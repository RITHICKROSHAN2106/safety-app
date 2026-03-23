# SOS Implementation Guide

This guide covers implementing all SOS features for the Women Safety App.

---

## 🚨 SOS Features Overview

When SOS is triggered (button press, shake, or voice), the app will:

1. ✅ **Send SMS** to all emergency contacts
2. ✅ **Make phone calls** to primary contact
3. ✅ **Send WhatsApp messages** with location
4. ✅ **Send email** with location details
5. ✅ **Record audio/video** evidence
6. ✅ **Upload media** to Firebase Storage
7. ✅ **Send push notifications** via FCM
8. ✅ **Share live location** link
9. ✅ **Create backend alert** for tracking

---

## 📁 File Structure

```
lib/
├── services/
│   ├── sos_service.dart           # Main SOS coordinator
│   ├── sms_service.dart           # SMS functionality
│   ├── call_service.dart          # Phone call functionality
│   ├── whatsapp_service.dart      # WhatsApp integration
│   ├── email_service.dart         # Email functionality
│   ├── recording_service.dart     # Audio/video recording
│   ├── storage_service.dart       # Firebase Storage upload
│   └── shake_detector_service.dart # Shake detection
├── bloc/
│   └── sos/
│       ├── sos_cubit.dart         # SOS state management
│       └── sos_state.dart         # SOS states
└── models/
    └── sos_alert.dart             # SOS alert model
```

---

## 🛠️ Implementation Steps

### Step 1: Update Dependencies

**File**: `pubspec.yaml`

Ensure these packages are present (already added):
```yaml
dependencies:
  flutter_sms: ^2.3.3           # SMS sending
  url_launcher: ^6.3.2          # Calls, WhatsApp, Email
  camera: ^0.11.2               # Video recording
  path_provider: ^2.1.1         # File paths
  firebase_storage: ^13.0.3     # Media upload
  sensors_plus: ^7.0.0          # Shake detection
  speech_to_text: ^7.3.0        # Voice activation
  geolocator: ^14.0.2           # Location
  permission_handler: ^12.0.1   # Permissions
```

### Step 2: Create SOS Alert Model

**File**: `lib/models/sos_alert.dart`

```dart
class SOSAlert {
  final String? id;
  final String userId;
  final double latitude;
  final double longitude;
  final String? mediaUrl;
  final DateTime timestamp;
  final String status; // ACTIVE, RESOLVED, FALSE_ALARM
  final String? triggerType; // BUTTON, SHAKE, VOICE
  final String? notes;

  SOSAlert({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.mediaUrl,
    required this.timestamp,
    this.status = 'ACTIVE',
    this.triggerType,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'triggerType': triggerType,
      'notes': notes,
    };
  }

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id']?.toString(),
      userId: json['userId'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      mediaUrl: json['mediaUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'] ?? 'ACTIVE',
      triggerType: json['triggerType'],
      notes: json['notes'],
    );
  }

  String getGoogleMapsUrl() {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }
}
```

---

## 📱 Implementation: SMS Service

**File**: `lib/services/sms_service.dart`

```dart
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';

class SmsService {
  /// Send SOS SMS to all emergency contacts
  static Future<bool> sendSOSSms({
    required List<Guardian> contacts,
    required SOSAlert alert,
  }) async {
    try {
      // Check SMS permission
      final status = await Permission.sms.status;
      if (!status.isGranted) {
        final result = await Permission.sms.request();
        if (!result.isGranted) {
          print('❌ SMS permission denied');
          return false;
        }
      }

      // Prepare SMS message
      final message = '''
🚨 EMERGENCY SOS ALERT 🚨

I need help! I have triggered an emergency SOS alert.

📍 My Location:
${alert.getGoogleMapsUrl()}

⏰ Time: ${alert.timestamp.toString()}

🆘 Please contact me immediately or call emergency services!

- Sent from Women Safety App
''';

      // Extract phone numbers
      final List<String> recipients = contacts
          .map((contact) => contact.phone)
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (recipients.isEmpty) {
        print('❌ No emergency contacts found');
        return false;
      }

      // Send SMS to all contacts
      String result = await sendSMS(
        message: message,
        recipients: recipients,
        sendDirect: true, // Send without user confirmation
      ).catchError((error) {
        print('❌ SMS send error: $error');
        return 'error';
      });

      print('✅ SMS sent to ${recipients.length} contacts: $result');
      return true;
    } catch (e) {
      print('❌ SMS service error: $e');
      return false;
    }
  }

  /// Send SMS with custom message
  static Future<bool> sendCustomSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    try {
      String result = await sendSMS(
        message: message,
        recipients: phoneNumbers,
        sendDirect: true,
      );
      
      return result != 'error';
    } catch (e) {
      print('❌ Custom SMS error: $e');
      return false;
    }
  }
}
```

---

## 📞 Implementation: Call Service

**File**: `lib/services/call_service.dart`

```dart
import 'package:url_launcher/url_launcher.dart';
import '../models/guardian.dart';

class CallService {
  /// Make emergency call to primary contact
  static Future<bool> makeEmergencyCall(List<Guardian> contacts) async {
    try {
      // Find primary contact
      final primaryContact = contacts.firstWhere(
        (contact) => contact.isPrimary,
        orElse: () => contacts.isNotEmpty ? contacts.first : Guardian(name: '', phone: ''),
      );

      if (primaryContact.phone.isEmpty) {
        print('❌ No primary contact phone number');
        return false;
      }

      return await makeCall(primaryContact.phone);
    } catch (e) {
      print('❌ Emergency call error: $e');
      return false;
    }
  }

  /// Make call to specific phone number
  static Future<bool> makeCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        print('✅ Call initiated to $phoneNumber');
        return true;
      } else {
        print('❌ Cannot launch phone dialer');
        return false;
      }
    } catch (e) {
      print('❌ Call service error: $e');
      return false;
    }
  }

  /// Call emergency services (911, 112, etc.)
  static Future<bool> callEmergencyServices(String emergencyNumber) async {
    return await makeCall(emergencyNumber);
  }
}
```

---

## 💬 Implementation: WhatsApp Service

**File**: `lib/services/whatsapp_service.dart`

```dart
import 'package:url_launcher/url_launcher.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';

class WhatsAppService {
  /// Send WhatsApp message to all contacts
  static Future<bool> sendSOSWhatsApp({
    required List<Guardian> contacts,
    required SOSAlert alert,
  }) async {
    try {
      for (final contact in contacts) {
        await sendWhatsAppMessage(
          phoneNumber: contact.phone,
          alert: alert,
          contactName: contact.name,
        );
      }
      return true;
    } catch (e) {
      print('❌ WhatsApp service error: $e');
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

      // Prepare WhatsApp message
      final message = '''
🚨 EMERGENCY SOS ALERT 🚨

I need help! I have triggered an emergency SOS alert.

📍 My Location:
${alert.getGoogleMapsUrl()}

⏰ Time: ${alert.timestamp.toString()}

🆘 Please contact me immediately or call emergency services!

- Sent from Women Safety App
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
        print('✅ WhatsApp message sent to $contactName ($phoneNumber)');
        return true;
      } else {
        print('❌ WhatsApp not installed');
        return false;
      }
    } catch (e) {
      print('❌ WhatsApp message error: $e');
      return false;
    }
  }

  /// Check if WhatsApp is installed
  static Future<bool> isWhatsAppInstalled() async {
    final Uri testUri = Uri.parse('https://wa.me/');
    return await canLaunchUrl(testUri);
  }
}
```

---

## 📧 Implementation: Email Service

**File**: `lib/services/email_service.dart`

```dart
import 'package:url_launcher/url_launcher.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';

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
        print('❌ No email addresses found');
        return false;
      }

      return await sendEmail(
        recipients: recipients,
        alert: alert,
        userName: userName,
      );
    } catch (e) {
      print('❌ Email service error: $e');
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
   
🗺️ Google Maps Link:
   ${alert.getGoogleMapsUrl()}

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
        print('✅ Email sent to: $recipients');
        return true;
      } else {
        print('❌ Cannot launch email client');
        return false;
      }
    } catch (e) {
      print('❌ Email sending error: $e');
      return false;
    }
  }
}
```

---

## 🎥 Implementation: Recording Service

**File**: `lib/services/recording_service.dart`

```dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordingService {
  static CameraController? _cameraController;
  static bool _isRecording = false;

  /// Start video recording
  static Future<String?> startVideoRecording() async {
    try {
      // Check camera and microphone permissions
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        print('❌ Camera/Microphone permission denied');
        return null;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('❌ No cameras available');
        return null;
      }

      // Initialize camera (front camera preferred for safety)
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      
      // Start recording
      await _cameraController!.startVideoRecording();
      _isRecording = true;

      print('✅ Video recording started');
      return 'recording';
    } catch (e) {
      print('❌ Start recording error: $e');
      return null;
    }
  }

  /// Stop video recording and return file path
  static Future<String?> stopVideoRecording() async {
    try {
      if (_cameraController == null || !_isRecording) {
        print('❌ No active recording');
        return null;
      }

      final XFile videoFile = await _cameraController!.stopVideoRecording();
      _isRecording = false;

      // Dispose camera controller
      await _cameraController!.dispose();
      _cameraController = null;

      print('✅ Video saved: ${videoFile.path}');
      return videoFile.path;
    } catch (e) {
      print('❌ Stop recording error: $e');
      return null;
    }
  }

  /// Record for specified duration (e.g., 30 seconds)
  static Future<String?> recordForDuration(Duration duration) async {
    try {
      await startVideoRecording();
      
      // Wait for specified duration
      await Future.delayed(duration);
      
      return await stopVideoRecording();
    } catch (e) {
      print('❌ Timed recording error: $e');
      return null;
    }
  }

  /// Check if currently recording
  static bool get isRecording => _isRecording;

  /// Clean up camera resources
  static Future<void> dispose() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
    _isRecording = false;
  }
}
```

---

**Continue to Part 2 for Storage, Shake Detection, and Main SOS Coordinator...**
