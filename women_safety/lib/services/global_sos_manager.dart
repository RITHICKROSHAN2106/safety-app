import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;

import '../bloc/auth/auth_cubit.dart';
import '../bloc/sos/sos_cubit.dart';
import '../models/app_user.dart';
import '../repositories/guardian_repository.dart';
import 'distress_voice_analysis_service.dart';
import 'notification_service.dart';
import 'panic_widget_service.dart';
import 'shake_detector_service.dart';

/// Coordinates shake and voice triggers with the SOS cubit.
class GlobalSOSManager {
  GlobalSOSManager._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GuardianRepository _guardianRepository = GuardianRepository();

  static bool _listenersActive = false;
  static bool _triggerInFlight = false;
  static StreamSubscription<Map<String, dynamic>>? _panicTriggerSub;

  /// Activate shake and voice listeners. Safe to call multiple times.
  static Future<void> setup() async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ GlobalSOSManager.setup called before navigator ready.');
      return;
    }

    if (!ShakeDetectorService.isListening) {
      await ShakeDetectorService.startListening(
        onShakeDetected: () => _handleGlobalTrigger('SHAKE'),
        threshold: 20.0,
      );
    }

    if (!DistressVoiceAnalysisService.isAnalyzing) {
      final voiceReady = await DistressVoiceAnalysisService.initialize();
      if (voiceReady) {
        DistressVoiceAnalysisService.onAutoSOSRequested = (score, transcript) async {
          debugPrint('🗣️ Global voice distress trigger: score=$score text="$transcript"');
          await _handleGlobalTrigger('VOICE');
        };
        await DistressVoiceAnalysisService.startAnalysis(emergencyMode: true);
      }
    }

    _panicTriggerSub ??= PanicWidgetService.panicTriggers.listen((event) async {
      debugPrint('🚨 Global panic widget trigger received: $event');
      await _handleGlobalTrigger('WIDGET');
    });

    final pendingWidgetTrigger = await PanicWidgetService.checkPanicTrigger();
    if (pendingWidgetTrigger != null) {
      debugPrint('🚨 Processing pending panic widget trigger: $pendingWidgetTrigger');
      await _handleGlobalTrigger('WIDGET');
    }

    _listenersActive = true;

    debugPrint('✅ Global SOS listeners active');
  }

  /// Stop all background listeners.
  static void teardown() {
    if (!_listenersActive) return;
    ShakeDetectorService.stopListening();
    DistressVoiceAnalysisService.stopAnalysis();
    _panicTriggerSub?.cancel();
    _panicTriggerSub = null;
    _listenersActive = false;
    debugPrint('✅ Global SOS listeners stopped');
  }

  /// Shake detection should work only while app is in foreground.
  static Future<void> pauseShakeDetection() async {
    await ShakeDetectorService.pauseListening();
  }

  static void resumeShakeDetection() {
    if (ShakeDetectorService.isListening) {
      ShakeDetectorService.resumeListening();
      return;
    }

    ShakeDetectorService.startListening(
      onShakeDetected: () => _handleGlobalTrigger('SHAKE'),
      threshold: 20.0,
    );
  }

  static Future<void> _handleGlobalTrigger(String triggerType) async {
    if (_triggerInFlight) {
      debugPrint('⚠️ SOS trigger already in progress; ignoring $triggerType');
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('❌ No navigator context available for SOS trigger');
      return;
    }

    final authCubit = context.read<AuthCubit>();
    final user = await _resolveAuthenticatedUser(authCubit);
    if (user == null) {
      debugPrint('❌ Cannot trigger SOS without authenticated user');
      return;
    }

    final sosCubit = context.read<SosCubit>();
    if (sosCubit.state.isLoading) {
      debugPrint('⚠️ SOS cubit busy; ignoring $triggerType trigger');
      return;
    }

    _triggerInFlight = true;

    try {
      final guardians = await _guardianRepository.fetchGuardiansForUser(user.uid);
      if (guardians.isEmpty) {
        await NotificationService.showNotification(
          title: 'SOS Trigger Blocked',
          body: 'Add guardians to enable automatic SOS alerts.',
        );
        return;
      }

      await sosCubit.triggerSOS(
        user: _sanitizeUser(user),
        emergencyContacts: guardians,
        triggerType: triggerType,
      );
    } catch (e) {
      debugPrint('❌ Failed to trigger SOS automatically: $e');
    } finally {
      _triggerInFlight = false;
    }
  }

  static Future<AppUser?> _resolveAuthenticatedUser(AuthCubit authCubit) async {
    final currentUser = authCubit.state.user;
    if (currentUser != null) {
      return currentUser;
    }

    final firebaseUser = fba.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    await authCubit.refreshProfile();
    final refreshedUser = authCubit.state.user;
    if (refreshedUser != null) {
      return refreshedUser;
    }

    return AppUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
    );
  }

  /// Make sure the user object contains the most up-to-date contact IDs.
  static AppUser _sanitizeUser(AppUser user) {
    if (user.emergencyContactIds != null) {
      return user;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      return user;
    }

    final authCubit = context.read<AuthCubit>();
    final refreshed = authCubit.state.user;
    return refreshed ?? user;
  }
}
