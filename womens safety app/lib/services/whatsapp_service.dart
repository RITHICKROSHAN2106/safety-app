/// WhatsApp Service
/// Handles sharing messages and location via WhatsApp
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class WhatsAppService {
  // Send message via WhatsApp to a specific phone number
  Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Encode message for URL
      String encodedMessage = Uri.encodeComponent(message);

      // Create WhatsApp URL
      String url;
      if (Platform.isAndroid) {
        url = 'https://wa.me/$cleanNumber?text=$encodedMessage';
      } else if (Platform.isIOS) {
        url = 'whatsapp://send?phone=$cleanNumber&text=$encodedMessage';
      } else {
        url = 'https://wa.me/$cleanNumber?text=$encodedMessage';
      }

      final uri = Uri.parse(url);

      // Check if WhatsApp is installed
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('WhatsApp is not installed');
      }
    } catch (e) {
      throw Exception('Failed to send WhatsApp message: $e');
    }
  }

  // Send message to multiple contacts
  Future<Map<String, bool>> sendMessageToMultiple({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    Map<String, bool> results = {};

    for (String phone in phoneNumbers) {
      try {
        bool success = await sendMessage(
          phoneNumber: phone,
          message: message,
        );
        results[phone] = success;
        // Add delay between messages to avoid rate limiting
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        results[phone] = false;
      }
    }

    return results;
  }

  // Send location via WhatsApp
  Future<bool> shareLocation({
    required String phoneNumber,
    required double latitude,
    required double longitude,
    String? customMessage,
  }) async {
    String message = customMessage ??
        '🚨 EMERGENCY! I need help!\n\n'
            'My location: https://www.google.com/maps?q=$latitude,$longitude';

    return await sendMessage(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Send SOS alert via WhatsApp
  Future<bool> sendSosAlert({
    required String phoneNumber,
    required String userName,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    String message = '🆘 SOS ALERT! 🆘\n\n';
    message += '$userName needs immediate help!\n\n';
    message += 'Location Details:\n';
    if (address != null) {
      message += 'Address: $address\n';
    }
    message += 'Coordinates: $latitude, $longitude\n\n';
    message += 'Google Maps: https://www.google.com/maps?q=$latitude,$longitude\n\n';
    message += 'Please respond immediately!';

    return await sendMessage(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Check if WhatsApp is installed
  Future<bool> isWhatsAppInstalled() async {
    try {
      final url = Platform.isIOS ? 'whatsapp://' : 'https://wa.me/';
      final uri = Uri.parse(url);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  // Open WhatsApp without a specific contact
  Future<bool> openWhatsApp() async {
    try {
      final url = Platform.isIOS ? 'whatsapp://' : 'https://wa.me/';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
