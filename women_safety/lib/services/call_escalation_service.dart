import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/guardian.dart';
import 'call_service.dart';

/// Intelligent call escalation system
/// Auto-retries calls and escalates through guardian list
class CallEscalationService {
  static bool _isEscalating = false;
  static Timer? _retryTimer;
  static int _currentAttempt = 0;
  static int _currentGuardianIndex = 0;
  
  static const int maxAttemptsPerGuardian = 3;
  static const Duration retryInterval = Duration(seconds: 30);

  /// Start smart call escalation
  static Future<void> startEscalation({
    required List<Guardian> guardians,
    bool callEmergencyServicesOnFailure = true,
  }) async {
    if (_isEscalating) {
      debugPrint('⚠️ Escalation already in progress');
      return;
    }

    if (guardians.isEmpty) {
      debugPrint('❌ No guardians to call');
      return;
    }

    _isEscalating = true;
    _currentAttempt = 0;
    _currentGuardianIndex = 0;

    debugPrint('🔄 Starting call escalation for ${guardians.length} guardians');

    // Start with primary guardian
    final primaryGuardian = guardians.firstWhere(
      (g) => g.isPrimary,
      orElse: () => guardians.first,
    );

    await _attemptCallWithRetry(
      guardians: guardians,
      currentGuardian: primaryGuardian,
      callEmergencyOnFailure: callEmergencyServicesOnFailure,
    );
  }

  /// Stop escalation process
  static void stopEscalation() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _isEscalating = false;
    _currentAttempt = 0;
    _currentGuardianIndex = 0;
    debugPrint('🛑 Call escalation stopped');
  }

  /// Attempt call with automatic retry
  static Future<void> _attemptCallWithRetry({
    required List<Guardian> guardians,
    required Guardian currentGuardian,
    required bool callEmergencyOnFailure,
  }) async {
    _currentAttempt++;

    debugPrint(
      '📞 Attempt $_currentAttempt/$maxAttemptsPerGuardian: '
      'Calling ${currentGuardian.name} (${currentGuardian.phone})',
    );

    final success = await CallService.makeCall(currentGuardian.phone);

    if (success) {
      // Call initiated successfully
      // Note: We can't detect if call was answered, so we schedule a retry
      debugPrint('✅ Call initiated to ${currentGuardian.name}');

      if (_currentAttempt < maxAttemptsPerGuardian) {
        // Schedule retry in case call wasn't answered
        _scheduleRetry(
          guardians: guardians,
          currentGuardian: currentGuardian,
          callEmergencyOnFailure: callEmergencyOnFailure,
        );
      } else {
        // Max attempts reached for this guardian, escalate to next
        _escalateToNext(
          guardians: guardians,
          callEmergencyOnFailure: callEmergencyOnFailure,
        );
      }
    } else {
      // Call failed immediately, try next guardian
      debugPrint('❌ Call failed for ${currentGuardian.name}');
      _escalateToNext(
        guardians: guardians,
        callEmergencyOnFailure: callEmergencyOnFailure,
      );
    }
  }

  /// Schedule next retry attempt
  static void _scheduleRetry({
    required List<Guardian> guardians,
    required Guardian currentGuardian,
    required bool callEmergencyOnFailure,
  }) {
    _retryTimer?.cancel();

    debugPrint(
      '⏱️ Scheduling retry in ${retryInterval.inSeconds}s '
      '(attempt $_currentAttempt/$maxAttemptsPerGuardian)',
    );

    _retryTimer = Timer(retryInterval, () {
      if (_isEscalating) {
        _attemptCallWithRetry(
          guardians: guardians,
          currentGuardian: currentGuardian,
          callEmergencyOnFailure: callEmergencyOnFailure,
        );
      }
    });
  }

  /// Escalate to next guardian
  static Future<void> _escalateToNext({
    required List<Guardian> guardians,
    required bool callEmergencyOnFailure,
  }) async {
    _currentGuardianIndex++;
    _currentAttempt = 0;

    // Filter out primary guardian to avoid duplicate calls
    final nonPrimaryGuardians = guardians
        .where((g) => !g.isPrimary)
        .toList(growable: false);

    if (_currentGuardianIndex - 1 < nonPrimaryGuardians.length) {
      // Call next guardian
      final nextGuardian = nonPrimaryGuardians[_currentGuardianIndex - 1];
      
      debugPrint(
        '⬆️ Escalating to next guardian: '
        '${nextGuardian.name} ($_currentGuardianIndex/${guardians.length})',
      );

      await _attemptCallWithRetry(
        guardians: guardians,
        currentGuardian: nextGuardian,
        callEmergencyOnFailure: callEmergencyOnFailure,
      );
    } else {
      // All guardians exhausted
      debugPrint('⚠️ All guardians called, no response');

      if (callEmergencyOnFailure) {
        await _callEmergencyServices();
      }

      stopEscalation();
    }
  }

  /// Call emergency services as last resort
  static Future<void> _callEmergencyServices() async {
    debugPrint('🚨 Calling emergency services (112)...');

    final success = await CallService.callEmergencyServices(
      emergencyNumber: '112',
    );

    if (success) {
      debugPrint('✅ Emergency services call initiated');
    } else {
      debugPrint('❌ Failed to call emergency services');
    }
  }

  /// Check if escalation is currently active
  static bool get isEscalating => _isEscalating;

  /// Get current escalation status
  static String get status {
    if (!_isEscalating) {
      return 'Inactive';
    }

    return 'Attempt $_currentAttempt/$maxAttemptsPerGuardian, '
        'Guardian ${_currentGuardianIndex + 1}';
  }
}
