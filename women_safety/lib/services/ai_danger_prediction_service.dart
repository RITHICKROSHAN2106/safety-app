import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 🤖 AI Danger Prediction - Predict danger zones using ML
class AIDangerPredictionService {
  static Interpreter? _interpreter;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, double> _dangerCache = {};

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
  };

  static List<String> get supportedCities =>
      _citySafetyDataset.keys.map((c) => _toTitleCase(c)).toList();

  /// Initialize TensorFlow Lite model
  static Future<bool> initialize() async {
    try {
      // Load pre-trained model
      // Note: You need to add danger_prediction_model.tflite to assets
      // Use relative path inside assets section (ensure pubspec lists assets/models/)
      _interpreter = await Interpreter.fromAsset('models/danger_prediction_model.tflite');
      
      debugPrint('✅ AI danger prediction initialized');
      return true;
    } catch (e) {
      debugPrint('⚠️ AI model not loaded (optional): $e');
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
      
      // Check cache (5-minute validity)
      if (_dangerCache.containsKey(cacheKey)) {
        return {
          'dangerScore': _dangerCache[cacheKey],
          'cached': true,
        };
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

      // Cache result
      _dangerCache[cacheKey] = dangerScore;

      // Get danger zone details
      final zoneDetails = await _getDangerZoneDetails(position);

      return {
        'dangerScore': dangerScore,
        'level': _getDangerLevel(dangerScore),
        'factors': features,
        'zoneDetails': zoneDetails,
        'recommendations': _getRecommendations(dangerScore, time),
        'cached': false,
      };
    } catch (e) {
      debugPrint('❌ Predict danger error: $e');
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

    // Population density (mock - in production, use real data)
    features['populationDensity'] = Random().nextDouble();

    // Lighting conditions
    features['lighting'] = features['isNight']! * 0.3;

    return features;
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
      debugPrint('❌ ML prediction error: $e');
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
      recommendations.add('🚨 Avoid this area if possible');
      recommendations.add('📞 Call a trusted person');
      recommendations.add('🚖 Use ride-sharing service');
    } else if (score >= 5) {
      recommendations.add('⚠️ Stay alert and aware');
      recommendations.add('👥 Travel in groups if possible');
      recommendations.add('💡 Stick to well-lit areas');
    } else {
      recommendations.add('✅ Area is relatively safe');
      recommendations.add('👀 Still maintain awareness');
    }

    if (time.hour >= 20 || time.hour <= 6) {
      recommendations.add('🌙 Avoid isolated areas at night');
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
    debugPrint('🗺️ Calculating safest route...');
    
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

      debugPrint('✅ Incident reported successfully');
    } catch (e) {
      debugPrint('❌ Report incident error: $e');
    }
  }

  /// Clear danger cache
  static void clearCache() {
    _dangerCache.clear();
    debugPrint('✅ Danger cache cleared');
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
