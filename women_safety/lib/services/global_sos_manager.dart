import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/sos/sos_cubit.dart';
import '../models/app_user.dart';
import '../repositories/guardian_repository.dart';
import 'notification_service.dart';
import 'shake_detector_service.dart';
import 'voice_activation_service.dart';

/// Coordinates shake and voice triggers with the SOS cubit.
class GlobalSOSManager {
  GlobalSOSManager._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GuardianRepository _guardianRepository = GuardianRepository();

  static bool _listenersActive = false;
  static bool _triggerInFlight = false;

  /// Activate shake and voice listeners. Safe to call multiple times.
  static Future<void> setup() async {
    if (_listenersActive) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ GlobalSOSManager.setup called before navigator ready.');
      return;
    }

    _listenersActive = true;

    ShakeDetectorService.startListening(
      onShakeDetected: () => _handleGlobalTrigger('SHAKE'),
      threshold: 20.0,
    );

    final voiceReady = await VoiceActivationService.initialize();
    if (voiceReady) {
      VoiceActivationService.startListening(
        onKeywordDetected: () => _handleGlobalTrigger('VOICE'),
      );
    }

    debugPrint('✅ Global SOS listeners active');
  }

  /// Stop all background listeners.
  static void teardown() {
    if (!_listenersActive) return;
    ShakeDetectorService.stopListening();
    VoiceActivationService.stopListening();
    _listenersActive = false;
    debugPrint('✅ Global SOS listeners stopped');
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
    final user = authCubit.state.user;
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
