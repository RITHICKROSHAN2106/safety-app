import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 24/7 Background Protection Service 
/// Manages background SOS triggers and protection state
class ProtectionService {
  static bool _isRunning = false;

  /// Start the protection service (placeholder for future foreground service)
  static Future<bool> startProtection() async {
    if (_isRunning) {
      debugPrint('⚠️ Protection service already running');
      return true;
    }

    // Request necessary permissions
    if (!await _requestPermissions()) {
      debugPrint('❌ Required permissions not granted');
      return false;
    }

    _isRunning = true;
    debugPrint('✅ Protection service marked as active');
    return true;
  }

  /// Stop the protection service
  static Future<bool> stopProtection() async {
    if (!_isRunning) {
      debugPrint('ℹ️ Protection service not running');
      return true;
    }

    _isRunning = false;
    debugPrint('✅ Protection service stopped');
    return true;
  }

  /// Check if service is currently running
  static bool get isRunning => _isRunning;

  /// Request all necessary permissions
  static Future<bool> _requestPermissions() async {
    // Location permission (required for foreground service)
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      debugPrint('❌ Location permission required for background protection');
      return false;
    }

    // Notification permission
    await Permission.notification.request();

    // Battery optimization (optional but recommended)
    await Permission.ignoreBatteryOptimizations.request();

    return true;
  }

  /// Check and handle any pending SOS triggers
  static Future<String?> checkPendingSOS() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final triggerType = prefs.getString('pending_sos_trigger');

      if (triggerType != null) {
        final timestamp = prefs.getInt('pending_sos_timestamp') ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;

        // Only handle triggers less than 5 minutes old
        if (age < 300000) {
          await prefs.remove('pending_sos_trigger');
          await prefs.remove('pending_sos_timestamp');
          debugPrint('✅ Retrieved pending SOS: $triggerType');
          return triggerType;
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to check pending SOS: $e');
    }
    return null;
  }
}
