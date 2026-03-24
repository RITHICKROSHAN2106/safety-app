/// SMS Service
/// Handles sending SMS messages for emergency alerts
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  // Send SMS to a single recipient
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Create SMS URL with encoded message
      String encodedMessage = Uri.encodeComponent(message);
      final uri = Uri.parse('sms:$cleanNumber?body=$encodedMessage');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        throw Exception('Cannot send SMS');
      }
    } catch (e) {
      throw Exception('Failed to send SMS: $e');
    }
  }

  // Send SMS to multiple recipients
  Future<Map<String, bool>> sendSmsToMultiple({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    Map<String, bool> results = {};

    for (String phone in phoneNumbers) {
      try {
        bool success = await sendSms(
          phoneNumber: phone,
          message: message,
        );
        results[phone] = success;
        // Small delay between messages
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        results[phone] = false;
      }
    }

    return results;
  }

  // Send SOS SMS alert
  Future<bool> sendSosAlert({
    required String phoneNumber,
    required String userName,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    String message = 'SOS ALERT!\n\n';
    message += '$userName needs help!\n\n';
    if (address != null) {
      message += 'Location: $address\n';
    }
    message += 'Maps: https://maps.google.com/?q=$latitude,$longitude';

    return await sendSms(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Send location via SMS
  Future<bool> shareLocation({
    required String phoneNumber,
    required double latitude,
    required double longitude,
    String? customMessage,
  }) async {
    String message = customMessage ??
        'My current location:\nhttps://maps.google.com/?q=$latitude,$longitude';

    return await sendSms(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Send bulk SMS to all guardians
  Future<List<String>> sendBulkSosAlert({
    required List<String> phoneNumbers,
    required String userName,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    List<String> successfulSends = [];

    String message = 'EMERGENCY! $userName needs help!\n';
    if (address != null) {
      message += 'At: $address\n';
    }
    message += 'Location: https://maps.google.com/?q=$latitude,$longitude';

    for (String phone in phoneNumbers) {
      try {
        bool success = await sendSms(
          phoneNumber: phone,
          message: message,
        );
        if (success) {
          successfulSends.add(phone);
        }
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // Continue with next number
        continue;
      }
    }

    return successfulSends;
  }

  // Check if device can send SMS
  Future<bool> canSendSms() async {
    try {
      final uri = Uri.parse('sms:');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
}
