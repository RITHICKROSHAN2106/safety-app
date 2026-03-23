import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';

class WhatsAppService {
  /// Send WhatsApp message with live location to all contacts
  static Future<bool> sendSOSWhatsApp({
    required List<Guardian> contacts,
    required SOSAlert alert,
  }) async {
    try {
      if (contacts.isEmpty) {
        debugPrint('❌ No emergency contacts available');
        return false;
      }

      debugPrint('📤 Sending WhatsApp to ${contacts.length} contacts...');
      int successCount = 0;
      
      for (final contact in contacts) {
        try {
          final success = await sendWhatsAppMessage(
            phoneNumber: contact.phone,
            alert: alert,
            contactName: contact.name,
          );
          if (success) {
            successCount++;
            debugPrint('✅ WhatsApp sent to ${contact.name} ($successCount/${contacts.length})');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to send WhatsApp to ${contact.name}: $e');
        }
        
        // Delay between messages to allow app switching
        await Future.delayed(const Duration(milliseconds: 800));
      }
      
      final result = successCount > 0;
      debugPrint(result ? '✅ WhatsApp sent to $successCount contacts' : '❌ All WhatsApp sends failed');
      return result;
    } catch (e) {
      debugPrint('❌ WhatsApp service error: $e');
      return false;
    }
  }

  /// Send WhatsApp message to specific contact
  static Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    required SOSAlert alert,
    String? contactName,
  }) async {
    try {
      // Remove non-numeric characters
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      
      // Add country code if not present (assuming India +91)
      if (!cleanNumber.startsWith('+')) {
        cleanNumber = '+91$cleanNumber';
      }

      // Prepare WhatsApp message with live location link
      final timestamp = alert.timestamp.toString().split('.')[0]; // Remove microseconds
      final message = '''
🚨 *EMERGENCY SOS ALERT* 🚨

⚠️ I NEED IMMEDIATE HELP!

📍 *My Current Location:*
https://www.google.com/maps/search/?api=1&query=${alert.latitude},${alert.longitude}

🗺️ *Google Maps Link:*
${alert.getMapUrl()}

⏰ *Time:* $timestamp
📱 *Device:* Women Safety App

🆘 *PLEASE RESPOND OR CALL ME IMMEDIATELY!*
⚠️ If I don't respond, call emergency services (112/100)

Location coordinates: ${alert.latitude}, ${alert.longitude}
''';

      // WhatsApp URL scheme
      final Uri whatsappUri = Uri.parse(
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ WhatsApp message sent to $contactName ($phoneNumber)');
        return true;
      } else {
        debugPrint('❌ WhatsApp not installed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ WhatsApp message error: $e');
      return false;
    }
  }

  /// Send a simple WhatsApp text without SOSAlert (used for volunteer notifications)
  static Future<bool> sendSimpleMessage({
    required String phoneNumber,
    required String message,
    String? contactName,
  }) async {
    try {
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      if (!cleanNumber.startsWith('+')) {
        cleanNumber = '+91$cleanNumber';
      }
      final Uri whatsappUri = Uri.parse(
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Simple WhatsApp message sent to $contactName ($phoneNumber)');
        return true;
      } else {
        debugPrint('❌ WhatsApp not installed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Simple WhatsApp message error: $e');
      return false;
    }
  }

  /// Check if WhatsApp is installed
  static Future<bool> isWhatsAppInstalled() async {
    try {
      final Uri testUri = Uri.parse('https://wa.me/');
      return await canLaunchUrl(testUri);
    } catch (e) {
      return false;
    }
  }

  /// Share live tracking link via WhatsApp (for continuous location updates)
  static Future<bool> shareLiveTrackingLink({
    required List<Guardian> contacts,
    required String trackingUrl,
    String? customMessage,
  }) async {
    try {
      if (contacts.isEmpty) {
        debugPrint('❌ No emergency contacts available');
        return false;
      }

      final message = customMessage ?? '''
🚨 EMERGENCY - LIVE TRACKING 🚨

I need help! Track my live location in real-time:

🗺️ Live Tracking Link:
$trackingUrl

This link will show my location updates every few seconds.

🆘 Please monitor my location and contact me immediately!

- Sent from Women Safety App
''';

      bool anySent = false;
      for (final contact in contacts) {
        // Clean phone number
        String cleanNumber = contact.phone.replaceAll(RegExp(r'[^0-9+]'), '');
        
        // Add country code if not present (assuming India +91)
        if (!cleanNumber.startsWith('+')) {
          cleanNumber = '+91$cleanNumber';
        }

        // WhatsApp URL
        final Uri whatsappUri = Uri.parse(
          'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
        );

        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          debugPrint('✅ Live tracking link sent to ${contact.name}');
          anySent = true;
          
          // Delay between contacts to allow WhatsApp to open
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      return anySent;
    } catch (e) {
      debugPrint('❌ Error sharing live tracking link: $e');
      return false;
    }
  }

  /// Share current location snapshot via WhatsApp
  static Future<bool> shareLocationSnapshot({
    required List<Guardian> contacts,
    required double latitude,
    required double longitude,
    String? customMessage,
  }) async {
    try {
      final locationUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      
      final message = customMessage ?? '''
📍 My Current Location

Latitude: $latitude
Longitude: $longitude

🗺️ Open in Google Maps:
$locationUrl

⏰ Time: ${DateTime.now().toString()}

- Sent from Women Safety App
''';

      bool anySent = false;
      for (final contact in contacts) {
        String cleanNumber = contact.phone.replaceAll(RegExp(r'[^0-9+]'), '');
        if (!cleanNumber.startsWith('+')) {
          cleanNumber = '+91$cleanNumber';
        }

        final Uri whatsappUri = Uri.parse(
          'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
        );

        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          anySent = true;
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      return anySent;
    } catch (e) {
      debugPrint('❌ Error sharing location snapshot: $e');
      return false;
    }
  }
}
