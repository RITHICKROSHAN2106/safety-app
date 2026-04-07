import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/guardian.dart';

/// Persists emergency-critical data locally so triggers can work when offline.
class EmergencyCacheService {
  static const String _guardiansKeyPrefix = 'cached_guardians_';
  static const String _emergencyContactsKeyPrefix =
      'cached_emergency_contacts_';
  static const String _cacheUpdatedAtKeyPrefix = 'cached_emergency_updated_at_';

  static Future<void> cacheGuardians({
    required String userId,
    required List<Guardian> guardians,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = guardians.map((g) => g.toJson()).toList();
      await prefs.setString('$_guardiansKeyPrefix$userId', jsonEncode(payload));
      await prefs.setInt(
        '$_cacheUpdatedAtKeyPrefix$userId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('❌ Failed to cache guardians: $e');
    }
  }

  static Future<List<Guardian>> getCachedGuardians(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_guardiansKeyPrefix$userId');
      if (raw == null || raw.isEmpty) {
        return <Guardian>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Guardian>[];
      }

      return decoded
          .whereType<Map>()
          .map((entry) => entry.map((key, value) => MapEntry('$key', value)))
          .map(Guardian.fromJson)
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to read cached guardians: $e');
      return <Guardian>[];
    }
  }

  static Future<void> cacheEmergencyContacts({
    required String userId,
    required List<Map<String, dynamic>> contacts,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_emergencyContactsKeyPrefix$userId',
        jsonEncode(contacts),
      );
      await prefs.setInt(
        '$_cacheUpdatedAtKeyPrefix$userId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('❌ Failed to cache emergency contacts: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCachedEmergencyContacts(
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_emergencyContactsKeyPrefix$userId');
      if (raw == null || raw.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<Map>()
          .map((entry) => entry.map((key, value) => MapEntry('$key', value)))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to read cached emergency contacts: $e');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<DateTime?> getCacheUpdatedAt(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt('$_cacheUpdatedAtKeyPrefix$userId');
      if (millis == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (e) {
      debugPrint('❌ Failed to read cache timestamp: $e');
      return null;
    }
  }
}
