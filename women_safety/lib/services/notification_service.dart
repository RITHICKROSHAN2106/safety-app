import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: iOS);
    
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
    
    _isInitialized = true;
  }

  /// Show a notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'SOS Alerts',
      channelDescription: 'Emergency SOS notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Show SOS alert notification
  static Future<void> showSOSNotification({
    required String message,
    String? payload,
  }) async {
    await showNotification(
      title: '🚨 Emergency SOS Alert',
      body: message,
      payload: payload,
      id: 999,
    );
  }

  /// Cancel a notification
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
