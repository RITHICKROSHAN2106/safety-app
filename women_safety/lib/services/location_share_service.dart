import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/guardian.dart';
import 'whatsapp_service.dart';
import 'sms_service.dart';

/// Comprehensive Location Sharing Service
/// Allows sharing current or live location via multiple channels
class LocationShareService {
  /// Share current location snapshot to emergency contacts via multiple channels
  static Future<bool> shareCurrentLocation({
    required List<Guardian> contacts,
    String? customMessage,
    bool viaWhatsApp = true,
    bool viaSMS = false,
    bool viaShare = false,
  }) async {
    try {
      // Get current position
      final position = await _getCurrentPosition();
      if (position == null) {
        debugPrint('❌ Unable to get current location');
        return false;
      }

      final lat = position.latitude;
      final lon = position.longitude;
      final timestamp = DateTime.now().toString().split('.')[0];

      // Build location message
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
      final message = customMessage ??
          '''📍 My Current Location

I'm sharing my location with you.

🗺️ Open in Maps:
$googleMapsUrl

⏰ Time: $timestamp
📱 Coordinates: $lat, $lon

- Sent from Women Safety App''';

      int successCount = 0;

      // Share via WhatsApp
      if (viaWhatsApp && contacts.isNotEmpty) {
        debugPrint('📤 Sharing via WhatsApp...');
        final whatsappSuccess = await WhatsAppService.shareLocationSnapshot(
          contacts: contacts,
          latitude: lat,
          longitude: lon,
          customMessage: message,
        );
        if (whatsappSuccess) successCount++;
      }

      // Share via SMS
      if (viaSMS && contacts.isNotEmpty) {
        debugPrint('📤 Sharing via SMS...');
        final phoneNumbers = contacts.map((c) => c.phone).toList();
        final smsSuccess = await SmsService.sendCustomSms(
          phoneNumbers: phoneNumbers,
          message: message,
        );
        if (smsSuccess) successCount++;
      }

      debugPrint(successCount > 0
          ? '✅ Location shared via $successCount channel(s)'
          : '❌ Failed to share location');
      return successCount > 0;
    } catch (e) {
      debugPrint('❌ Location share error: $e');
      return false;
    }
  }

  /// Quick share location via WhatsApp (single tap)
  static Future<bool> quickShareLocation(List<Guardian> contacts) async {
    try {
      return await shareCurrentLocation(
        contacts: contacts,
        viaWhatsApp: true,
        viaSMS: false,
      );
    } catch (e) {
      debugPrint('❌ Quick share error: $e');
      return false;
    }
  }

  /// Share live tracking link (for continuous location updates)
  static Future<bool> shareLiveTracking({
    required List<Guardian> contacts,
    required String trackingSessionId,
    String? customMessage,
  }) async {
    try {
      if (contacts.isEmpty) {
        debugPrint('❌ No contacts to share with');
        return false;
      }

      // Generate tracking URL (you'll need to implement backend for this)
      final trackingUrl =
          'https://womensafety.app/track/$trackingSessionId'; // Replace with your actual tracking URL

      final message = customMessage ??
          '''🚨 LIVE LOCATION TRACKING

I'm sharing my live location with you. Track me in real-time:

🗺️ Live Tracking Link:
$trackingUrl

This link shows my location updates continuously.

⚠️ Please monitor and contact me if needed!

- Sent from Women Safety App''';

      // Share via WhatsApp
      final success = await WhatsAppService.shareLiveTrackingLink(
        contacts: contacts,
        trackingUrl: trackingUrl,
        customMessage: message,
      );

      debugPrint(success
          ? '✅ Live tracking link shared with ${contacts.length} contacts'
          : '❌ Failed to share live tracking');
      return success;
    } catch (e) {
      debugPrint('❌ Live tracking share error: $e');
      return false;
    }
  }

  /// Share location via specific app (WhatsApp, SMS, or system share)
  static Future<bool> shareVia({
    required String method, // 'whatsapp', 'sms', 'system'
    required List<Guardian> contacts,
    String? customMessage,
  }) async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return false;

      final lat = position.latitude;
      final lon = position.longitude;

      switch (method.toLowerCase()) {
        case 'whatsapp':
          return await WhatsAppService.shareLocationSnapshot(
            contacts: contacts,
            latitude: lat,
            longitude: lon,
            customMessage: customMessage,
          );
        case 'sms':
          final phoneNumbers = contacts.map((c) => c.phone).toList();
          final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
          final message = customMessage ??
              '📍 My Location: $googleMapsUrl\n⏰ ${DateTime.now()}\n- Women Safety App';
          return await SmsService.sendCustomSms(
            phoneNumbers: phoneNumbers,
            message: message,
          );
        case 'system':
          return await quickShareLocation(contacts);
        default:
          debugPrint('❌ Unknown share method: $method');
          return false;
      }
    } catch (e) {
      debugPrint('❌ Share via $method error: $e');
      return false;
    }
  }

  /// Get formatted location string
  static Future<String?> getLocationString() async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return null;

      final lat = position.latitude.toStringAsFixed(6);
      final lon = position.longitude.toStringAsFixed(6);
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      return '''📍 Location: $lat, $lon
🗺️ Maps: $googleMapsUrl
⏰ ${DateTime.now().toString().split('.')[0]}''';
    } catch (e) {
      debugPrint('❌ Get location string error: $e');
      return null;
    }
  }

  /// Helper: Get current position with error handling
  static Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services disabled');
        return null;
      }

      // Check permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission permanently denied');
        return null;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint('✅ Got location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error getting position: $e');
      return null;
    }
  }

  /// Check if location services are available
  static Future<bool> isLocationAvailable() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }
}
