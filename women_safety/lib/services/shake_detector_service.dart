import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetectorService {
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static bool _isListening = false;
  static Function()? _onShakeDetected;

  // Shake detection parameters
  static const double _shakeThreshold = 20.0; // m/s²
  static const int _shakeDuration = 500; // milliseconds
  static const int _shakeCount = 3; // number of shakes required

  static DateTime? _lastShakeTime;
  static int _shakeCounter = 0;

  /// Start listening for shake gestures
  static Future<void> startListening({
    required Function() onShakeDetected,
    double? threshold,
  }) async {
    if (_isListening) {
      debugPrint('⚠️ Already listening for shake gestures');
      return;
    }

    _onShakeDetected = onShakeDetected;
    _isListening = true;
    _shakeCounter = 0;
    _lastShakeTime = null;

    final double effectiveThreshold = threshold ?? _shakeThreshold;

    debugPrint('🔊 Started listening for shake gestures (threshold: $effectiveThreshold m/s²)');

    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _handleAccelerometerEvent(event, effectiveThreshold);
      },
      onError: (error) {
        debugPrint('❌ Accelerometer error: $error');
      },
    );
  }

  /// Handle accelerometer event
  static void _handleAccelerometerEvent(
    AccelerometerEvent event,
    double threshold,
  ) {
    // Calculate the magnitude of acceleration
    final double x = event.x;
    final double y = event.y;
    final double z = event.z;
    final double acceleration = sqrt(x * x + y * y + z * z);

    // Remove gravity (9.8 m/s²) to get net acceleration
    final double netAcceleration = (acceleration - 9.8).abs();

    // Check if shake threshold is exceeded
    if (netAcceleration > threshold) {
      final DateTime now = DateTime.now();

      // Check if this is a continuation of previous shakes
      if (_lastShakeTime != null) {
        final int timeDiff = now.difference(_lastShakeTime!).inMilliseconds;

        if (timeDiff < _shakeDuration) {
          // Within shake duration window
          _shakeCounter++;
          debugPrint('📳 Shake detected! Count: $_shakeCounter/$_shakeCount');

          if (_shakeCounter >= _shakeCount) {
            // Shake threshold reached, trigger SOS
            debugPrint('🚨 SHAKE THRESHOLD REACHED! Triggering SOS...');
            _triggerShakeDetected();
            _resetShakeCounter();
          }
        } else if (timeDiff > _shakeDuration * 2) {
          // Too much time passed, reset counter
          _resetShakeCounter();
          _shakeCounter = 1;
        }
      } else {
        // First shake detected
        _shakeCounter = 1;
        debugPrint('📳 First shake detected');
      }

      _lastShakeTime = now;
    }
  }

  /// Trigger shake detected callback
  static void _triggerShakeDetected() {
    if (_onShakeDetected != null) {
      _onShakeDetected!();
    }
  }

  /// Reset shake counter
  static void _resetShakeCounter() {
    _shakeCounter = 0;
    _lastShakeTime = null;
  }

  /// Stop listening for shake gestures
  static Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isListening = false;
    _onShakeDetected = null;
    _resetShakeCounter();

    debugPrint('🔇 Stopped listening for shake gestures');
  }

  /// Check if currently listening
  static bool get isListening => _isListening;

  /// Pause listening (temporarily)
  static Future<void> pauseListening() async {
    if (!_isListening) {
      return;
    }

    _accelerometerSubscription?.pause();
    debugPrint('⏸️ Paused shake detection');
  }

  /// Resume listening
  static void resumeListening() {
    if (!_isListening) {
      return;
    }

    _accelerometerSubscription?.resume();
    _resetShakeCounter();
    debugPrint('▶️ Resumed shake detection');
  }

  /// Test shake detection (simulates a shake)
  static void testShakeDetection() {
    debugPrint('🧪 Testing shake detection...');
    for (int i = 0; i < _shakeCount; i++) {
      _handleAccelerometerEvent(
        AccelerometerEvent(25.0, 25.0, 25.0, DateTime.now()),
        _shakeThreshold,
      );
    }
  }
}
