import 'dart:async';

import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class CheckInState {
  final bool isActive;
  final bool awaitingConfirmation;
  final int remainingSeconds;
  final int graceRemainingSeconds;

  const CheckInState({
    required this.isActive,
    required this.awaitingConfirmation,
    required this.remainingSeconds,
    required this.graceRemainingSeconds,
  });
}

/// In-app safety check-in timer with grace period and escalation callback.
class SafetyCheckInService {
  SafetyCheckInService._();

  static final StreamController<CheckInState> _stateController =
      StreamController<CheckInState>.broadcast();

  static Timer? _timer;
  static Duration _interval = const Duration(minutes: 10);
  static Duration _grace = const Duration(seconds: 45);
  static int _remainingSeconds = 0;
  static int _graceRemainingSeconds = 0;
  static bool _awaitingConfirmation = false;
  static bool _isActive = false;
  static Future<void> Function()? _onMissedCheckIn;

  static Stream<CheckInState> get updates => _stateController.stream;

  static CheckInState get currentState => CheckInState(
    isActive: _isActive,
    awaitingConfirmation: _awaitingConfirmation,
    remainingSeconds: _remainingSeconds,
    graceRemainingSeconds: _graceRemainingSeconds,
  );

  static Future<void> start({
    Duration interval = const Duration(minutes: 10),
    Duration gracePeriod = const Duration(seconds: 45),
    Future<void> Function()? onMissedCheckIn,
  }) async {
    await stop();

    _interval = interval;
    _grace = gracePeriod;
    _onMissedCheckIn = onMissedCheckIn;
    _isActive = true;
    _awaitingConfirmation = false;
    _remainingSeconds = _interval.inSeconds;
    _graceRemainingSeconds = _grace.inSeconds;

    _emitState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      if (_awaitingConfirmation) {
        _graceRemainingSeconds = (_graceRemainingSeconds - 1).clamp(0, 1 << 30);
        _emitState();

        if (_graceRemainingSeconds <= 0) {
          debugPrint(
            '🚨 Safety check-in missed. Triggering escalation callback.',
          );
          await stop();
          await _onMissedCheckIn?.call();
        }
        return;
      }

      _remainingSeconds = (_remainingSeconds - 1).clamp(0, 1 << 30);
      _emitState();

      if (_remainingSeconds <= 0) {
        _awaitingConfirmation = true;
        _graceRemainingSeconds = _grace.inSeconds;
        _emitState();
        await NotificationService.showNotification(
          title: 'Safety Check-In',
          body:
              'Tap I\'m Safe within ${_grace.inSeconds}s to avoid emergency escalation.',
          id: 45001,
        );
      }
    });
  }

  static Future<void> confirmSafe() async {
    if (!_isActive) {
      return;
    }

    _awaitingConfirmation = false;
    _remainingSeconds = _interval.inSeconds;
    _graceRemainingSeconds = _grace.inSeconds;
    _emitState();
    await NotificationService.cancelNotification(45001);
    await NotificationService.showNotification(
      title: 'Check-In Confirmed',
      body: 'Great. Safety timer has been reset.',
      id: 45002,
    );
  }

  static Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _awaitingConfirmation = false;
    _remainingSeconds = 0;
    _graceRemainingSeconds = 0;
    _emitState();
    await NotificationService.cancelNotification(45001);
  }

  static void _emitState() {
    if (_stateController.isClosed) {
      return;
    }
    _stateController.add(currentState);
  }
}
