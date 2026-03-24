/// Panic Widget Service
/// Manages Android home screen widget data and updates
import 'package:home_widget/home_widget.dart';
import 'package:flutter/services.dart';

class PanicWidgetService {
  static const String _widgetName = 'PanicWidgetProvider';
  static const String _androidPackageName =
      'com.example.women_safety_app'; // Update with your package name

  // Initialize widget
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_androidPackageName);
    } catch (e) {
      print('Failed to initialize widget: $e');
    }
  }

  // Update widget with user data
  Future<void> updateWidget({
    required String userName,
    required int guardianCount,
    required String safetyStatus,
  }) async {
    try {
      // Save data for widget
      await HomeWidget.saveWidgetData<String>('user_name', userName);
      await HomeWidget.saveWidgetData<int>('guardian_count', guardianCount);
      await HomeWidget.saveWidgetData<String>('safety_status', safetyStatus);
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      // Update widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
        iOSName: _widgetName,
      );

      print('Widget updated successfully');
    } catch (e) {
      print('Failed to update widget: $e');
    }
  }

  // Update safety status only
  Future<void> updateSafetyStatus(String status) async {
    try {
      await HomeWidget.saveWidgetData<String>('safety_status', status);
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      print('Failed to update safety status: $e');
    }
  }

  // Handle widget click (register click handler)
  Future<void> registerWidgetClickHandler(
    Function(Uri?) clickHandler,
  ) async {
    try {
      HomeWidget.widgetClicked.listen(clickHandler);
    } catch (e) {
      print('Failed to register widget click handler: $e');
    }
  }

  // Trigger SOS from widget
  static const MethodChannel _channel =
      MethodChannel('women_safety_app/widget');

  Future<void> triggerSosFromWidget() async {
    try {
      await _channel.invokeMethod('triggerSOS');
    } catch (e) {
      print('Failed to trigger SOS from widget: $e');
    }
  }

  // Get widget data (for debugging)
  Future<Map<String, dynamic>> getWidgetData() async {
    try {
      final userName =
          await HomeWidget.getWidgetData<String>('user_name', defaultValue: '');
      final guardianCount =
          await HomeWidget.getWidgetData<int>('guardian_count', defaultValue: 0);
      final safetyStatus = await HomeWidget.getWidgetData<String>(
          'safety_status',
          defaultValue: 'Unknown');
      final lastUpdated = await HomeWidget.getWidgetData<String>(
          'last_updated',
          defaultValue: '');

      return {
        'user_name': userName,
        'guardian_count': guardianCount,
        'safety_status': safetyStatus,
        'last_updated': lastUpdated,
      };
    } catch (e) {
      return {};
    }
  }

  // Clear widget data
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>('user_name', '');
      await HomeWidget.saveWidgetData<int>('guardian_count', 0);
      await HomeWidget.saveWidgetData<String>('safety_status', 'Unknown');
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      print('Failed to clear widget data: $e');
    }
  }
}
