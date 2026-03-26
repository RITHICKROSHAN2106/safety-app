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
  /// Supports both custom subject/body (from MultiChannelMessageBuilder) or auto-built
  static Future<bool> sendEmail({
    required String recipients,
    String? subject, // ✅ NEW: Custom subject from message builder
    String? body, // ✅ NEW: Custom body from message builder
    SOSAlert? alert, // Keep for backward compatibility
    String? userName,
  }) async {
    try {
      // Determine subject and body
      final finalSubject = subject ?? '🚨 EMERGENCY SOS ALERT from ${userName ?? "User"}';
      
      final finalBody = body ?? _buildEmailBodyFromAlert(alert, userName);

      if (recipients.isEmpty || finalSubject.isEmpty || finalBody.isEmpty) {
        debugPrint('❌ Missing required email parameters');
        return false;
      }

      debugPrint('📧 Sending email to $recipients with location');

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipients,
        query: 'subject=${Uri.encodeComponent(finalSubject)}&body=${Uri.encodeComponent(finalBody)}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        debugPrint('✅ Email sent with location details');
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

  /// Internal: Build email body from SOSAlert (fallback for backward compatibility)
  static String _buildEmailBodyFromAlert(SOSAlert? alert, String? userName) {
    if (alert == null) {
      return 'Emergency alert sent from Women Safety App';
    }

    return '''
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
}

}
