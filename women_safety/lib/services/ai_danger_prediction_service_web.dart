import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Web-safe fallback for AI danger prediction.
class AIDangerPredictionService {
  static const List<String> supportedCities = [
    'Coimbatore',
    'Chennai',
    'Bengaluru',
    'Madurai',
    'Trichy',
    'Salem',
    'Erode',
  ];

  static Future<bool> initialize() async {
    debugPrint('ℹ️ AI danger prediction stub initialized (web-safe mode)');
    return true;
  }

  static Future<Map<String, dynamic>> predictDanger({
    required Position position,
    DateTime? time,
  }) async {
    return {
      'dangerScore': 0.0,
      'level': 'LOW',
      'zoneDetails': <String, dynamic>{
        'inDangerZone': false,
        'zoneName': 'No unsafe zone detected',
        'reason': 'Web-safe fallback is active',
      },
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'timestamp': (time ?? DateTime.now()).toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> getCitySafetyInsights({
    required String city,
    Position? start,
    Position? position,
  }) async {
    final selectedPosition = start ?? position;
    return {
      'city': city,
      'riskLevel': 'LOW',
      'summary': 'Web-safe fallback is active. AI danger data is not available in this build.',
      'riskyAreas': <Map<String, dynamic>>[],
      'policeStations': <Map<String, dynamic>>[],
      'position': selectedPosition == null
          ? null
          : {
              'latitude': selectedPosition.latitude,
              'longitude': selectedPosition.longitude,
            },
    };
  }

  static Future<List<Position>> getSafeRoute({
    required Position start,
    required Position end,
  }) async {
    return [start, end];
  }

  static Future<void> reportIncident({
    required Position position,
    required String incidentType,
    String? description,
  }) async {
    debugPrint('ℹ️ Ignoring reportIncident in web-safe fallback for $incidentType');
  }

  static void clearCache() {
    debugPrint('ℹ️ Web-safe danger cache clear requested');
  }

  static void dispose() {
    debugPrint('ℹ️ Web-safe danger service disposed');
  }
}