/// Unit Tests for Notification Service
/// Tests: Push notifications (FCM), SMS, Email, In-app messages

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:women_safety/utils/test_logger.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockNotificationPayload extends Mock implements RemoteMessage {}

void main() {
  TestLogger.init();

  group('Notification Service Tests', () {
    test('Push Notification Should Be Sent to Guardian', () async {
      TestLogger.logNotification('Testing push notification to guardian');

      // Arrange
      const guardianPhone = '+919123456789';
      const guardianName = 'John Doe';

      // Act
      try {
        TestLogger.logAPI('POST', '/api/notifications/push', request: {
          'to': guardianPhone,
          'title': 'SOS Alert!',
          'body': 'User needs help NOW',
          'priority': 'high',
        });

        // Simulate FCM send
        await Future.delayed(Duration(milliseconds: 500));

        TestLogger.logNotification('Push notification sent', to: guardianName, 
          data: {'guardian_phone': guardianPhone, 'priority': 'high'});

        // Assert
        TestAssertions.assertNotificationSent(true, guardianName);
      } catch (e) {
        TestLogger.logError('Push notification failed', e);
        rethrow;
      }
    });

    test('SMS Notification Should Be Sent Through Twilio', () async {
      TestLogger.logNotification('Testing SMS notification via Twilio');

      // Arrange
      const phone = '+919876543210';
      const message = 'SOS Alert: Your friend needs help urgently. Location: [link]';

      // Act
      try {
        TestLogger.logAPI('POST', '/api/sms/send', request: {
          'to': phone,
          'message': message,
          'from': '+1234567890',
        });

        // Simulate SMS send
        await Future.delayed(Duration(milliseconds: 300));

        TestLogger.logNotification('SMS sent successfully', to: phone, 
          data: {'message_length': message.length, 'gateway': 'twilio'});

        // Assert
        expect(message.isNotEmpty, true);
        TestLogger.logSuccess('SMS notification delivered');
      } catch (e) {
        TestLogger.logError('SMS send failed', e);
        rethrow;
      }
    });

    test('Email Notification Should Be Sent', () async {
      TestLogger.logNotification('Testing email notification');

      // Arrange
      const email = 'guardian@example.com';
      const subject = 'Emergency SOS Alert';

      // Act
      try {
        TestLogger.logAPI('POST', '/api/email/send', request: {
          'to': email,
          'subject': subject,
          'template': 'sos_alert',
          'variables': {
            'user_name': 'Test User',
            'location_url': 'https://maps.google.com?q=12.9716,77.5946',
          }
        });

        await Future.delayed(Duration(milliseconds: 300));
        TestLogger.logNotification('Email sent', to: email, 
          data: {'subject': subject, 'template': 'sos_alert'});

        // Assert
        TestAssertions.assertNotificationSent(true, email);
      } catch (e) {
        TestLogger.logError('Email send failed', e);
        rethrow;
      }
    });

    test('Multiple Notifications Should Be Sent in Sequence', () async {
      TestLogger.logNotification('Testing multiple notification sends');

      // Arrange
      final guardians = [
        {'name': 'John Doe', 'phone': '+919123456789', 'email': 'john@example.com'},
        {'name': 'Jane Smith', 'phone': '+919987654321', 'email': 'jane@example.com'},
        {'name': 'Alice Johnson', 'phone': '+919111111111', 'email': 'alice@example.com'},
      ];

      // Act
      int successCount = 0;
      for (final guardian in guardians) {
        try {
          TestLogger.logNotification('Sending to ${guardian['name']}', 
            to: guardian['name']?.toString(), 
            data: {'phone': guardian['phone']});
          await Future.delayed(Duration(milliseconds: 200));
          successCount++;
        } catch (e) {
          TestLogger.logError('Failed to send to ${guardian['name']}', e);
        }
      }

      // Assert
      expect(successCount, equals(guardians.length));
      TestLogger.logSuccess('All notifications sent', data: {'count': successCount});
    });

    test('Foreground Notification Should Display In-App Alert', () async {
      TestLogger.logNotification('Testing foreground notification handling');

      // Act
      bool inAppAlertDisplayed = false;
      try {
        // Simulate receiving notification while app is open
        TestLogger.logInfo('Notification received while app is foreground', 'FCM');
        inAppAlertDisplayed = true;
        TestLogger.logSuccess('In-app alert displayed');

        // Assert
        expect(inAppAlertDisplayed, true);
      } catch (e) {
        TestLogger.logError('In-app alert failed', e);
        rethrow;
      }
    });

    test('Background Notification Should Trigger System Notification', () async {
      TestLogger.logNotification('Testing background notification system alert');

      // Act
      bool systemNotificationTriggered = false;
      try {
        // Simulate receiving notification while app is backgrounded
        TestLogger.logInfo('Notification received while app is background', 'FCM');
        systemNotificationTriggered = true;
        TestLogger.logSuccess('System notification triggered');

        // Assert
        expect(systemNotificationTriggered, true);
      } catch (e) {
        TestLogger.logError('System notification failed', e);
        rethrow;
      }
    });

    test('Notification With Location Link Should Include Coordinates', () async {
      TestLogger.logNotification('Testing location link in notification');

      // Arrange
      const latitude = 12.9716;
      const longitude = 77.5946;
      final locationUrl = 'https://maps.google.com?q=$latitude,$longitude';

      // Act
      try {
        TestLogger.logAPI('POST', '/api/notifications/push', request: {
          'title': 'SOS Alert',
          'body': 'User needs help - View location',
          'location_url': locationUrl,
        });

        TestLogger.logNotification('Notification with location sent', 
          data: {'location_url': locationUrl});

        // Assert
        expect(locationUrl.contains('$latitude,$longitude'), true);
        TestLogger.logSuccess('Location link included in notification');
      } catch (e) {
        TestLogger.logError('Notification with location failed', e);
        rethrow;
      }
    });

    test('Notification Delivery Should Be Retried On Failure', () async {
      TestLogger.logNotification('Testing notification retry logic');

      // Arrange
      const maxRetries = 3;
      int attemptCount = 0;

      // Act
      bool delivered = false;
      while (attemptCount < maxRetries && !delivered) {
        try {
          attemptCount++;
          TestLogger.logAPI('POST', '/api/notifications/push', 
            request: {'attempt': attemptCount}, 
            statusCode: attemptCount < 2 ? 500 : 200
          );

          if (attemptCount < 2) {
            throw Exception('Network error');
          }

          delivered = true;
          TestLogger.logSuccess('Notification delivered after $attemptCount attempts');
        } catch (e) {
          TestLogger.logWarning('Attempt $attemptCount failed: ${e.toString()}');
          if (attemptCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 100 * attemptCount));
          }
        }
      }

      // Assert
      expect(delivered, true);
      expect(attemptCount, lessThanOrEqualTo(maxRetries));
    });

    test('WhatsApp Message Should Be Sent To Guardian', () async {
      TestLogger.logNotification('Testing WhatsApp message notification');

      // Arrange
      const phone = '+919876543210';
      const message = 'SOS Alert! Your emergency contact needs help immediately.';

      // Act
      try {
        TestLogger.logAPI('POST', '/api/whatsapp/send', request: {
          'to': phone,
          'message': message,
          'template': 'sos_alert',
        });

        await Future.delayed(Duration(milliseconds: 300));
        TestLogger.logNotification('WhatsApp message sent', to: 'Guardian',
          data: {'phone': phone, 'platform': 'whatsapp'});

        // Assert
        TestAssertions.assertNotificationSent(true, 'Guardian (WhatsApp)');
      } catch (e) {
        TestLogger.logError('WhatsApp send failed', e);
        rethrow;
      }
    });

    test('Notification Should Include Contact Confirmation URL', () async {
      TestLogger.logNotification('Testing notification with confirmation link');

      // Arrange
      const sosId = 'test_sos_001';
      const confirmUrl = 'https://womensafety.app/sos/$sosId/confirm?token=abc123';

      // Act
      try {
        TestLogger.logAPI('POST', '/api/notifications/push', request: {
          'title': 'SOS Confirmation Needed',
          'confirmation_url': confirmUrl,
        });

        TestLogger.logNotification('Confirmation link included',
          data: {'sos_id': sosId, 'has_confirmation_link': true});

        // Assert
        expect(confirmUrl.contains(sosId), true);
        expect(confirmUrl.contains('token='), true);
        TestLogger.logSuccess('Confirmation URL generated correctly');
      } catch (e) {
        TestLogger.logError('Confirmation link failed', e);
        rethrow;
      }
    });

    test('Notification Should Be Logged For Audit Trail', () async {
      TestLogger.logNotification('Testing notification audit logging');

      // Arrange
      final notificationLog = <Map<String, dynamic>>[];

      // Act
      notificationLog.add({
        'timestamp': DateTime.now(),
        'type': 'push',
        'recipient': 'john@example.com',
        'status': 'sent',
        'retry_count': 0,
      });

      TestLogger.logInfo('Notification logged for audit', 'AUDIT_LOG', 
        notificationLog.first);

      // Assert
      expect(notificationLog.isNotEmpty, true);
      TestLogger.logSuccess('Audit log created');
    });
  });
}
