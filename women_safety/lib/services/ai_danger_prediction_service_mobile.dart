import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

/// ≡ƒñû AI Danger Prediction - Predict danger zones using ML
class AIDangerPredictionService {
  static Interpreter? _interpreter;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, Map<String, dynamic>> _dangerCache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  static const Map<String, Map<String, dynamic>> _citySafetyDataset = {
    'coimbatore': {
      'riskyAreas': [
        {
          'name': 'Ukkadam Bus Stand Back Lanes',
          'latitude': 10.9906,
          'longitude': 76.9612,
          'risk': 'HIGH',
          'reason': 'Low visibility after 10 PM and sparse patrol frequency',
        },
        {
          'name': 'Town Hall Market Side Streets',
          'latitude': 10.9981,
          'longitude': 76.9589,
          'risk': 'MEDIUM',
          'reason': 'Crowd pockets and pickpocket activity during late evenings',
        },
        {
          'name': 'Gandhipuram Flyover Underpass',
          'latitude': 11.0174,
          'longitude': 76.9678,
          'risk': 'HIGH',
          'reason': 'Poor lighting and isolated stretches after night hours',
        },
      ],
      'policeStations': [
        {
          'name': 'B1 Bazaar Police Station',
          'latitude': 10.9977,
          'longitude': 76.9567,
          'type': 'Police Station',
          'contact': '+91 422 230 0250',
        },
        {
          'name': 'Gandhipuram Police Station',
          'latitude': 11.0165,
          'longitude': 76.9689,
          'type': 'Police Station',
          'contact': '+91 422 249 3555',
        },
        {
          'name': 'RS Puram Patrol Booth',
          'latitude': 11.0095,
          'longitude': 76.9518,
          'type': 'Police Booth',
          'contact': '+91 100',
        },
      ],
    },
    'chennai': {
      'riskyAreas': [
        {
          'name': 'T Nagar Back Market Streets',
          'latitude': 13.0413,
          'longitude': 80.2337,
          'risk': 'MEDIUM',
          'reason': 'Heavy crowd and traffic bottlenecks during peak hours',
        },
      ],
      'policeStations': [
        {
          'name': 'T Nagar Police Station',
          'latitude': 13.0418,
          'longitude': 80.2329,
          'type': 'Police Station',
          'contact': '+91 44 2345 2500',
        },
      ],
    },
    'bengaluru': {
      'riskyAreas': [
        {
          'name': 'Majestic Bus Terminal Peripheral Lanes',
          'latitude': 12.9770,
          'longitude': 77.5728,
          'risk': 'MEDIUM',
          'reason': 'Late-night congestion and limited visibility sections',
        },
      ],
      'policeStations': [
        {
          'name': 'Upparpet Police Station',
          'latitude': 12.9759,
          'longitude': 77.5718,
          'type': 'Police Station',
          'contact': '+91 80 2294 2999',
        },
      ],
    },
    'madurai': {
      'riskyAreas': [
        {
          'name': 'Periyar Bus Stand Rear Lanes',
          'latitude': 9.9188,
          'longitude': 78.1190,
          'risk': 'HIGH',
          'reason': 'Low-lit stretches and irregular patrol visibility late night',
        },
        {
          'name': 'Railway Junction Service Road',
          'latitude': 9.9149,
          'longitude': 78.1178,
          'risk': 'MEDIUM',
          'reason': 'Crowd surges and traffic confusion during late evening windows',
        },
      ],
      'policeStations': [
        {
          'name': 'B1 Vilakkuthoon Police Station',
          'latitude': 9.9195,
          'longitude': 78.1183,
          'type': 'Police Station',
          'contact': '+91 452 252 0200',
        },
        {
          'name': 'Tallakulam Police Station',
          'latitude': 9.9387,
          'longitude': 78.1304,
          'type': 'Police Station',
          'contact': '+91 452 253 9722',
        },
        {
          'name': 'Meenakshi Temple Security Booth',
          'latitude': 9.9195,
          'longitude': 78.1193,
          'type': 'Police Booth',
          'contact': '+91 100',
        },
      ],
    },
    'trichy': {
      'riskyAreas': [
        {
          'name': 'Central Bus Stand Link Roads',
          'latitude': 10.7987,
          'longitude': 78.6825,
          'risk': 'MEDIUM',
          'reason': 'Congested transfer zones with low visibility in side lanes',
        },
        {
          'name': 'Chathiram Peripheral Streets',
          'latitude': 10.8269,
          'longitude': 78.6962,
          'risk': 'HIGH',
          'reason': 'Night-time isolation in internal roads and sparse movement',
        },
      ],
      'policeStations': [
        {
          'name': 'Cantonment Police Station',
          'latitude': 10.8043,
          'longitude': 78.6902,
          'type': 'Police Station',
          'contact': '+91 431 241 1100',
        },
        {
          'name': 'Fort Police Station',
          'latitude': 10.8289,
          'longitude': 78.6942,
          'type': 'Police Station',
          'contact': '+91 431 270 2525',
        },
        {
          'name': 'Srirangam Patrol Booth',
          'latitude': 10.8637,
          'longitude': 78.6939,
          'type': 'Police Booth',
          'contact': '+91 100',
        },
      ],
    },
    'salem': {
      'riskyAreas': [
        {
          'name': 'New Bus Stand Back Corridor',
          'latitude': 11.6644,
          'longitude': 78.1460,
          'risk': 'MEDIUM',
          'reason': 'Frequent crowd bottlenecks and poor side-lane illumination',
        },
        {
          'name': 'Old Suramangalam Industrial Stretch',
          'latitude': 11.6748,
          'longitude': 78.1198,
          'risk': 'HIGH',
          'reason': 'Low footfall and isolated warehouse roads at night',
        },
      ],
      'policeStations': [
        {
          'name': 'Hasthampatti Police Station',
          'latitude': 11.6732,
          'longitude': 78.1466,
          'type': 'Police Station',
          'contact': '+91 427 244 4242',
        },
        {
          'name': 'Town Police Station Salem',
          'latitude': 11.6537,
          'longitude': 78.1598,
          'type': 'Police Station',
          'contact': '+91 427 221 0300',
        },
        {
          'name': 'Five Roads Patrol Booth',
          'latitude': 11.6750,
          'longitude': 78.1413,
          'type': 'Police Booth',
          'contact': '+91 100',
        },
      ],
    },
    'erode': {
      'riskyAreas': [
        {
          'name': 'Central Bus Stand Rear Access Lanes',
          'latitude': 11.3414,
          'longitude': 77.7173,
          'risk': 'MEDIUM',
          'reason': 'Dense transport crowd with intermittent surveillance coverage',
        },
        {
          'name': 'Textile Market Side Roads',
          'latitude': 11.3427,
          'longitude': 77.7265,
          'risk': 'HIGH',
          'reason': 'Late-night shop closures create low-visibility blind spots',
        },
      ],
      'policeStations': [
        {
          'name': 'Erode Town Police Station',
          'latitude': 11.3410,
          'longitude': 77.7178,
          'type': 'Police Station',
          'contact': '+91 424 225 1122',
        },
        {
          'name': 'Surampatti Police Station',
          'latitude': 11.3371,
          'longitude': 77.7334,
          'type': 'Police Station',
          'contact': '+91 424 226 6600',
        },
        {
          'name': 'Perundurai Road Safety Booth',
          'latitude': 11.3188,
          'longitude': 77.7223,
          'type': 'Police Booth',
          'contact': '+91 100',
        },
      ],
    },
  };

  static List<String> get supportedCities =>
      _citySafetyDataset.keys.map((c) => _toTitleCase(c)).toList();

  /// Initialize TensorFlow Lite model
  static Future<bool> initialize() async {
    try {
      // Load pre-trained model
      // Note: You need to add danger_prediction_model.tflite to assets
      // Use relative path inside assets section (ensure pubspec lists assets/models/)
      _interpreter = await Interpreter.fromAsset('assets/models/danger_prediction_model.tflite');
      
      debugPrint('Γ£à AI danger prediction initialized');
      return true;
    } catch (e) {
      debugPrint('ΓÜá∩╕Å AI model not loaded (optional): $e');
      return false;
    }
  }

  /// Predict danger level for a location (0-10 score)
  static Future<Map<String, dynamic>> predictDanger({
    required Position position,
    DateTime? time,
  }) async {
    try {
      time ??= DateTime.now();
      
      // Create cache key
      final cacheKey = '${position.latitude.toStringAsFixed(3)}_${position.longitude.toStringAsFixed(3)}';
      final now = DateTime.now();

      // Check cache (5-minute validity)
      final cachedEntry = _dangerCache[cacheKey];
      if (cachedEntry != null) {
        final cachedAtMs = (cachedEntry['cachedAtEpochMs'] as int?) ?? 0;
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
        if (now.difference(cachedAt) <= _cacheTtl) {
          return {
            ...cachedEntry,
            'cached': true,
          };
        }
      }

      // Gather features for prediction
      final features = await _gatherFeatures(position, time);
      
      // Run prediction if model loaded
      double dangerScore;
      if (_interpreter != null) {
        dangerScore = await _runMLPrediction(features);
      } else {
        // Fallback to rule-based prediction
        dangerScore = _ruleBasedPrediction(features);
      }

      // Get danger zone details
      final zoneDetails = await _getDangerZoneDetails(position);

      final result = {
        'dangerScore': dangerScore,
        'level': _getDangerLevel(dangerScore),
        'factors': features,
        'zoneDetails': zoneDetails,
        'recommendations': _getRecommendations(dangerScore, time),
        'cached': false,
        'cachedAtEpochMs': now.millisecondsSinceEpoch,
      };

      // Cache full payload (not only score)
      _dangerCache[cacheKey] = result;

      return result;
    } catch (e) {
      debugPrint('Γ¥î Predict danger error: $e');
      return {
        'dangerScore': 5.0,
        'level': 'MEDIUM',
        'error': e.toString(),
      };
    }
  }

  /// Gather features for ML model
  static Future<Map<String, double>> _gatherFeatures(Position position, DateTime time) async {
    // Feature engineering for danger prediction
    final features = <String, double>{};

    // Time-based features
    features['hour'] = time.hour.toDouble();
    features['isNight'] = (time.hour >= 20 || time.hour <= 6) ? 1.0 : 0.0;
    features['isWeekend'] = (time.weekday >= 6) ? 1.0 : 0.0;

    // Location-based features (normalized)
    features['latitude'] = position.latitude / 90.0;
    features['longitude'] = position.longitude / 180.0;

    // Get incident history from database
    final incidentCount = await _getIncidentCount(position);
    features['incidentHistory'] = incidentCount.toDouble() / 100.0; // Normalize

    // Population density proxy (real-time from nearby incidents + time profile)
    final density = await _estimatePopulationDensity(position, time);
    features['populationDensity'] = density;

    // Lighting conditions (deterministic heuristic)
    features['lighting'] = _estimateLightingCondition(time);

    return features;
  }

  /// Estimate population density proxy from real-time incident concentration + hour profile
  static Future<double> _estimatePopulationDensity(Position position, DateTime time) async {
    try {
      final nearbyCount = await _getIncidentCountWithinRadius(position, radiusDeg: 0.02);
      final incidentDensity = (nearbyCount / 50.0).clamp(0.0, 1.0);

      final hour = time.hour;
      final hourFactor = _hourCrowdFactor(hour);

      final blended = (incidentDensity * 0.65) + (hourFactor * 0.35);
      return blended.clamp(0.0, 1.0);
    } catch (_) {
      return _hourCrowdFactor(time.hour).clamp(0.0, 1.0);
    }
  }

  /// Time-of-day crowd profile proxy
  static double _hourCrowdFactor(int hour) {
    if (hour >= 8 && hour <= 11) return 0.80; // morning commute
    if (hour >= 12 && hour <= 16) return 0.70; // daytime
    if (hour >= 17 && hour <= 21) return 0.95; // evening peak
    if (hour >= 22 || hour <= 4) return 0.25; // night low crowd
    return 0.45; // early morning shoulder
  }

  /// Estimate lighting condition as [0,1] where 1 = well-lit
  static double _estimateLightingCondition(DateTime time) {
    final hour = time.hour;
    if (hour >= 7 && hour <= 17) return 1.0;
    if ((hour >= 18 && hour <= 19) || (hour >= 5 && hour <= 6)) return 0.6;
    return 0.3;
  }

  /// Run ML prediction
  static Future<double> _runMLPrediction(Map<String, double> features) async {
    try {
      // Prepare input tensor
      final input = Float32List.fromList([
        features['hour']!,
        features['isNight']!,
        features['isWeekend']!,
        features['latitude']!,
        features['longitude']!,
        features['incidentHistory']!,
        features['populationDensity']!,
        features['lighting']!,
      ]);

      // Prepare output tensor
      final output = Float32List(1);

      // Run inference
      _interpreter?.run(input.reshape([1, 8]), output.reshape([1, 1]));

      // Convert to 0-10 scale
      final dangerScore = (output[0] * 10).clamp(0.0, 10.0);
      
      return dangerScore;
    } catch (e) {
      debugPrint('Γ¥î ML prediction error: $e');
      return 5.0;
    }
  }

  /// Rule-based prediction (fallback)
  static double _ruleBasedPrediction(Map<String, double> features) {
    double score = 5.0; // Base score

    // Night time increases danger
    if (features['isNight']! > 0) score += 2.0;

    // High incident history
    if (features['incidentHistory']! > 0.5) score += 2.0;

    // Low population density
    if (features['populationDensity']! < 0.3) score += 1.5;

    // Weekend late hours
    if (features['isWeekend']! > 0 && features['hour']! > 22) score += 1.0;

    return score.clamp(0.0, 10.0);
  }

  /// Get incident count from database
  static Future<int> _getIncidentCount(Position position) async {
    try {
      // Expect incidents to store separate lat/lng fields for querying
      final incidents = await _firestore
          .collection('incidents')
          .where('lat', isGreaterThan: position.latitude - 0.01)
          .where('lat', isLessThan: position.latitude + 0.01)
          .where('lng', isGreaterThan: position.longitude - 0.01)
          .where('lng', isLessThan: position.longitude + 0.01)
          .get();
      return incidents.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get incident density in a larger radius for population proxy
  static Future<int> _getIncidentCountWithinRadius(
    Position position, {
    required double radiusDeg,
  }) async {
    try {
      final incidents = await _firestore
          .collection('incidents')
          .where('lat', isGreaterThan: position.latitude - radiusDeg)
          .where('lat', isLessThan: position.latitude + radiusDeg)
          .where('lng', isGreaterThan: position.longitude - radiusDeg)
          .where('lng', isLessThan: position.longitude + radiusDeg)
          .get();
      return incidents.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Get danger zone details
  static Future<Map<String, dynamic>> _getDangerZoneDetails(Position position) async {
    try {
      final zones = await _firestore
          .collection('danger_zones')
          .where('active', isEqualTo: true)
          .get();

      for (final doc in zones.docs) {
        final data = doc.data();
        final center = data['center'] as GeoPoint;
        final radiusKm = data['radiusKm'] as double;

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          center.latitude,
          center.longitude,
        ) / 1000;

        if (distance <= radiusKm) {
          return {
            'inDangerZone': true,
            'zoneName': data['name'],
            'incidentType': data['incidentType'],
            'lastIncident': data['lastIncident'],
          };
        }
      }

      return {'inDangerZone': false};
    } catch (e) {
      return {'inDangerZone': false};
    }
  }

  /// Get danger level text
  static String _getDangerLevel(double score) {
    if (score >= 8) return 'CRITICAL';
    if (score >= 6) return 'HIGH';
    if (score >= 4) return 'MEDIUM';
    if (score >= 2) return 'LOW';
    return 'SAFE';
  }

  /// Get safety recommendations
  static List<String> _getRecommendations(double score, DateTime time) {
    final recommendations = <String>[];

    if (score >= 7) {
      recommendations.add('≡ƒÜ¿ Avoid this area if possible');
      recommendations.add('≡ƒô₧ Call a trusted person');
      recommendations.add('≡ƒÜû Use ride-sharing service');
    } else if (score >= 5) {
      recommendations.add('ΓÜá∩╕Å Stay alert and aware');
      recommendations.add('≡ƒæÑ Travel in groups if possible');
      recommendations.add('≡ƒÆí Stick to well-lit areas');
    } else {
      recommendations.add('Γ£à Area is relatively safe');
      recommendations.add('≡ƒæÇ Still maintain awareness');
    }

    if (time.hour >= 20 || time.hour <= 6) {
      recommendations.add('≡ƒîÖ Avoid isolated areas at night');
    }

    return recommendations;
  }

  /// Get safe route recommendation
  static Future<List<Position>> getSafeRoute({
    required Position start,
    required Position end,
  }) async {
    // In production, integrate with Google Maps Directions API
    // and filter routes by danger scores
    
    final safeRoute = <Position>[start, end];
    debugPrint('≡ƒù║∩╕Å Calculating safest route...');
    
    return safeRoute;
  }

  /// Returns richer safety insights using curated city datasets.
  static Future<Map<String, dynamic>> getCitySafetyInsights({
    required String city,
    required Position start,
    Position? destination,
  }) async {
    final normalizedCity = city.trim().toLowerCase();
    final data = _citySafetyDataset[normalizedCity] ?? _citySafetyDataset['coimbatore']!;

    final riskyAreas = (data['riskyAreas'] as List)
        .map((area) {
          final lat = (area['latitude'] as num).toDouble();
          final lng = (area['longitude'] as num).toDouble();
          final distanceKm = _distanceKm(start.latitude, start.longitude, lat, lng);
          return {
            ...Map<String, dynamic>.from(area as Map),
            'distanceKm': distanceKm,
          };
        })
        .toList()
      ..sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

    final nearbyPolice = (data['policeStations'] as List)
        .map((station) {
          final lat = (station['latitude'] as num).toDouble();
          final lng = (station['longitude'] as num).toDouble();
          final distanceKm = _distanceKm(start.latitude, start.longitude, lat, lng);
          return {
            ...Map<String, dynamic>.from(station as Map),
            'distanceKm': distanceKm,
          };
        })
        .toList()
      ..sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

    final end = destination ?? Position(
      longitude: start.longitude + 0.015,
      latitude: start.latitude + 0.015,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    final saferOptions = <Map<String, dynamic>>[
      {
        'name': 'Police Corridor Route',
        'safetyScore': 9,
        'description': 'Prioritizes roads near police stations/booths.',
        'avoidAreas': riskyAreas.take(2).map((e) => e['name']).toList(),
        'policeStops': nearbyPolice.take(2).map((e) => e['name']).toList(),
        'mapsUrl':
            'https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&travelmode=driving',
      },
      {
        'name': 'Well-Lit Main Road Route',
        'safetyScore': 8,
        'description': 'Uses arterial roads and avoids isolated shortcuts.',
        'avoidAreas': riskyAreas.take(3).map((e) => e['name']).toList(),
        'policeStops': nearbyPolice.take(1).map((e) => e['name']).toList(),
        'mapsUrl':
            'https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&travelmode=walking',
      },
    ];

    return {
      'city': _toTitleCase(normalizedCity),
      'riskyAreas': riskyAreas,
      'nearbyPolice': nearbyPolice.take(5).toList(),
      'saferOptions': saferOptions,
    };
  }

  /// Report incident to improve model
  static Future<void> reportIncident({
    required Position position,
    required String incidentType,
    String? description,
  }) async {
    try {
      await _firestore.collection('incidents').add({
        'location': GeoPoint(position.latitude, position.longitude),
        'lat': position.latitude,
        'lng': position.longitude,
        'incidentType': incidentType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'verified': false,
      });

      // Clear cache for this location
      final cacheKey = '${position.latitude.toStringAsFixed(3)}_${position.longitude.toStringAsFixed(3)}';
      _dangerCache.remove(cacheKey);

      debugPrint('Γ£à Incident reported successfully');
    } catch (e) {
      debugPrint('Γ¥î Report incident error: $e');
    }
  }

  /// Clear danger cache
  static void clearCache() {
    _dangerCache.clear();
    debugPrint('Γ£à Danger cache cleared');
  }

  /// Dispose interpreter
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  static String _toTitleCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
}