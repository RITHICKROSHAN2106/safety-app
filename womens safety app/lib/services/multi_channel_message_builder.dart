import 'package:flutter/foundation.dart';
import '../models/sos_alert.dart';

/// Unified message builder for all multi-channel SOS communications
/// Ensures consistent location data and formatting across WhatsApp, SMS, Email, and Push notifications
class MultiChannelMessageBuilder {
  /// Build consistent SOS messages for all channels with unified location data
  static SOSMessageSet buildSOSMessages({
    required SOSAlert alert,
    required String userName,
    String? contactName,
  }) {
    final timestamp = alert.timestamp.toString().split('.')[0];
    final mapUrl = alert.getMapUrl();
    final coords = '${alert.latitude},${alert.longitude}';
    final googleMapsLink =
        'https://www.google.com/maps/search/?api=1&query=$coords';

    debugPrint('🔨 Building unified SOS messages with location:');
    debugPrint('   📍 Coordinates: $coords');
    debugPrint('   🗺️  Map URL: $mapUrl');
    debugPrint('   ⏰ Timestamp: $timestamp');

    // WhatsApp format (supports markdown, multiple links)
    final whatsappMessage = '''🚨 *EMERGENCY SOS ALERT* 🚨

⚠️ *$userName NEEDS IMMEDIATE HELP!*

📍 *My Current Location:*
$googleMapsLink

🗺️ *Google Maps Link:*
$mapUrl

⏰ *Time:* $timestamp
🚨 *Trigger:* ${alert.triggerType ?? 'Manual Button'}

🆘 *PLEASE RESPOND OR CALL ME IMMEDIATELY!*
⚠️ If I don't respond, call emergency services (112/100)

📌 Coordinates: $coords

- Sent from Women Safety App''';

    // SMS format (short, location-rich, efficient)
    final smsMessage = '''🚨 EMERGENCY SOS!

$userName needs help NOW!

📍 Location: $mapUrl

⏰ Time: $timestamp
📌 Coords: $coords

🚗 Call 112 or respond immediately!

- Women Safety App''';

    // Email format (detailed, professional, formatted)
    final emailMessage = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; color: #333; }
        .alert-header { background: #ff5252; color: white; padding: 20px; text-align: center; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #ff5252; }
        .label { font-weight: bold; color: #d32f2f; }
        .link-button { background: #ff5252; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="alert-header">
        <h1>🚨 EMERGENCY SOS ALERT 🚨</h1>
        <p>$userName has triggered an emergency SOS</p>
    </div>
    
    <div class="section">
        <h2>CRITICAL LOCATION INFORMATION</h2>
        <p><span class="label">📍 Current Location:</span></p>
        <ul>
            <li><strong>Latitude:</strong> ${alert.latitude}</li>
            <li><strong>Longitude:</strong> ${alert.longitude}</li>
            <li><strong>Map URL:</strong> <a href="$mapUrl" class="link-button">Open Google Maps</a></li>
            <li><strong>Coordinates:</strong> $coords</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>ALERT DETAILS</h2>
        <ul>
            <li><strong>⏰ Time:</strong> $timestamp</li>
            <li><strong>🚨 Trigger Type:</strong> ${alert.triggerType ?? 'Manual Button'}</li>
            <li><strong>👤 User:</strong> $userName</li>
            <li><strong>📱 App:</strong> Women Safety App</li>
        </ul>
    </div>
    
    <div class="section" style="background: #ffebee;">
        <h2>IMMEDIATE ACTIONS REQUIRED</h2>
        <ol>
            <li><strong>Contact $userName immediately</strong></li>
            <li><strong>If no response → Call Emergency (112/100)</strong></li>
            <li>Share location with local authorities if needed</li>
            <li>Provide any available assistance</li>
        </ol>
    </div>
    
    <div class="section">
        <h2>EMERGENCY SERVICE CONTACTS (India)</h2>
        <ul>
            <li><strong>🚔 Police/General Emergency:</strong> 112 or 100</li>
            <li><strong>🚑 Ambulance/Medical:</strong> 102</li>
            <li><strong>👩‍⚖️ Women Helpline:</strong> 181</li>
            <li><strong>🔥 Fire Service:</strong> 101</li>
        </ul>
    </div>
    
    <div class="section" style="background: #f5f5f5; text-align: center; color: #999;">
        <p>This is an automated emergency alert from the Women Safety App</p>
        <p>If you received this alert, please take immediate action</p>
    </div>
</body>
</html>''';

    // Push notification format (brief, actionable)
    final pushTitle = '🚨 SOS EMERGENCY';
    final pushBody = '$userName needs help! Location: $mapUrl';

    // Location data payload for notifications and sync
    final location = {
      'latitude': alert.latitude,
      'longitude': alert.longitude,
      'mapUrl': mapUrl,
      'googleMapsUrl': googleMapsLink,
      'coordinates': coords,
      'timestamp': timestamp,
      'triggerType': alert.triggerType ?? 'UNKNOWN',
    };

    debugPrint('✅ Unified messages created successfully');

    return SOSMessageSet(
      whatsapp: whatsappMessage,
      sms: smsMessage,
      email: emailMessage,
      pushTitle: pushTitle,
      pushBody: pushBody,
      location: location,
    );
  }

  /// Build location-only sharing messages (for non-emergency sharing)
  static SOSMessageSet buildLocationMessages({
    required double latitude,
    required double longitude,
    String? userName,
    String? customMessage,
  }) {
    final coords = '$latitude,$longitude';
    final googleMapsLink =
        'https://www.google.com/maps/search/?api=1&query=$coords';
    final timestamp = DateTime.now().toString().split('.')[0];

    final defaultMessage = customMessage ??
        '''📍 I'm sharing my location with you.

🗺️ Open in Google Maps:
$googleMapsLink

⏰ Time: $timestamp
📌 Coordinates: $coords

- Sent from Women Safety App''';

    // WhatsApp format
    final whatsappMessage = '''📍 *Location Sharing*

$defaultMessage''';

    // SMS format
    final smsMessage = '''📍 Location: $googleMapsLink
Time: $timestamp
Coords: $coords
- Women Safety App''';

    // Email format
    final emailMessage = '''
Location Information

$defaultMessage
''';

    // Push notification
    final pushTitle = '📍 Location Shared';
    final pushBody = 'Location: $googleMapsLink';

    final location = {
      'latitude': latitude,
      'longitude': longitude,
      'mapUrl': googleMapsLink,
      'googleMapsUrl': googleMapsLink,
      'coordinates': coords,
      'timestamp': timestamp,
    };

    return SOSMessageSet(
      whatsapp: whatsappMessage,
      sms: smsMessage,
      email: emailMessage,
      pushTitle: pushTitle,
      pushBody: pushBody,
      location: location,
    );
  }
}

/// Model to hold all message formats for consistent multi-channel delivery
class SOSMessageSet {
  /// WhatsApp message (supports markdown formatting)
  final String whatsapp;

  /// SMS message (compact, location-rich)
  final String sms;

  /// Email message (detailed HTML format)
  final String email;

  /// Push notification title
  final String pushTitle;

  /// Push notification body
  final String pushBody;

  /// Location data for all channels (payload, sync, etc.)
  final Map<String, dynamic> location;

  SOSMessageSet({
    required this.whatsapp,
    required this.sms,
    required this.email,
    required this.pushTitle,
    required this.pushBody,
    required this.location,
  });

  /// Get all location info as formatted string for logging
  String getLocationInfoLog() {
    return '''
📍 Location Information:
   Latitude: ${location['latitude']}
   Longitude: ${location['longitude']}
   Coordinates: ${location['coordinates']}
   Map URL: ${location['mapUrl']}
   Google Maps: ${location['googleMapsUrl']}
   Timestamp: ${location['timestamp']}
''';
  }

  /// Verify location data is complete
  bool isLocationDataComplete() {
    return location['latitude'] != null &&
        location['longitude'] != null &&
        location['mapUrl'] != null &&
        location['googleMapsUrl'] != null &&
        location['coordinates'] != null;
  }
}
