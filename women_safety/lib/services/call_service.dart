import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/guardian.dart';

class CallService {
  /// Make emergency call to primary contact
  static Future<bool> makeEmergencyCall(List<Guardian> contacts) async {
    final callStarted = await _placeCallWithEscalation(
      contacts: contacts,
      attemptIndex: 0,
    );

    return callStarted;
  }

  static Future<bool> _placeCallWithEscalation({
    required List<Guardian> contacts,
    required int attemptIndex,
  }) async {
    try {
      if (contacts.isEmpty) {
        debugPrint('❌ No emergency contacts available');
        return false;
      }

      // Find primary contact
      Guardian targetContact;

      if (attemptIndex == 0) {
        targetContact = contacts.firstWhere(
          (contact) => contact.isPrimary,
          orElse: () => contacts.first,
        );
      } else {
        final nonPrimary = contacts
            .where((contact) => !contact.isPrimary)
            .toList(growable: false);

        if (nonPrimary.isEmpty) {
          debugPrint('ℹ️ No additional contacts for escalation');
          return false;
        }

        if (attemptIndex - 1 >= nonPrimary.length) {
          debugPrint('ℹ️ Escalation attempts exhausted');
          return false;
        }

        targetContact = nonPrimary[attemptIndex - 1];
      }

      if (targetContact.phone.isEmpty) {
        debugPrint('❌ Target contact missing phone number');
        return false;
      }

      final callPlaced = await makeCall(targetContact.phone);

      if (!callPlaced) {
        debugPrint('⚠️ Call attempt failed for ${targetContact.name}');
        return false;
      }

      debugPrint('✅ Call initiated to ${targetContact.name} (${targetContact.phone})');
      return true;
    } catch (e) {
      debugPrint('❌ Emergency call error: $e');
      return false;
    }
  }

  /// Make call to specific phone number
  static Future<bool> makeCall(String phoneNumber) async {
    try {
      if (await _tryDirectCall(phoneNumber)) {
        debugPrint('✅ Direct call placed to $phoneNumber');
        return true;
      }

      if (await _launchDialer(phoneNumber)) {
        debugPrint('ℹ️ Fallback dialer opened for $phoneNumber');
        return true;
      }

      debugPrint('❌ Cannot initiate phone call to $phoneNumber');
      return false;
    } catch (e) {
      debugPrint('❌ Call service error: $e');
      return false;
    }
  }

  /// Attempt a direct phone call when platform and permissions allow.
  static Future<bool> _tryDirectCall(String phoneNumber) async {
    if (!Platform.isAndroid) {
      debugPrint('ℹ️ Direct call only supported on Android');
      return false;
    }

    // Request permission if not already granted
    var status = await Permission.phone.status;

    if (!status.isGranted) {
      debugPrint('📞 Requesting CALL_PHONE permission...');
      status = await Permission.phone.request();
    }

    if (!status.isGranted) {
      debugPrint('⚠️ CALL_PHONE permission denied - will use dialer fallback');
      return false;
    }

    try {
      final sanitizedNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
      debugPrint('📞 Attempting direct call to $sanitizedNumber...');
      final success = await FlutterPhoneDirectCaller.callNumber(sanitizedNumber);
      
      if (success == true) {
        debugPrint('✅ Direct call successfully initiated');
        return true;
      } else {
        debugPrint('⚠️ Direct call returned false, will try dialer');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Direct call exception: $e');
      return false;
    }
  }

  static Future<bool> _launchDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
      return true;
    }

    return false;
  }

  /// Call emergency services (911, 112, 100, etc.)
  static Future<bool> callEmergencyServices({String emergencyNumber = '112'}) async {
    return await makeCall(emergencyNumber);
  }

  /// Call police (India: 100, International: 112)
  static Future<bool> callPolice() async {
    return await callEmergencyServices(emergencyNumber: '100');
  }

  /// Call ambulance (India: 102)
  static Future<bool> callAmbulance() async {
    return await callEmergencyServices(emergencyNumber: '102');
  }

  /// Call women helpline (India: 181)
  static Future<bool> callWomenHelpline() async {
    return await callEmergencyServices(emergencyNumber: '181');
  }
}
