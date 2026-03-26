/// Test Logger Utility
/// Provides structured logging for unit tests, widget tests, and integration tests
/// with color-coded output and timestamp tracking

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Structured logging system for testing
class TestLogger {
  static const String _sos = '🚨';
  static const String _location = '📍';
  static const String _notification = '📲';
  static const String _voice = '🎤';
  static const String _error = '❌';
  static const String _success = '✅';
  static const String _info = 'ℹ️';
  static const String _warning = '⚠️';

  static DateTime _sessionStart = DateTime.now();

  /// Initialize logger (call once at app startup)
  static void init() {
    _sessionStart = DateTime.now();
    logInfo('TestLogger initialized', 'Session Start');
  }

  /// Log SOS trigger events
  static void logSOSTrigger(String message, {String? type, Map<String, dynamic>? data}) {
    _log('SOS_TRIGGER', '$_sos $message', data: data);
    developer.log('🚨 SOS: $message', name: 'SOS_TRIGGER', error: data);
  }

  /// Log location service events
  static void logLocation(String message, {double? latitude, double? longitude, Map<String, dynamic>? data}) {
    final locData = {
      ...?data,
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lng': longitude,
    };
    _log('LOCATION', '$_location $message', data: locData);
    developer.log('📍 Location: $message', name: 'LOCATION_SERVICE');
  }

  /// Log notification events
  static void logNotification(String message, {String? to, Map<String, dynamic>? data}) {
    final notifData = {...?data, if (to != null) 'sent_to': to};
    _log('NOTIFICATION', '$_notification $message', data: notifData);
    developer.log('📲 Notification: $message', name: 'NOTIFICATION_SERVICE');
  }

  /// Log voice distress detection events
  static void logVoiceDetection(String message, {double? confidence, Map<String, dynamic>? data}) {
    final voiceData = {...?data, if (confidence != null) 'confidence': confidence};
    _log('VOICE_DETECTION', '$_voice $message', data: voiceData);
    developer.log('🎤 Voice: $message', name: 'VOICE_DETECTION');
  }

  /// Log API calls
  static void logAPI(String method, String endpoint, {dynamic request, dynamic response, int? statusCode, dynamic error}) {
    final apiData = {
      'method': method,
      'endpoint': endpoint,
      if (statusCode != null) 'status': statusCode,
      if (request != null) 'request': request,
      if (response != null) 'response': response,
      if (error != null) 'error': error.toString(),
    };
    _log('API_CALL', '$method $endpoint', data: apiData);
    developer.log('API: $method $endpoint', name: 'API_CLIENT');
  }

  /// Log authentication events
  static void logAuth(String message, {String? userId, Map<String, dynamic>? data}) {
    final authData = {...?data, if (userId != null) 'user_id': userId};
    _log('AUTH', '$_info Auth: $message', data: authData);
    developer.log('Auth: $message', name: 'AUTHENTICATION');
  }

  /// Log errors
  static void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    final errorData = {
      'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
    };
    _log('ERROR', '$_error ERROR: $message', data: errorData);
    developer.log('ERROR: $message\n${error}\n${stackTrace}', name: 'ERROR_LOG', error: error, stackTrace: stackTrace);
  }

  /// Log success events
  static void logSuccess(String message, {Map<String, dynamic>? data}) {
    _log('SUCCESS', '$_success $message', data: data);
    developer.log('SUCCESS: $message', name: 'APP_LOG');
  }

  /// Log info/general events
  static void logInfo(String message, [String? tag, Map<String, dynamic>? data]) {
    _log(tag ?? 'INFO', '$_info $message', data: data);
    developer.log(message, name: tag ?? 'APP_LOG');
  }

  /// Log warning events
  static void logWarning(String message, {Map<String, dynamic>? data}) {
    _log('WARNING', '$_warning $message', data: data);
    developer.log('WARNING: $message', name: 'APP_LOG');
  }

  /// Get elapsed time since session start
  static Duration getElapsedTime() {
    return DateTime.now().difference(_sessionStart);
  }

  /// Internal log function
  static void _log(String tag, String message, {Map<String, dynamic>? data}) {
    final elapsed = getElapsedTime();
    final timestamp = DateTime.now().toString().split('.')[0];
    final elapsedStr = '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';

    final output = '[$timestamp] [$elapsedStr] [$tag] $message';

    if (data != null && data.isNotEmpty) {
      if (kDebugMode) {
        print('$output');
        print('  Data: $data');
      }
    } else {
      if (kDebugMode) {
        print(output);
      }
    }
  }
}

/// Test assertion helper with custom messages
class TestAssertions {
  static void assertSOSTriggered(bool triggered, {String location = ''}) {
    assert(triggered, '🚨 SOS should have been triggered at $location');
    TestLogger.logSuccess('SOS triggered assertion passed', data: {'location': location});
  }

  static void assertLocationReceived(double? lat, double? lng) {
    assert(lat != null && lng != null, '📍 Location coordinates should not be null');
    TestLogger.logSuccess('Location received assertion passed', data: {'lat': lat, 'lng': lng});
  }

  static void assertNotificationSent(bool sent, [String? contact]) {
    assert(sent, '📲 Notification should have been sent${contact != null ? ' to $contact' : ''}');
    TestLogger.logSuccess('Notification sent assertion passed', data: {'contact': contact});
  }

  static void assertAPISuccess(int? statusCode) {
    assert(statusCode != null && statusCode >= 200 && statusCode < 300, 
      'API call should return success status code (200-299), got: $statusCode');
  }
}

/// Performance timer for measuring execution time
class PerformanceTimer {
  final String _name;
  late DateTime _startTime;
  late Duration _duration;

  PerformanceTimer(this._name);

  void start() {
    _startTime = DateTime.now();
    TestLogger.logInfo('Performance timer started: $_name', 'PERF_TIMER');
  }

  void stop() {
    _duration = DateTime.now().difference(_startTime);
    TestLogger.logInfo(
      'Performance timer stopped: $_name - ${_duration.inMilliseconds}ms',
      'PERF_TIMER',
      {'duration_ms': _duration.inMilliseconds},
    );
  }

  Duration getDuration() => _duration;

  bool isWithinThreshold(int thresholdMs) {
    final withinThreshold = _duration.inMilliseconds <= thresholdMs;
    TestLogger.logSuccess(
      '$_name completed in ${_duration.inMilliseconds}ms (threshold: ${thresholdMs}ms)',
      data: {'within_threshold': withinThreshold},
    );
    return withinThreshold;
  }
}

/// Test constants
class TestConstants {
  // Timeout values
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration mediumTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(seconds: 30);

  // SOS performance thresholds
  static const int sosClickToUIMs = 1000;  // 1 second
  static const int sosClickToAPIMs = 2000; // 2 seconds
  static const int locationFetchMs = 3000; // 3 seconds

  // Test data
  static const String testEmail = 'testuser@womensafety.com';
  static const String testPassword = 'Test@123456';
  static const String testPhoneNumber = '+919876543210';
  static const String testGuardianName = 'John Doe';
  static const String testGuardianPhone = '+919123456789';
  static const double testLatitude = 12.9716;
  static const double testLongitude = 77.5946;

  // Firebase test values
  static const String testUserId = 'test_user_001';
  static const String testGuardianId = 'test_guardian_001';
  static const String testSOSId = 'test_sos_001';
}
