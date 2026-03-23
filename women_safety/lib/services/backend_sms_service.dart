import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/guardian.dart';
import '../models/sos_alert.dart';
import 'config.dart';

/// 🚀 Backend SMS Service - Fully automatic SMS via server
/// Uses SMS Gateway API (Twilio/AWS SNS/Fast2SMS) for automatic sending
class BackendSmsService {
  /// Send SOS SMS automatically via backend (NO USER INTERACTION)
  static Future<bool> sendAutomaticSOSSms({
    required List<Guardian> contacts,
    required SOSAlert alert,
    required String userName,
  }) async {
    try {
      debugPrint('� STARTING AUTOMATIC SMS SERVICE');
      
      // Prepare SMS message
      final message = _buildSOSMessage(alert, userName);
      debugPrint('📧 Message: $message');

      // Extract phone numbers
      final List<String> recipients = contacts
          .map((contact) => contact.phone)
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (recipients.isEmpty) {
        debugPrint('❌ No emergency contacts found');
        return false;
      }

      debugPrint('👥 Recipients: $recipients');

      // OPTION 1: Use your own backend server
      debugPrint('🌐 TRY 1: Backend server...');
      final backendSuccess = await _sendViaBackend(recipients, message, alert);
      if (backendSuccess) {
        debugPrint('✅ SMS SENT VIA BACKEND!');
        return true;
      }

      // OPTION 2: Use Fast2SMS (India) - Direct API
      debugPrint('🚀 TRY 2: Fast2SMS API...');
      final fast2smsSuccess = await _sendViaFast2SMS(recipients, message);
      if (fast2smsSuccess) {
        debugPrint('✅ SMS SENT VIA FAST2SMS!');
        return true;
      }

      // OPTION 3: Use Twilio - Direct API
      debugPrint('🌍 TRY 3: Twilio API...');
      final twilioSuccess = await _sendViaTwilio(recipients, message);
      if (twilioSuccess) {
        debugPrint('✅ SMS SENT VIA TWILIO!');
        return true;
      }

      debugPrint('❌ All automatic SMS methods FAILED!');
      return false;
    } catch (e) {
      debugPrint('❌ CRITICAL ERROR IN SMS SERVICE: $e');
      return false;
    }
  }

  /// Send via your own backend server (RECOMMENDED)
  static Future<bool> _sendViaBackend(
    List<String> recipients,
    String message,
    SOSAlert alert,
  ) async {
    try {
      final backendUrl = Config.backendUrl;
      if (backendUrl.isEmpty || backendUrl == 'YOUR_BACKEND_URL') {
        debugPrint('⚠️ Backend URL not configured, skipping...');
        return false;
      }

      final response = await http.post(
        Uri.parse('$backendUrl/api/sms/send-sos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.backendApiKey}',
        },
        body: jsonEncode({
          'recipients': recipients,
          'message': message,
          'latitude': alert.latitude,
          'longitude': alert.longitude,
          'timestamp': alert.timestamp.toIso8601String(),
          'urgent': true,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Backend SMS response: ${data['message']}');
        return data['success'] == true;
      } else {
        debugPrint('❌ Backend SMS failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Backend SMS error: $e');
      return false;
    }
  }

  /// Send via Fast2SMS (India only) - Direct API
  static Future<bool> _sendViaFast2SMS(
    List<String> recipients,
    String message,
  ) async {
    try {
      final apiKey = Config.fast2smsApiKey;
      if (apiKey.isEmpty || apiKey == 'YOUR_FAST2SMS_API_KEY') {
        debugPrint('⚠️ Fast2SMS API key NOT configured');
        return false;
      }

      // Clean and format phone numbers
      final List<String> cleanNumbers = [];
      for (final phone in recipients) {
        String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
        // Remove country code if present
        if (cleaned.startsWith('91')) {
          cleaned = cleaned.substring(2);
        }
        // Ensure 10 digits
        if (cleaned.length >= 10) {
          cleanNumbers.add(cleaned.substring(cleaned.length - 10));
        }
      }

      if (cleanNumbers.isEmpty) {
        debugPrint('⚠️ No valid 10-digit numbers found');
        debugPrint('⚠️ Original: $recipients');
        return false;
      }

      final numbersString = cleanNumbers.join(',');
      final shortMessage = message.length > 160 ? message.substring(0, 160) : message;
      
      debugPrint('📤 Numbers: $numbersString');
      debugPrint('📤 Message length: ${shortMessage.length}');

      // Try GET method (more reliable than POST)
      final url = Uri.parse(
        'https://www.fast2sms.com/dev/bulkV2'
        '?authorization=$apiKey'
        '&route=q'
        '&sender_id=FSTSMS'
        '&message=${Uri.encodeComponent(shortMessage)}'
        '&language=english'
        '&flash=0'
        '&numbers=$numbersString'
      );

      debugPrint('🌐 Calling Fast2SMS GET API...');
      final response = await http.get(
        url,
        headers: {
          'authorization': apiKey,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['return'] == true) {
          debugPrint('✅ Fast2SMS SUCCESS! Sent to ${cleanNumbers.length} numbers');
          return true;
        } else {
          debugPrint('❌ Fast2SMS returned: ${data['message'] ?? "Unknown error"}');
          return false;
        }
      } else {
        debugPrint('❌ HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      return false;
    }
  }

  /// Send via Twilio (Global) - Direct API
  static Future<bool> _sendViaTwilio(
    List<String> recipients,
    String message,
  ) async {
    try {
      // Get Twilio credentials from config
      final accountSid = Config.twilioAccountSid;
      final authToken = Config.twilioAuthToken;
      final fromNumber = Config.twilioFromNumber;

      if (accountSid.isEmpty || accountSid == 'YOUR_TWILIO_ACCOUNT_SID') {
        debugPrint('⚠️ Twilio not configured, skipping...');
        return false;
      }

      // Send to each recipient (Twilio charges per SMS)
      int successCount = 0;
      for (final recipient in recipients) {
        try {
          final response = await http.post(
            Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'),
            headers: {
              'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
            },
            body: {
              'From': fromNumber,
              'To': recipient,
              'Body': message,
            },
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 201) {
            successCount++;
            debugPrint('✅ Twilio SMS sent to $recipient');
          } else {
            debugPrint('❌ Twilio failed for $recipient: ${response.body}');
          }

          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('❌ Twilio error for $recipient: $e');
        }
      }

      if (successCount > 0) {
        debugPrint('✅ Twilio sent $successCount/${recipients.length} messages');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Twilio error: $e');
      return false;
    }
  }

  /// Build SOS message
  static String _buildSOSMessage(SOSAlert alert, String userName) {
    return '''🚨 EMERGENCY SOS from $userName!

📍 ${alert.getMapUrl()}

⏰ ${alert.timestamp.toString().split('.')[0]}

🆘 CALL IMMEDIATELY!
No response? Call 112

Women Safety App''';
  }
}
