import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';

class SmsService {
  /// Send SOS SMS to all emergency contacts (opens system SMS composer)
  /// Supports both custom message (from MultiChannelMessageBuilder) or auto-built from SOSAlert
  static Future<bool> sendSOSSms({
    required List<Guardian> contacts,
    required SOSAlert alert,
    String? customMessage, // ✅ NEW: Custom message from message builder
  }) async {
    try {
      // Check and request SMS permission if needed
      if (!await Permission.sms.isGranted) {
        final result = await Permission.sms.request();
        if (!result.isGranted) {
          debugPrint('⚠️ SMS permission not granted');
          return false;
        }
      }

      // Prepare SMS message (use custom if provided, otherwise build from alert)
      final message = customMessage ?? _buildSOSMessage(alert);

      // Extract phone numbers
      final List<String> recipients = contacts
          .map((contact) => contact.phone)
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (recipients.isEmpty) {
        debugPrint('❌ No emergency contacts found');
        return false;
      }

      // Send to all contacts in BATCH - open one SMS composer with all recipients
      // Join multiple recipients with semicolons for batch SMS
      final allRecipients = recipients.join(';');
      
      debugPrint('📱 Sending SMS to ${recipients.length} contacts with location');
      final sent = await _sendToNumber(allRecipients, message);
      
      if (sent) {
        debugPrint('✅ SMS composer opened for ALL ${recipients.length} contacts (BATCH) with location');
        debugPrint('ℹ️  User needs to tap SEND once to message all contacts');
        return true;
      } else {
        debugPrint('⚠️ Batch SMS failed, trying individual sends...');
        // Fallback: open individual composers
        bool anyOpened = false;
        for (final phone in recipients) {
          final sent = await _sendToNumber(phone, message);
          if (sent) anyOpened = true;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        return anyOpened;
      }
    } catch (e) {
      debugPrint('❌ SMS service error: $e');
      return false;
    }
  }

  /// Send SMS to a single number
  static Future<bool> _sendToNumber(String phoneNumber, String message) async {
    try {
      // Clean phone number
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Build SMS URI
      final smsUri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        queryParameters: {'body': message},
      );

      try {
        // Try to launch directly without checking canLaunchUrl
        // (canLaunchUrl may return false even when SMS app exists)
        final launched = await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          debugPrint('✅ SMS composer opened for $cleanPhone');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Primary SMS method failed: $e');
      }

      // Fallback 1: Try smsto: scheme
      try {
        final smstoUri = Uri.parse('smsto:$cleanPhone?body=${Uri.encodeComponent(message)}');
        final launched = await launchUrl(
          smstoUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          debugPrint('✅ SMS composer opened (smsto) for $cleanPhone');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ smsto method failed: $e');
      }

      // Fallback 2: Try mms: scheme (also works for SMS)
      try {
        final mmsUri = Uri.parse('mms:$cleanPhone?body=${Uri.encodeComponent(message)}');
        final launched = await launchUrl(
          mmsUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          debugPrint('✅ SMS composer opened (mms) for $cleanPhone');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ mms method failed: $e');
      }

      debugPrint('❌ All SMS methods failed for $cleanPhone');
      return false;
    } catch (e) {
      debugPrint('❌ Error sending SMS to $phoneNumber: $e');
      return false;
    }
  }

  /// Build SOS message
  static String _buildSOSMessage(SOSAlert alert) {
    final timestamp = alert.timestamp.toString().split('.')[0];
    return '''🚨 EMERGENCY - NEED HELP!

📍 Location:
${alert.getMapUrl()}

⏰ $timestamp

🆘 CALL ME NOW!
No response? Call 112/100

Coords: ${alert.latitude},${alert.longitude}
- Women Safety App''';
  }

  /// Send SMS with custom message (opens composer for each recipient)
  static Future<bool> sendCustomSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    try {
      if (phoneNumbers.isEmpty) {
        return false;
      }

      bool anyOpened = false;
      for (final phone in phoneNumbers) {
        final sent = await _sendToNumber(phone, message);
        if (sent) anyOpened = true;
        await Future.delayed(const Duration(milliseconds: 800));
      }

      debugPrint('✅ SMS composer opened for ${phoneNumbers.length} contacts');
      return anyOpened;
    } catch (e) {
      debugPrint('❌ Custom SMS error: $e');
      return false;
    }
  }
}
