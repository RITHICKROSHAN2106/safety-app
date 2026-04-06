import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/guardian.dart';
import 'call_escalation_service.dart';

enum CallOutcome {
  answered,
  rejected,
  missed,
  timeout,
  unknown,
}

class CallService {
  static const MethodChannel _callChannel = MethodChannel('women_safety/call');
  static const EventChannel _callStateChannel = EventChannel('women_safety/call_state');

  /// Make emergency call to primary contact
  static Future<bool> makeEmergencyCall(List<Guardian> contacts) async {
    if (contacts.isEmpty) {
      debugPrint('❌ No emergency contacts available');
      return false;
    }

    await CallEscalationService.startEscalation(
      guardians: contacts,
      callEmergencyServicesOnFailure: true,
    );
    return true;
  }

  /// Make call to specific phone number
  static Future<bool> makeCall(String phoneNumber) async {
    try {
      final launched = await _tryDirectCall(phoneNumber);
      if (launched) {
        debugPrint('✅ Direct call started for $phoneNumber');
        return true;
      }

      debugPrint('⚠️ Direct call unavailable for $phoneNumber');
      return false;
    } catch (e) {
      debugPrint('❌ Call service error: $e');
      return false;
    }
  }

  static Future<CallOutcome> waitForCallOutcome({
    Duration timeout = const Duration(seconds: 45),
    Duration answeredThreshold = const Duration(seconds: 15),
  }) async {
    if (!Platform.isAndroid) {
      return CallOutcome.unknown;
    }

    final completer = Completer<CallOutcome>();
    StreamSubscription<dynamic>? subscription;
    Timer? timeoutTimer;

    DateTime? offHookAt;
    bool sawOffHook = false;

    void finish(CallOutcome outcome) {
      if (!completer.isCompleted) {
        completer.complete(outcome);
      }
    }

    timeoutTimer = Timer(timeout, () {
      finish(CallOutcome.timeout);
    });

    subscription = _callStateChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        final data = event is Map ? event : const <String, dynamic>{};
        final state = (data['state'] as String? ?? '').toUpperCase();
        final now = DateTime.now();

        if (state == 'OFFHOOK') {
          sawOffHook = true;
          offHookAt ??= now;
          return;
        }

        if (state == 'IDLE') {
          if (!sawOffHook) {
            finish(CallOutcome.missed);
            return;
          }

          final start = offHookAt ?? now;
          final duration = now.difference(start);
          if (duration >= answeredThreshold) {
            finish(CallOutcome.answered);
          } else {
            finish(CallOutcome.rejected);
          }
        }
      },
      onError: (_) {
        finish(CallOutcome.unknown);
      },
    );

    final result = await completer.future;
    await subscription.cancel();
    timeoutTimer.cancel();
    return result;
  }

  /// Attempt a direct phone call when platform and permissions allow.
  static Future<bool> _tryDirectCall(String phoneNumber) async {
    if (!Platform.isAndroid) {
      debugPrint('ℹ️ Direct call only supported on Android');
      return false;
    }

    // Request permission if not already granted
    var status = await Permission.phone.status;

    if (!status.isGranted) {
      debugPrint('📞 Requesting CALL_PHONE permission...');
      status = await Permission.phone.request();
    }

    if (!status.isGranted) {
      debugPrint('⚠️ CALL_PHONE permission denied - will use dialer fallback');
      return false;
    }

    try {
      final sanitizedNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
      final result = await _callChannel.invokeMethod<bool>('startDirectCall', {
        'phone': sanitizedNumber,
      });

      return result ?? false;
    } catch (e) {
      debugPrint('❌ Native direct call exception: $e');
      return false;
    }
  }

  /// Call emergency services (911, 112, 100, etc.)
  static Future<bool> callEmergencyServices({String emergencyNumber = '112'}) async {
    return await makeCall(emergencyNumber);
  }

  /// Call police (India: 100, International: 112)
  static Future<bool> callPolice() async {
    return await callEmergencyServices(emergencyNumber: '100');
  }

  /// Call ambulance (India: 102)
  static Future<bool> callAmbulance() async {
    return await callEmergencyServices(emergencyNumber: '102');
  }

  /// Call women helpline (India: 181)
  static Future<bool> callWomenHelpline() async {
    return await callEmergencyServices(emergencyNumber: '181');
  }
}
