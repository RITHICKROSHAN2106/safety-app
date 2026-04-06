import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/guardian.dart';
import 'call_service.dart';

typedef CallAttemptHandler = Future<bool> Function(String phoneNumber);
typedef CallOutcomeHandler = Future<CallOutcome> Function({
  Duration timeout,
  Duration answeredThreshold,
});

/// Intelligent call escalation system
/// Auto-retries calls and escalates through guardian list
class CallEscalationService {
  static bool _isEscalating = false;
  static Timer? _retryTimer;
  static int _currentAttempt = 0;
  static int _currentGuardianIndex = 0;

  static int maxAttemptsPerGuardian = 3;
  static Duration retryInterval = const Duration(seconds: 5);
  static Duration callOutcomeTimeout = const Duration(seconds: 45);
  static Duration answeredDurationThreshold = const Duration(seconds: 15);
  static CallAttemptHandler _callAttemptHandler = CallService.makeCall;
  static CallAttemptHandler _emergencyCallHandler =
      (number) => CallService.callEmergencyServices(emergencyNumber: number);
  static CallOutcomeHandler _callOutcomeHandler = CallService.waitForCallOutcome;

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

    final callSequence = _buildCallSequence(guardians);
    if (callSequence.isEmpty) {
      debugPrint('❌ No valid guardians in call sequence');
      stopEscalation();
      return;
    }

    debugPrint('🔄 Starting call escalation for ${callSequence.length} guardians');

    await _attemptCallWithRetry(
      guardians: callSequence,
      currentGuardian: callSequence.first,
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

    final success = await _callAttemptHandler(currentGuardian.phone);

    if (success) {
      debugPrint('✅ Call initiated to ${currentGuardian.name}');

      final outcome = await _waitForOutcomeWithFallback();

      if (outcome == CallOutcome.answered) {
        debugPrint('✅ Call answered by ${currentGuardian.name}; stopping escalation');
        stopEscalation();
        return;
      }

      debugPrint('⚠️ Call outcome for ${currentGuardian.name}: $outcome');

      if (_currentAttempt < maxAttemptsPerGuardian) {
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
      debugPrint('❌ Call failed for ${currentGuardian.name}');

      if (_currentAttempt < maxAttemptsPerGuardian) {
        _scheduleRetry(
          guardians: guardians,
          currentGuardian: currentGuardian,
          callEmergencyOnFailure: callEmergencyOnFailure,
        );
      } else {
        _escalateToNext(
          guardians: guardians,
          callEmergencyOnFailure: callEmergencyOnFailure,
        );
      }
    }
  }

  /// Wait for call outcome, but never block escalation forever if the platform
  /// does not emit call-state events on a particular device.
  static Future<CallOutcome> _waitForOutcomeWithFallback() async {
    try {
      return await Future.any<CallOutcome>([
        _callOutcomeHandler(
          timeout: callOutcomeTimeout,
          answeredThreshold: answeredDurationThreshold,
        ),
        Future<CallOutcome>.delayed(
          callOutcomeTimeout,
          () => CallOutcome.timeout,
        ),
      ]);
    } catch (e) {
      debugPrint('⚠️ Call outcome detection failed, treating as timeout: $e');
      return CallOutcome.timeout;
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

    if (_currentGuardianIndex < guardians.length) {
      final nextGuardian = guardians[_currentGuardianIndex];
      
      debugPrint(
        '⬆️ Escalating to next guardian: '
        '${nextGuardian.name} (${_currentGuardianIndex + 1}/${guardians.length})',
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

    final success = await _emergencyCallHandler('112');

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

  @visibleForTesting
  static void configureForTest({
    CallAttemptHandler? callAttemptHandler,
    CallAttemptHandler? emergencyCallHandler,
    CallOutcomeHandler? callOutcomeHandler,
    int? maxAttempts,
    Duration? retryDelay,
    Duration? outcomeTimeout,
    Duration? answeredThreshold,
  }) {
    if (callAttemptHandler != null) {
      _callAttemptHandler = callAttemptHandler;
    }
    if (emergencyCallHandler != null) {
      _emergencyCallHandler = emergencyCallHandler;
    }
    if (callOutcomeHandler != null) {
      _callOutcomeHandler = callOutcomeHandler;
    }
    if (maxAttempts != null && maxAttempts > 0) {
      maxAttemptsPerGuardian = maxAttempts;
    }
    if (retryDelay != null && retryDelay > Duration.zero) {
      retryInterval = retryDelay;
    }
    if (outcomeTimeout != null && outcomeTimeout > Duration.zero) {
      callOutcomeTimeout = outcomeTimeout;
    }
    if (answeredThreshold != null && answeredThreshold > Duration.zero) {
      answeredDurationThreshold = answeredThreshold;
    }
  }

  @visibleForTesting
  static void resetTestConfiguration() {
    _callAttemptHandler = CallService.makeCall;
    _emergencyCallHandler =
        (number) => CallService.callEmergencyServices(emergencyNumber: number);
    _callOutcomeHandler = CallService.waitForCallOutcome;
    maxAttemptsPerGuardian = 3;
    retryInterval = const Duration(seconds: 5);
    callOutcomeTimeout = const Duration(seconds: 45);
    answeredDurationThreshold = const Duration(seconds: 15);
  }

  static List<Guardian> _buildCallSequence(List<Guardian> guardians) {
    // Primary guardians are called first, then non-primary guardians.
    final primary = guardians.where((g) => g.isPrimary).toList(growable: false);
    final others = guardians.where((g) => !g.isPrimary).toList(growable: false);
    final ordered = <Guardian>[...primary, ...others];

    // Deduplicate by normalized phone while preserving first occurrence.
    final seenPhones = <String>{};
    final sequence = <Guardian>[];
    for (final guardian in ordered) {
      final phone = guardian.phone.replaceAll(RegExp(r'\D'), '');
      if (phone.isEmpty || seenPhones.contains(phone)) {
        continue;
      }
      seenPhones.add(phone);
      sequence.add(guardian);
    }

    return sequence;
  }
}
