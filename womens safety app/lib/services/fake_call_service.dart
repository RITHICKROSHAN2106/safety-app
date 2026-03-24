import 'dart:async';

class FakeCallService {
  Timer? _timer;
  bool _isScheduled = false;

  bool get isScheduled => _isScheduled;

  void scheduleFakeCall({
    required Duration delay,
    required String callerName,
    required String callerNumber,
    required void Function(FakeCallEvent event) onTriggered,
  }) {
    cancelScheduledCall();
    _isScheduled = true;

    _timer = Timer(delay, () {
      _isScheduled = false;
      onTriggered(
        FakeCallEvent(
          callerName: callerName,
          callerNumber: callerNumber,
          triggeredAt: DateTime.now(),
        ),
      );
    });
  }

  void cancelScheduledCall() {
    _timer?.cancel();
    _timer = null;
    _isScheduled = false;
  }

  void dispose() {
    cancelScheduledCall();
  }
}

class FakeCallEvent {
  final String callerName;
  final String callerNumber;
  final DateTime triggeredAt;

  FakeCallEvent({
    required this.callerName,
    required this.callerNumber,
    required this.triggeredAt,
  });
}
