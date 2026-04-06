import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';

class WhatsAppService {
  /// Convert user-entered phone number into WhatsApp-compatible digits.
  /// wa.me expects international number without '+' or separators.
  static String _normalizeWhatsAppNumber(String phoneNumber) {
    var digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    // Default India country code when only a 10-digit local number is provided.
    if (digits.length == 10) {
      digits = '91$digits';
    }

    if (digits.length == 11 && digits.startsWith('0')) {
      digits = '91${digits.substring(1)}';
    }

    return digits;
  }

  /// Launch WhatsApp using wa.me with fallback to whatsapp:// for better device compatibility.
  static Future<bool> _launchWhatsAppMessage({
    required String normalizedNumber,
    required String message,
  }) async {
    final Uri directSchemeUri = Uri.parse(
      'whatsapp://send?phone=$normalizedNumber&text=${Uri.encodeComponent(message)}',
    );
    final Uri waMeUri = Uri.https('wa.me', '/$normalizedNumber', {
      'text': message,
    });
    final Uri genericComposeUri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(message)}',
    );

    // Try direct WhatsApp app URI first (most reliable on Android devices).
    try {
      if (await canLaunchUrl(directSchemeUri)) {
        final launched = await launchUrl(
          directSchemeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Direct WhatsApp URI failed: $e');
    }

    // Fallback to wa.me universal link.
    try {
      final launched = await launchUrl(
        waMeUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ wa.me launch failed: $e');
    }

    // Last fallback: open WhatsApp compose without pre-selected number.
    try {
      if (await canLaunchUrl(genericComposeUri)) {
        return await launchUrl(
          genericComposeUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Generic WhatsApp compose failed: $e');
    }

    return false;
  }

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
  /// Supports both custom message (from MultiChannelMessageBuilder) or auto-built from SOSAlert
  static Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    String? message, // ✅ NEW: Custom message from message builder
    SOSAlert? alert, // ✅ Now optional - use message if provided
    String? contactName,
  }) async {
    try {
      // Validate inputs
      if (message == null && alert == null) {
        debugPrint('❌ Either message or alert must be provided');
        return false;
      }

      final cleanNumber = _normalizeWhatsAppNumber(phoneNumber);
      if (cleanNumber.length < 10) {
        debugPrint('❌ Invalid WhatsApp number for $contactName: $phoneNumber');
        return false;
      }

      // Use custom message if provided, otherwise build from alert
      final finalMessage = message ?? _buildWhatsAppMessageFromAlert(alert!);

      if (finalMessage.isEmpty) {
        debugPrint('❌ Empty message content');
        return false;
      }

      final launched = await _launchWhatsAppMessage(
        normalizedNumber: cleanNumber,
        message: finalMessage,
      );

      if (launched) {
        debugPrint('✅ WhatsApp sent to $contactName with location');
        return true;
      } else {
        debugPrint('❌ Could not open WhatsApp for $contactName');
        return false;
      }
    } catch (e) {
      debugPrint('❌ WhatsApp message error: $e');
      return false;
    }
  }

  /// Internal: Build WhatsApp message from SOSAlert (fallback for backward compatibility)
  static String _buildWhatsAppMessageFromAlert(SOSAlert alert) {
    final timestamp = alert.timestamp.toString().split('.')[0];
    return '''🚨 *EMERGENCY SOS ALERT* 🚨

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
  }

  /// Send a simple WhatsApp text without SOSAlert (used for volunteer notifications)
  static Future<bool> sendSimpleMessage({
    required String phoneNumber,
    required String message,
    String? contactName,
  }) async {
    try {
      final cleanNumber = _normalizeWhatsAppNumber(phoneNumber);
      if (cleanNumber.length < 10) {
        debugPrint('❌ Invalid WhatsApp number for $contactName: $phoneNumber');
        return false;
      }

      final launched = await _launchWhatsAppMessage(
        normalizedNumber: cleanNumber,
        message: message,
      );

      if (launched) {
        debugPrint('✅ Simple WhatsApp message sent to $contactName ($phoneNumber)');
        return true;
      } else {
        debugPrint('❌ Could not open WhatsApp for $contactName');
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
      final Uri nativeUri = Uri.parse('whatsapp://send');
      if (await canLaunchUrl(nativeUri)) {
        return true;
      }

      final Uri webUri = Uri.parse('https://wa.me/');
      return await canLaunchUrl(webUri);
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
        final cleanNumber = _normalizeWhatsAppNumber(contact.phone);
        if (cleanNumber.length < 10) {
          debugPrint('⚠️ Skipping invalid WhatsApp number for ${contact.name}');
          continue;
        }

        final launched = await _launchWhatsAppMessage(
          normalizedNumber: cleanNumber,
          message: message,
        );

        if (launched) {
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
        final cleanNumber = _normalizeWhatsAppNumber(contact.phone);
        if (cleanNumber.length < 10) {
          debugPrint('⚠️ Skipping invalid WhatsApp number for ${contact.name}');
          continue;
        }

        final launched = await _launchWhatsAppMessage(
          normalizedNumber: cleanNumber,
          message: message,
        );

        if (launched) {
          debugPrint('✅ Location snapshot sent to ${contact.name}');
          anySent = true;
          await Future.delayed(const Duration(seconds: 2));
        } else {
          debugPrint('⚠️ Could not open WhatsApp for ${contact.name}');
        }
      }

      return anySent;
    } catch (e) {
      debugPrint('❌ Error sharing location snapshot: $e');
      return false;
    }
  }
}
