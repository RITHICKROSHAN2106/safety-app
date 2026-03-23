import 'package:url_launcher/url_launcher.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  /// Send SOS email to all contacts
  static Future<bool> sendSOSEmail({
    required List<Guardian> contacts,
    required SOSAlert alert,
    String? userName,
  }) async {
    try {
      final recipients = contacts
          .map((c) => c.email)
          .where((email) => email != null && email.isNotEmpty)
          .join(',');

      if (recipients.isEmpty) {
        debugPrint('❌ No email addresses found');
        return false;
      }

      return await sendEmail(
        recipients: recipients,
        alert: alert,
        userName: userName,
      );
    } catch (e) {
      debugPrint('❌ Email service error: $e');
      return false;
    }
  }

  /// Send email with SOS details
  static Future<bool> sendEmail({
    required String recipients,
    required SOSAlert alert,
    String? userName,
  }) async {
    try {
      final subject = '🚨 EMERGENCY SOS ALERT from ${userName ?? "User"}';
      
      final body = '''
EMERGENCY SOS ALERT

${userName ?? "A user"} has triggered an emergency SOS alert and needs immediate help.

ALERT DETAILS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Location:
   Latitude: ${alert.latitude}
   Longitude: ${alert.longitude}
   
🗺️ Map Link (OpenStreetMap):
  ${alert.getMapUrl()}

⏰ Alert Time:
   ${alert.timestamp.toString()}

🚨 Trigger Type:
   ${alert.triggerType ?? 'Manual Button'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMMEDIATE ACTIONS REQUIRED:
1. Contact ${userName ?? "the user"} immediately
2. Call emergency services if unable to reach
3. Share location with local authorities if needed

This is an automated emergency alert from the Women Safety App.

For emergency services:
• Police: 112 / 100
• Ambulance: 102
• Women Helpline: 181
''';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipients,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        debugPrint('✅ Email sent to: $recipients');
        return true;
      } else {
        debugPrint('❌ Cannot launch email client');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email sending error: $e');
      return false;
    }
  }
}
