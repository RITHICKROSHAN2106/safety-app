import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:typed_data';

/// 🤖 AI Danger Prediction - Predict danger zones using ML
class AIDangerPredictionService {
  static Interpreter? _interpreter;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, Map<String, dynamic>> _dangerCache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);
  static final Map<String, Map<String, dynamic>> _townSafetyDataset = {};
  static final Map<String, Map<String, double>> _townCenters = {};
  static DateTime? _townDatasetLoadedAt;
  static const Duration _townDatasetCacheTtl = Duration(hours: 6);
  static const String _townDatasetCollection = 'tn_town_safety_datasets';

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
    'tiruppur': {
      'riskyAreas': [
        {
          'name': 'Old Bus Stand Rear Road Stretch',
          'latitude': 11.1025,
          'longitude': 77.3461,
          'risk': 'MEDIUM',
          'reason': 'Intermittent surveillance and low lighting in side roads after late evenings',
        },
        {
          'name': 'Industrial Estate Link Roads',
          'latitude': 11.0898,
          'longitude': 77.3254,
          'risk': 'HIGH',
          'reason': 'Sparse pedestrian movement and isolated sections after shift hours',
        },
      ],
      'policeStations': [
        {
          'name': 'Tiruppur North Police Station',
          'latitude': 11.1084,
          'longitude': 77.3415,
          'type': 'Police Station',
          'contact': '+91 421 220 0145',
        },
        {
          'name': 'Tiruppur South Police Station',
          'latitude': 11.0907,
          'longitude': 77.3498,
          'type': 'Police Station',
          'contact': '+91 421 223 1100',
        },
        {
          'name': 'Avinashi Road Patrol Booth',
          'latitude': 11.1115,
          'longitude': 77.3436,
          'type': 'Police Booth',
          'contact': '+91 100',
        },
      ],
    },
    'vellore': {
      'riskyAreas': [
        {
          'name': 'Old Town Junction Side Streets',
          'latitude': 12.9228,
          'longitude': 79.1315,
          'risk': 'MEDIUM',
          'reason': 'Congested traffic with blind corners and inconsistent street lighting',
        },
        {
          'name': 'Katpadi Station Rear Access Roads',
          'latitude': 12.9697,
          'longitude': 79.1457,
          'risk': 'HIGH',
          'reason': 'Low-visibility access routes and sparse patrol presence at late hours',
        },
      ],
      'policeStations': [
        {
          'name': 'Vellore North Police Station',
          'latitude': 12.9286,
          'longitude': 79.1336,
          'type': 'Police Station',
          'contact': '+91 416 222 1100',
        },
        {
          'name': 'Katpadi Police Station',
          'latitude': 12.9691,
          'longitude': 79.1451,
          'type': 'Police Station',
          'contact': '+91 416 224 2233',
        },
        {
          'name': 'CMC Zone Safety Booth',
          'latitude': 12.9247,
          'longitude': 79.1372,
          'type': 'Police Booth',
          'contact': '+91 100',
        },
      ],
    },
    'tirunelveli': {
      'riskyAreas': [
        {
          'name': 'Junction Bus Stand Peripheral Roads',
          'latitude': 8.7287,
          'longitude': 77.7081,
          'risk': 'MEDIUM',
          'reason': 'Crowded transit points with low-visibility connector lanes',
        },
        {
          'name': 'Riverbank Service Road Segments',
          'latitude': 8.7213,
          'longitude': 77.7428,
          'risk': 'HIGH',
          'reason': 'Isolated stretches and reduced movement in late-night windows',
        },
      ],
      'policeStations': [
        {
          'name': 'Tirunelveli Town Police Station',
          'latitude': 8.7271,
          'longitude': 77.7045,
          'type': 'Police Station',
          'contact': '+91 462 233 1100',
        },
        {
          'name': 'Palayamkottai Police Station',
          'latitude': 8.7323,
          'longitude': 77.7461,
          'type': 'Police Station',
          'contact': '+91 462 257 8899',
        },
        {
          'name': 'Nellai Junction Safety Booth',
          'latitude': 8.7283,
          'longitude': 77.7097,
          'type': 'Police Booth',
          'contact': '+91 100',
        },
      ],
    },
  };

  static const Map<String, Map<String, double>> _cityCenters = {
    'coimbatore': {'latitude': 11.0168, 'longitude': 76.9558},
    'chennai': {'latitude': 13.0827, 'longitude': 80.2707},
    'bengaluru': {'latitude': 12.9716, 'longitude': 77.5946},
    'madurai': {'latitude': 9.9252, 'longitude': 78.1198},
    'trichy': {'latitude': 10.7905, 'longitude': 78.7047},
    'salem': {'latitude': 11.6643, 'longitude': 78.1460},
    'erode': {'latitude': 11.3410, 'longitude': 77.7172},
    'tiruppur': {'latitude': 11.1085, 'longitude': 77.3411},
    'vellore': {'latitude': 12.9165, 'longitude': 79.1325},
    'tirunelveli': {'latitude': 8.7139, 'longitude': 77.7567},
  };

  static const List<Map<String, String>> _defaultGovernmentSources = [
    {
      'name': 'National Crime Records Bureau (NCRB)',
      'url': 'https://ncrb.gov.in',
      'dataset': 'Crime in India (annual district/city statistics)',
      'integrationMode': 'curated_snapshot',
    },
    {
      'name': 'Open Government Data (India)',
      'url': 'https://data.gov.in',
      'dataset': 'Public safety, police, and civic datasets',
      'integrationMode': 'curated_snapshot',
    },
    {
      'name': 'Bureau of Police Research & Development (BPR&D)',
      'url': 'https://bprd.nic.in',
      'dataset': 'Police modernization and crime prevention resources',
      'integrationMode': 'curated_snapshot',
    },
    {
      'name': 'Emergency Response Support System (ERSS-112)',
      'url': 'https://112.gov.in',
      'dataset': 'Emergency response infrastructure and support coverage',
      'integrationMode': 'curated_snapshot',
    },
    {
      'name': 'Ministry of Home Affairs (India)',
      'url': 'https://www.mha.gov.in',
      'dataset': 'National-level safety advisories and policing policy updates',
      'integrationMode': 'curated_snapshot',
    },
  ];

  static const Map<String, List<Map<String, String>>> _cityGovernmentSources = {
    'coimbatore': [
      {
        'name': 'Tamil Nadu Police',
        'url': 'https://eservices.tnpolice.gov.in',
        'dataset': 'Police station and jurisdiction information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'chennai': [
      {
        'name': 'Greater Chennai Police',
        'url': 'https://chennaipolice.gov.in',
        'dataset': 'Police station and emergency contact information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'bengaluru': [
      {
        'name': 'Bengaluru City Police',
        'url': 'https://bcp.karnataka.gov.in',
        'dataset': 'Police station and emergency contact information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'madurai': [
      {
        'name': 'Tamil Nadu Police',
        'url': 'https://eservices.tnpolice.gov.in',
        'dataset': 'Police station and jurisdiction information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'trichy': [
      {
        'name': 'Tamil Nadu Police',
        'url': 'https://eservices.tnpolice.gov.in',
        'dataset': 'Police station and jurisdiction information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'salem': [
      {
        'name': 'Tamil Nadu Police',
        'url': 'https://eservices.tnpolice.gov.in',
        'dataset': 'Police station and jurisdiction information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'erode': [
      {
        'name': 'Tamil Nadu Police',
        'url': 'https://eservices.tnpolice.gov.in',
        'dataset': 'Police station and jurisdiction information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'tiruppur': [
      {
        'name': 'Tamil Nadu Police',
        'url': 'https://eservices.tnpolice.gov.in',
        'dataset': 'Police station and jurisdiction information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'vellore': [
      {
        'name': 'Tamil Nadu Police',
        'url': 'https://eservices.tnpolice.gov.in',
        'dataset': 'Police station and jurisdiction information',
        'integrationMode': 'curated_snapshot',
      },
    ],
    'tirunelveli': [
      {
        'name': 'Tamil Nadu Police',
        'url': 'https://eservices.tnpolice.gov.in',
        'dataset': 'Police station and jurisdiction information',
        'integrationMode': 'curated_snapshot',
      },
    ],
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
      
      debugPrint('✅ AI danger prediction initialized');
      await _ensureTownDatasetsLoaded();
      return true;
    } catch (e) {
      debugPrint('⚠️ AI model not loaded (optional): $e');
      await _ensureTownDatasetsLoaded();
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

      // Get danger zone details from dynamic DB zones and curated city hotspots.
      final dbZoneDetails = await _getDangerZoneDetails(position);
      final curatedHotspotDetails = await _getCuratedDangerHotspot(position);

      // Curated hotspot risk should raise score when user is near known dangerous pockets.
      dangerScore = _applyCuratedRiskBoost(dangerScore, curatedHotspotDetails);
      final zoneDetails = _mergeZoneDetails(dbZoneDetails, curatedHotspotDetails);

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
    String? city,
  }) async {
    final recommendation = await getRecommendedSafeRoute(
      start: start,
      end: end,
      city: city,
    );

    return List<Position>.from(recommendation['bestRoute'] as List);
  }

  /// Rank route candidates using danger prediction.
  static Future<Map<String, dynamic>> getRecommendedSafeRoute({
    required Position start,
    required Position end,
    String? city,
    DateTime? time,
  }) async {
    time ??= DateTime.now();
    await _ensureTownDatasetsLoaded();

    final datasets = _allSafetyDatasets();

    final normalizedCity = (city == null || city.trim().isEmpty)
        ? await _resolveNearestCityName(start)
        : city.trim().toLowerCase();
    final cityData = datasets[normalizedCity] ?? datasets['coimbatore'];
    final datasetSources = _extractGovernmentSourcesFromDataset(cityData);
    final governmentSources = _getGovernmentSources(
      normalizedCity,
      datasetSpecificSources: datasetSources,
    );

    final nearbyPolice = cityData == null
        ? <Map<String, dynamic>>[]
        : (cityData['policeStations'] as List)
            .map((station) {
              final lat = (station['latitude'] as num).toDouble();
              final lng = (station['longitude'] as num).toDouble();
              final distanceKm = _distanceKm(start.latitude, start.longitude, lat, lng);
              return {
                ...Map<String, dynamic>.from(station as Map),
                'distanceKm': distanceKm,
                'sourceType': 'government_dataset',
                'sourceName': governmentSources.first['name'],
                'sourceUrl': governmentSources.first['url'],
              };
            })
            .toList()
          ..sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

    final riskyAreas = cityData == null
        ? <Map<String, dynamic>>[]
        : (cityData['riskyAreas'] as List)
            .map((area) {
              final lat = (area['latitude'] as num).toDouble();
              final lng = (area['longitude'] as num).toDouble();
              final distanceKm = _distanceKm(start.latitude, start.longitude, lat, lng);
              return {
                ...Map<String, dynamic>.from(area as Map),
                'distanceKm': distanceKm,
                'sourceType': 'government_dataset',
                'sourceName': governmentSources.first['name'],
                'sourceUrl': governmentSources.first['url'],
              };
            })
            .toList()
          ..sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

    final candidates = <Map<String, dynamic>>[
      {
        'name': 'Direct Route',
        'description': 'Shortest path, used as a baseline for comparison.',
        'points': <Position>[start, end],
        'mapsUrl': 'https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&travelmode=walking',
      },
    ];

    if (nearbyPolice.isNotEmpty) {
      final station = nearbyPolice.first;
      final stationPosition = Position(
        latitude: (station['latitude'] as num).toDouble(),
        longitude: (station['longitude'] as num).toDouble(),
        timestamp: time,
        accuracy: 5,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      candidates.add({
        'name': 'Police Corridor Route',
        'description': 'Passes close to the nearest police station or booth.',
        'points': <Position>[start, stationPosition, end],
        'mapsUrl': 'https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&travelmode=driving',
      });
    }

    final avoidanceWaypoint = _buildAvoidanceWaypoint(start: start, end: end, riskyAreas: riskyAreas);
    if (avoidanceWaypoint != null) {
      candidates.add({
        'name': 'Well-Lit Avoidance Route',
        'description': 'Shifts the route midpoint away from nearby risky areas.',
        'points': <Position>[start, avoidanceWaypoint, end],
        'mapsUrl': 'https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&travelmode=walking',
      });
    }

    final scoredCandidates = <Map<String, dynamic>>[];
    for (final candidate in candidates) {
      final points = List<Position>.from(candidate['points'] as List);
      final dangerScore = await _scoreRoute(points, time);
      final distanceKm = _routeDistanceKm(points);
      final safetyScore = (10.0 - dangerScore).clamp(0.0, 10.0);

      scoredCandidates.add({
        ...candidate,
        'dangerScore': dangerScore,
        'safetyScore': safetyScore,
        'distanceKm': distanceKm,
      });
    }

    scoredCandidates.sort((a, b) {
      final dangerComparison = (a['dangerScore'] as double).compareTo(b['dangerScore'] as double);
      if (dangerComparison != 0) return dangerComparison;
      return (a['distanceKm'] as double).compareTo(b['distanceKm'] as double);
    });

    final bestCandidate = scoredCandidates.first;

    return {
      'bestRouteName': bestCandidate['name'],
      'bestRouteDescription': bestCandidate['description'],
      'bestRoute': List<Position>.from(bestCandidate['points'] as List),
      'bestRouteDangerScore': bestCandidate['dangerScore'],
      'bestRouteSafetyScore': bestCandidate['safetyScore'],
      'bestRouteDistanceKm': bestCandidate['distanceKm'],
      'alternatives': scoredCandidates
          .map((candidate) => {
                'name': candidate['name'],
                'description': candidate['description'],
                'mapsUrl': candidate['mapsUrl'],
                'dangerScore': candidate['dangerScore'],
                'safetyScore': candidate['safetyScore'],
                'distanceKm': candidate['distanceKm'],
              })
          .toList(),
      'governmentSources': governmentSources,
    };
  }

  /// Returns richer safety insights using curated city datasets and
  /// ML-ranked route recommendations.
  static Future<Map<String, dynamic>> getCitySafetyInsights({
    String? city,
    required Position start,
    Position? destination,
  }) async {
    await _ensureTownDatasetsLoaded();
    final datasets = _allSafetyDatasets();

    final normalizedCity = (city == null || city.trim().isEmpty)
        ? await _resolveNearestCityName(start)
        : city.trim().toLowerCase();
    final data = datasets[normalizedCity] ?? datasets['coimbatore']!;
    final datasetSources = _extractGovernmentSourcesFromDataset(data);
    final governmentSources = _getGovernmentSources(
      normalizedCity,
      datasetSpecificSources: datasetSources,
    );

    final riskyAreas = (data['riskyAreas'] as List)
        .map((area) {
          final lat = (area['latitude'] as num).toDouble();
          final lng = (area['longitude'] as num).toDouble();
          final distanceKm = _distanceKm(start.latitude, start.longitude, lat, lng);
          return {
            ...Map<String, dynamic>.from(area as Map),
            'distanceKm': distanceKm,
            'sourceType': 'government_dataset',
            'sourceName': governmentSources.first['name'],
            'sourceUrl': governmentSources.first['url'],
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
            'sourceType': 'government_dataset',
            'sourceName': governmentSources.first['name'],
            'sourceUrl': governmentSources.first['url'],
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

    final routeRecommendation = await getRecommendedSafeRoute(
      start: start,
      end: end,
      city: normalizedCity,
    );

    final saferOptions = (routeRecommendation['alternatives'] as List<dynamic>)
        .map((candidate) {
          final safetyScore = (candidate['safetyScore'] as num).toDouble();
          return {
            'name': candidate['name'],
            'safetyScore': safetyScore.round(),
            'description': candidate['description'],
            'avoidAreas': riskyAreas.take(3).map((e) => e['name']).toList(),
            'policeStops': nearbyPolice.take(2).map((e) => e['name']).toList(),
            'mapsUrl': candidate['mapsUrl'],
            'routeDangerScore': candidate['dangerScore'],
            'routeDistanceKm': candidate['distanceKm'],
          };
        })
        .toList();

    return {
      'city': _toTitleCase(normalizedCity),
      'riskyAreas': riskyAreas,
      'nearbyPolice': nearbyPolice.take(5).toList(),
      'saferOptions': saferOptions,
      'routeRecommendation': {
        'name': routeRecommendation['bestRouteName'],
        'description': routeRecommendation['bestRouteDescription'],
        'dangerScore': routeRecommendation['bestRouteDangerScore'],
        'safetyScore': routeRecommendation['bestRouteSafetyScore'],
        'distanceKm': routeRecommendation['bestRouteDistanceKm'],
      },
      'dataProvenance': {
        'providerType': 'government',
        'integrationMode': 'curated_snapshot',
        'sources': governmentSources,
        'lastReviewedOn': '2026-04-04',
      },
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

  static List<Map<String, dynamic>> _extractGovernmentSourcesFromDataset(
    Map<String, dynamic>? dataset,
  ) {
    final sources = dataset?['governmentSources'];
    if (sources is! List) {
      return const <Map<String, dynamic>>[];
    }

    return sources
        .whereType<Map>()
        .map((source) => source.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);
  }

  static List<Map<String, String>> _getGovernmentSources(
    String normalizedCity, {
    List<Map<String, dynamic>>? datasetSpecificSources,
  }) {
    final citySources = _cityGovernmentSources[normalizedCity] ?? const <Map<String, String>>[];
    final datasetSources = (datasetSpecificSources ?? const <Map<String, dynamic>>[])
        .map((source) => {
              'name': (source['name'] ?? 'Government Source').toString(),
              'url': (source['url'] ?? '').toString(),
              'dataset': (source['dataset'] ?? 'Safety dataset').toString(),
              'integrationMode': (source['integrationMode'] ?? 'curated_snapshot').toString(),
            })
        .toList(growable: false);

    return <Map<String, String>>[
      ..._defaultGovernmentSources,
      ...citySources,
      ...datasetSources,
    ];
  }

  static Future<void> _ensureTownDatasetsLoaded({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _townDatasetLoadedAt != null &&
        DateTime.now().difference(_townDatasetLoadedAt!) <= _townDatasetCacheTtl) {
      return;
    }

    try {
      final snapshot = await _firestore.collection(_townDatasetCollection).get();
      final loadedTownDataset = <String, Map<String, dynamic>>{};
      final loadedTownCenters = <String, Map<String, double>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final normalizedTown = (data['town'] ?? data['city'] ?? doc.id).toString().trim().toLowerCase();
        if (normalizedTown.isEmpty) {
          continue;
        }

        final riskyAreas = _normalizeAreaList(data['riskyAreas']);
        final policeStations = _normalizeAreaList(data['policeStations']);
        final governmentSources = _normalizeAreaList(data['governmentSources']);

        loadedTownDataset[normalizedTown] = {
          'riskyAreas': riskyAreas,
          'policeStations': policeStations,
          'governmentSources': governmentSources,
        };

        final center = data['center'];
        if (center is GeoPoint) {
          loadedTownCenters[normalizedTown] = {
            'latitude': center.latitude,
            'longitude': center.longitude,
          };
        } else {
          final latitude = _toDouble(data['latitude']);
          final longitude = _toDouble(data['longitude']);
          if (latitude != null && longitude != null) {
            loadedTownCenters[normalizedTown] = {
              'latitude': latitude,
              'longitude': longitude,
            };
          }
        }
      }

      _townSafetyDataset
        ..clear()
        ..addAll(loadedTownDataset);
      _townCenters
        ..clear()
        ..addAll(loadedTownCenters);
      _townDatasetLoadedAt = DateTime.now();

      if (_townSafetyDataset.isNotEmpty) {
        debugPrint('✅ Loaded ${_townSafetyDataset.length} Tamil Nadu town datasets from Firestore');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load Tamil Nadu town datasets: $e');
    }
  }

  static List<Map<String, dynamic>> _normalizeAreaList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((entry) => entry.map((key, val) => MapEntry('$key', val)))
        .toList(growable: false);
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static Map<String, Map<String, dynamic>> _allSafetyDatasets() {
    return {
      ..._citySafetyDataset,
      ..._townSafetyDataset,
    };
  }

  static Position? _buildAvoidanceWaypoint({
    required Position start,
    required Position end,
    required List<Map<String, dynamic>> riskyAreas,
  }) {
    final midpointLat = (start.latitude + end.latitude) / 2;
    final midpointLng = (start.longitude + end.longitude) / 2;

    if (riskyAreas.isEmpty) {
      return Position(
        latitude: midpointLat,
        longitude: midpointLng,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    final nearestRisk = riskyAreas.first;
    final riskLat = (nearestRisk['latitude'] as num).toDouble();
    final riskLng = (nearestRisk['longitude'] as num).toDouble();

    final latOffset = midpointLat >= riskLat ? 0.004 : -0.004;
    final lngOffset = midpointLng >= riskLng ? 0.004 : -0.004;

    return Position(
      latitude: midpointLat + latOffset,
      longitude: midpointLng + lngOffset,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  static double _routeDistanceKm(List<Position> route) {
    if (route.length < 2) {
      return 0;
    }

    var total = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      total += _distanceKm(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude,
      );
    }
    return total;
  }

  static List<Position> _sampleRoutePoints(List<Position> route) {
    if (route.length <= 2) {
      return route;
    }

    final samples = <Position>[route.first];
    for (var i = 0; i < route.length - 1; i++) {
      final start = route[i];
      final end = route[i + 1];
      samples.add(_interpolatePosition(start, end, 0.33));
      samples.add(_interpolatePosition(start, end, 0.66));
      samples.add(end);
    }

    final deduped = <String, Position>{};
    for (final point in samples) {
      final key = '${point.latitude.toStringAsFixed(5)}_${point.longitude.toStringAsFixed(5)}';
      deduped[key] = point;
    }
    return deduped.values.toList(growable: false);
  }

  static Position _interpolatePosition(Position start, Position end, double ratio) {
    return Position(
      latitude: start.latitude + ((end.latitude - start.latitude) * ratio),
      longitude: start.longitude + ((end.longitude - start.longitude) * ratio),
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  static Future<double> _scoreRoute(List<Position> route, DateTime time) async {
    final points = _sampleRoutePoints(route);
    if (points.isEmpty) {
      return 10.0;
    }

    double dangerTotal = 0;
    for (final point in points) {
      final prediction = await predictDanger(position: point, time: time);
      dangerTotal += (prediction['dangerScore'] as num?)?.toDouble() ?? 5.0;
    }

    final averageDanger = dangerTotal / points.length;
    final distancePenalty = math.min(_routeDistanceKm(route) / 12.0, 2.0);
    return (averageDanger + distancePenalty).clamp(0.0, 10.0);
  }

  static String _toTitleCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  static Future<String> _resolveNearestCityName(Position position) async {
    await _ensureTownDatasetsLoaded();
    String nearestCity = 'coimbatore';
    double nearestDistanceKm = double.infinity;

    final centers = {
      ..._cityCenters,
      ..._townCenters,
    };

    centers.forEach((city, center) {
      final lat = center['latitude']!;
      final lng = center['longitude']!;
      final distanceKm = _distanceKm(position.latitude, position.longitude, lat, lng);
      if (distanceKm < nearestDistanceKm) {
        nearestDistanceKm = distanceKm;
        nearestCity = city;
      }
    });

    return nearestCity;
  }

  static Future<Map<String, dynamic>> _getCuratedDangerHotspot(Position position) async {
    final nearestCity = await _resolveNearestCityName(position);
    final cityData = _allSafetyDatasets()[nearestCity];
    if (cityData == null) {
      return {'inDangerZone': false};
    }

    final riskyAreas = (cityData['riskyAreas'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (riskyAreas.isEmpty) {
      return {'inDangerZone': false};
    }

    Map<String, dynamic>? nearestArea;
    double nearestDistanceKm = double.infinity;

    for (final area in riskyAreas) {
      final lat = (area['latitude'] as num).toDouble();
      final lng = (area['longitude'] as num).toDouble();
      final distanceKm = _distanceKm(position.latitude, position.longitude, lat, lng);
      if (distanceKm < nearestDistanceKm) {
        nearestDistanceKm = distanceKm;
        nearestArea = area;
      }
    }

    if (nearestArea == null) {
      return {'inDangerZone': false};
    }

    final risk = (nearestArea['risk'] as String? ?? 'LOW').toUpperCase();
    final entryThresholdKm = risk == 'HIGH' ? 0.90 : 0.60;
    final inHotspot = nearestDistanceKm <= entryThresholdKm;

    if (!inHotspot) {
      return {'inDangerZone': false};
    }

    final mostDangerous = risk == 'HIGH' && nearestDistanceKm <= 0.40;

    return {
      'inDangerZone': true,
      'zoneName': nearestArea['name'],
      'incidentType': 'curated_hotspot',
      'lastIncident': nearestArea['reason'],
      'risk': risk,
      'city': _toTitleCase(nearestCity),
      'distanceKm': nearestDistanceKm,
      'sourceType': 'government_dataset',
      'isMostDangerousPlace': mostDangerous,
    };
  }

  static double _applyCuratedRiskBoost(double score, Map<String, dynamic> hotspot) {
    if (hotspot['inDangerZone'] != true) {
      return score;
    }

    final risk = (hotspot['risk'] as String? ?? 'LOW').toUpperCase();
    final distanceKm = (hotspot['distanceKm'] as num?)?.toDouble() ?? 1.0;

    var boost = 0.0;
    if (risk == 'HIGH') {
      boost = distanceKm <= 0.4 ? 2.2 : 1.6;
    } else if (risk == 'MEDIUM') {
      boost = distanceKm <= 0.35 ? 1.2 : 0.8;
    } else {
      boost = 0.4;
    }

    return (score + boost).clamp(0.0, 10.0);
  }

  static Map<String, dynamic> _mergeZoneDetails(
    Map<String, dynamic> dbZone,
    Map<String, dynamic> curatedZone,
  ) {
    final dbInZone = dbZone['inDangerZone'] == true;
    final curatedInZone = curatedZone['inDangerZone'] == true;

    if (!dbInZone && !curatedInZone) {
      return {'inDangerZone': false};
    }

    if (!dbInZone && curatedInZone) {
      return curatedZone;
    }

    if (dbInZone && !curatedInZone) {
      return dbZone;
    }

    final curatedRisk = (curatedZone['risk'] as String? ?? 'LOW').toUpperCase();
    final curatedRank = curatedRisk == 'HIGH' ? 3 : curatedRisk == 'MEDIUM' ? 2 : 1;

    // If both zones are active, prefer curated HIGH/MEDIUM hotspot metadata for warnings.
    if (curatedRank >= 2) {
      return {
        ...dbZone,
        ...curatedZone,
        'inDangerZone': true,
      };
    }

    return {
      ...curatedZone,
      ...dbZone,
      'inDangerZone': true,
    };
  }
}
