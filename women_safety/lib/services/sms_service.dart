import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';

class SmsService {
  static const MethodChannel _smsChannel = MethodChannel('women_safety/sms');

  /// Send SOS SMS to all emergency contacts automatically.
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

      // Extract phone numbers and split accidental merged fields like "a;b" or "a,b".
      final recipients = _extractDistinctPhoneNumbers(
        contacts.map((contact) => contact.phone),
      );

      if (recipients.isEmpty) {
        debugPrint('❌ No emergency contacts found');
        return false;
      }

      debugPrint('📱 Sending SMS separately to ${recipients.length} contacts with location');

      final successCount = await _sendDirectSmsBulk(
        phones: recipients,
        message: message,
      );

      debugPrint('✅ SMS sent/opened for $successCount/${recipients.length} contacts');
      return successCount > 0;
    } catch (e) {
      debugPrint('❌ SMS service error: $e');
      return false;
    }
  }

  /// Send SMS to a single number
  static Future<int> _sendDirectSmsBulk({
    required List<String> phones,
    required String message,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return 0;
    }

    try {
      final sentCount = await _smsChannel.invokeMethod<int>('sendDirectSmsBulk', {
        'phones': phones,
        'message': message,
      });
      return sentCount ?? 0;
    } catch (e) {
      debugPrint('⚠️ Direct bulk SMS failed: $e');
      return 0;
    }
  }

  static String _normalizePhoneNumber(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.replaceAll(RegExp(r'\D'), '');
  }

  static List<String> _extractDistinctPhoneNumbers(Iterable<String> rawPhones) {
    final numbers = <String>{};

    for (final raw in rawPhones) {
      final value = raw.trim();
      if (value.isEmpty) {
        continue;
      }

      final splitCandidates = value
          .split(RegExp(r'[;,\n\r\t ]+'))
          .where((part) => part.trim().isNotEmpty)
          .toList();

      final candidates = splitCandidates.isEmpty ? <String>[value] : splitCandidates;
      for (final candidate in candidates) {
        final normalized = _normalizePhoneNumber(candidate);
        for (final expanded in _expandMergedCandidates(normalized)) {
          if (expanded.isNotEmpty) {
            numbers.add(expanded);
          }
        }
      }
    }

    return numbers.toList(growable: false);
  }

  static List<String> _expandMergedCandidates(String digitsOnlyPhone) {
    if (digitsOnlyPhone.isEmpty) {
      return const <String>[];
    }

    final len = digitsOnlyPhone.length;

    if (len == 10 || (len == 12 && digitsOnlyPhone.startsWith('91'))) {
      return <String>[digitsOnlyPhone];
    }

    if (len > 12) {
      if (len % 12 == 0 && digitsOnlyPhone.startsWith('91')) {
        final parts = <String>[];
        for (var i = 0; i < len; i += 12) {
          parts.add(digitsOnlyPhone.substring(i, i + 12));
        }
        return parts;
      }

      if (len % 10 == 0) {
        final parts = <String>[];
        for (var i = 0; i < len; i += 10) {
          parts.add(digitsOnlyPhone.substring(i, i + 10));
        }
        return parts;
      }
    }

    return <String>[digitsOnlyPhone];
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

  /// Send custom SMS automatically to each recipient.
  static Future<bool> sendCustomSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    try {
      if (phoneNumbers.isEmpty) {
        return false;
      }

      final recipients = _extractDistinctPhoneNumbers(phoneNumbers);

      if (recipients.isEmpty) {
        return false;
      }

      bool anyOpened = false;
      final successCount = await _sendDirectSmsBulk(
        phones: recipients,
        message: message,
      );
      anyOpened = successCount > 0;

      debugPrint('✅ SMS sent/opened for ${recipients.length} contacts');
      return anyOpened;
    } catch (e) {
      debugPrint('❌ Custom SMS error: $e');
      return false;
    }
  }
}
