import 'dart:async';

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 🚨 Panic Widget Service - One-tap SOS from home screen
class PanicWidgetService {
  static const String _widgetName = 'PanicWidgetProvider';
  static bool _isInitialized = false;
  static StreamSubscription<Uri?>? _widgetClickSubscription;

  static final StreamController<Map<String, dynamic>> _panicTriggerController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get panicTriggers => _panicTriggerController.stream;

  /// Initialize panic widget on home screen
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      await _widgetClickSubscription?.cancel();
      _widgetClickSubscription = null;

      // Register widget update callback
      HomeWidget.setAppGroupId('com.example.women_safety');
      
      // Listen for widget taps
      _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
        if (_isPanicUri(uri)) {
          debugPrint('🚨 PANIC WIDGET PRESSED!');
          unawaited(_handlePanicButtonPress());
        }
      });

      _isInitialized = true;
      debugPrint('✅ Panic widget initialized');
      return true;
    } catch (e) {
      debugPrint('❌ Panic widget initialization error: $e');
      return false;
    }
  }

  /// Update widget UI with user data
  static Future<void> updateWidget({
    required String userName,
    required int contactCount,
    bool isEnabled = true,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('user_name', userName);
      await HomeWidget.saveWidgetData<int>('contact_count', contactCount);
      await HomeWidget.saveWidgetData<bool>('is_enabled', isEnabled);
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
        iOSName: _widgetName,
      );
      
      debugPrint('✅ Panic widget updated');
    } catch (e) {
      debugPrint('❌ Widget update error: $e');
    }
  }

  /// Handle panic button press from widget
  static Future<void> _handlePanicButtonPress() async {
    try {
      // Store panic trigger in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('panic_triggered', true);
      await prefs.setInt('panic_timestamp', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('pending_sos_trigger', 'WIDGET');
      await prefs.setInt('pending_sos_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('🚨 Panic triggered from widget!');

      _panicTriggerController.add({
        'triggered': true,
        'timestamp': DateTime.now(),
        'source': 'widget',
      });
      
      // Update widget to show "SOS Sent" status
      await updateWidgetStatus('SOS Triggered!');
      
    } catch (e) {
      debugPrint('❌ Panic button press error: $e');
    }
  }

  /// Check if panic was triggered from widget
  static Future<Map<String, dynamic>?> checkPanicTrigger({
    bool clearOnRead = true,
  }) async {
    try {
      final launchedUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (_isPanicUri(launchedUri)) {
        return {
          'triggered': true,
          'timestamp': DateTime.now(),
          'source': 'widget',
        };
      }

      final prefs = await SharedPreferences.getInstance();
      final wasTriggered = prefs.getBool('panic_triggered') ?? false;
      
      if (wasTriggered) {
        final timestamp = prefs.getInt('panic_timestamp');

        if (clearOnRead) {
          // Clear the trigger once consumed.
          await prefs.remove('panic_triggered');
          await prefs.remove('panic_timestamp');
        }
        
        return {
          'triggered': true,
          'timestamp': timestamp != null 
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : DateTime.now(),
          'source': 'widget',
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Check panic trigger error: $e');
      return null;
    }
  }

  /// Update widget status text
  static Future<void> updateWidgetStatus(String status) async {
    try {
      await HomeWidget.saveWidgetData<String>('status_text', status);
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
        iOSName: _widgetName,
      );
    } catch (e) {
      debugPrint('❌ Widget status update error: $e');
    }
  }

  /// Enable/disable panic widget
  static Future<void> setWidgetEnabled(bool enabled) async {
    try {
      await HomeWidget.saveWidgetData<bool>('is_enabled', enabled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('panic_widget_enabled', enabled);
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
        iOSName: _widgetName,
      );
      
      debugPrint('${enabled ? "✅" : "❌"} Panic widget ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Widget enable/disable error: $e');
    }
  }

  static Future<bool> getWidgetEnabledStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('panic_widget_enabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Launch main app from widget
  static Future<void> launchApp() async {
    try {
      await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint('❌ Launch app error: $e');
    }
  }

  static Future<void> dispose() async {
    await _widgetClickSubscription?.cancel();
    _widgetClickSubscription = null;
    _isInitialized = false;
  }

  static bool _isPanicUri(Uri? uri) {
    if (uri == null) {
      return false;
    }

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return host == 'panic' || path.contains('panic');
  }
}
