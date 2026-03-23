import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Safe Journey Mode Service
/// Tracks user journey with expected destination and ETA
/// Auto-alerts on route deviation or missed check-ins
/// Provides live tracking link to guardians
class SafeJourneyService {
  static final SafeJourneyService _instance = SafeJourneyService._internal();
  factory SafeJourneyService() => _instance;
  SafeJourneyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<Position>? _locationStreamSubscription;
  Timer? _checkInTimer;
  String? _activeJourneyId;
  bool _isJourneyActive = false;

  // Configuration
  static const int locationUpdateIntervalSeconds = 30;
  static const int checkInIntervalMinutes = 10; // Check-in every 10 minutes
  static const double routeDeviationThresholdMeters = 500.0; // 500m off-route
  static const double destinationReachedThresholdMeters = 100.0; // 100m from destination

  /// Start a safe journey
  Future<String> startJourney({
    required String userId,
    required String userName,
    required Map<String, dynamic> startLocation,
    required Map<String, dynamic> destinationLocation,
    required String destinationName,
    required DateTime estimatedArrival,
    required List<String> guardianPhones,
    String? notes,
  }) async {
    debugPrint('🚗 Starting safe journey...');

    if (_isJourneyActive) {
      debugPrint('⚠️ Journey already active, ending previous journey...');
      await endJourney(reason: 'New journey started');
    }

    try {
      _activeJourneyId = 'journey_${DateTime.now().millisecondsSinceEpoch}';
      _isJourneyActive = true;

      // Calculate expected route distance
      final distance = Geolocator.distanceBetween(
        startLocation['latitude'],
        startLocation['longitude'],
        destinationLocation['latitude'],
        destinationLocation['longitude'],
      );

      // Create journey in Firestore
      final journeyData = {
        'journeyId': _activeJourneyId,
        'userId': userId,
        'userName': userName,
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'startLocation': startLocation,
        'destinationLocation': destinationLocation,
        'destinationName': destinationName,
        'estimatedArrival': estimatedArrival.toIso8601String(),
        'expectedDistance': distance,
        'currentLocation': startLocation,
        'guardianPhones': guardianPhones,
        'notes': notes ?? '',
        'locationHistory': [
          {
            ...startLocation,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
        'checkIns': [],
        'alerts': [],
        'deviations': [],
      };

      await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .set(journeyData);

      debugPrint('✅ Journey created: $_activeJourneyId');

      // Start location tracking
      _startLocationTracking();

      // Start check-in monitoring
      _startCheckInMonitoring();

      // Monitor ETA
      _monitorETA(estimatedArrival);

      // Notify guardians
      await _notifyGuardiansJourneyStarted(
        guardianPhones,
        userName,
        destinationName,
        estimatedArrival,
      );

      return _activeJourneyId!;
    } catch (e) {
      debugPrint('❌ Error starting journey: $e');
      _isJourneyActive = false;
      rethrow;
    }
  }

  /// Start tracking location during journey
  void _startLocationTracking() {
    debugPrint('📍 Starting journey location tracking...');

    _locationStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    ).listen(
      (Position position) async {
        if (_isJourneyActive && _activeJourneyId != null) {
          await _updateJourneyLocation(position);
          await _checkRouteDeviation(position);
          await _checkDestinationReached(position);
        }
      },
      onError: (error) {
        debugPrint('❌ Location stream error: $error');
      },
    );

    // Also use timer for reliability
    Timer.periodic(Duration(seconds: locationUpdateIntervalSeconds), (timer) async {
      if (!_isJourneyActive) {
        timer.cancel();
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _updateJourneyLocation(position);
      } catch (e) {
        debugPrint('⚠️ Error getting location: $e');
      }
    });
  }

  /// Update journey location in Firestore
  Future<void> _updateJourneyLocation(Position position) async {
    if (_activeJourneyId == null) return;

    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .update({
        'currentLocation': locationData,
        'lastUpdateAt': FieldValue.serverTimestamp(),
        'locationHistory': FieldValue.arrayUnion([locationData]),
      });

      debugPrint('📍 Journey location updated');
    } catch (e) {
      debugPrint('❌ Error updating journey location: $e');
    }
  }

  /// Check if user deviated from route
  Future<void> _checkRouteDeviation(Position currentPosition) async {
    if (_activeJourneyId == null) return;

    try {
      final doc = await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final destination = data['destinationLocation'];
      
      // Calculate distance to destination
      final distanceToDestination = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        destination['latitude'],
        destination['longitude'],
      );

      final expectedDistance = data['expectedDistance'] ?? 0.0;
      
      // Simple deviation check: if current distance is much greater than expected
      // (In production, use proper route calculation with Google Maps API)
      if (distanceToDestination > expectedDistance + routeDeviationThresholdMeters) {
        await _recordDeviation(currentPosition, distanceToDestination);
      }
    } catch (e) {
      debugPrint('❌ Error checking route deviation: $e');
    }
  }

  /// Record route deviation
  Future<void> _recordDeviation(Position position, double distance) async {
    try {
      final deviationData = {
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'distanceFromRoute': distance,
        'alertSent': true,
      };

      await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .update({
        'deviations': FieldValue.arrayUnion([deviationData]),
        'alerts': FieldValue.arrayUnion([
          {
            'type': 'route_deviation',
            'message': 'User deviated from expected route',
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]),
      });

      // Alert guardians
      await _alertGuardians('route_deviation', 
          'User has deviated from the expected route by ${distance.toStringAsFixed(0)}m');

      debugPrint('⚠️ Route deviation recorded and alert sent');
    } catch (e) {
      debugPrint('❌ Error recording deviation: $e');
    }
  }

  /// Check if destination reached
  Future<void> _checkDestinationReached(Position currentPosition) async {
    if (_activeJourneyId == null) return;

    try {
      final doc = await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final destination = data['destinationLocation'];

      final distanceToDestination = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        destination['latitude'],
        destination['longitude'],
      );

      if (distanceToDestination <= destinationReachedThresholdMeters) {
        debugPrint('🎯 Destination reached!');
        await endJourney(reason: 'Destination reached safely');
      }
    } catch (e) {
      debugPrint('❌ Error checking destination: $e');
    }
  }

  /// Start periodic check-in monitoring
  void _startCheckInMonitoring() {
    debugPrint('⏰ Starting check-in monitoring...');

    _checkInTimer = Timer.periodic(
      Duration(minutes: checkInIntervalMinutes),
      (timer) async {
        if (!_isJourneyActive) {
          timer.cancel();
          return;
        }

        await _requestCheckIn();
      },
    );
  }

  /// Request check-in from user
  Future<void> _requestCheckIn() async {
    if (_activeJourneyId == null) return;

    debugPrint('📱 Requesting check-in...');

    try {
      await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .update({
        'pendingCheckIn': {
          'requested': true,
          'timestamp': FieldValue.serverTimestamp(),
          'timeout': DateTime.now()
              .add(Duration(minutes: 5))
              .toIso8601String(), // 5 min timeout
        },
      });

      // In production, send push notification to user app
      debugPrint('✅ Check-in request sent');

      // Schedule alert if no response
      Future.delayed(Duration(minutes: 5), () async {
        await _checkMissedCheckIn();
      });
    } catch (e) {
      debugPrint('❌ Error requesting check-in: $e');
    }
  }

  /// Record check-in from user
  Future<void> recordCheckIn({String? message}) async {
    if (_activeJourneyId == null) return;

    debugPrint('✅ Check-in recorded');

    try {
      final checkInData = {
        'timestamp': FieldValue.serverTimestamp(),
        'localTimestamp': DateTime.now().toIso8601String(),
        'message': message ?? 'All good',
      };

      await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .update({
        'checkIns': FieldValue.arrayUnion([checkInData]),
        'pendingCheckIn': FieldValue.delete(),
      });

      debugPrint('✅ Check-in saved');
    } catch (e) {
      debugPrint('❌ Error recording check-in: $e');
    }
  }

  /// Check if user missed check-in
  Future<void> _checkMissedCheckIn() async {
    if (_activeJourneyId == null) return;

    try {
      final doc = await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final pendingCheckIn = data['pendingCheckIn'];

      if (pendingCheckIn != null && pendingCheckIn['requested'] == true) {
        debugPrint('⚠️ Missed check-in detected!');

        await _firestore
            .collection('safe_journeys')
            .doc(_activeJourneyId)
            .update({
          'alerts': FieldValue.arrayUnion([
            {
              'type': 'missed_checkin',
              'message': 'User missed scheduled check-in',
              'timestamp': FieldValue.serverTimestamp(),
            }
          ]),
          'pendingCheckIn': FieldValue.delete(),
        });

        await _alertGuardians('missed_checkin', 
            'User did not respond to check-in request');
      }
    } catch (e) {
      debugPrint('❌ Error checking missed check-in: $e');
    }
  }

  /// Monitor ETA and alert if delayed
  void _monitorETA(DateTime estimatedArrival) {
    final delayCheckTime = estimatedArrival.add(Duration(minutes: 15));
    final delay = delayCheckTime.difference(DateTime.now());

    if (delay.isNegative) return;

    Timer(delay, () async {
      if (_isJourneyActive && _activeJourneyId != null) {
        debugPrint('⚠️ ETA exceeded!');

        await _firestore
            .collection('safe_journeys')
            .doc(_activeJourneyId)
            .update({
          'alerts': FieldValue.arrayUnion([
            {
              'type': 'eta_exceeded',
              'message': 'User has not reached destination by expected time',
              'timestamp': FieldValue.serverTimestamp(),
            }
          ]),
        });

        await _alertGuardians('eta_exceeded', 
            'User has not arrived at destination by estimated time');
      }
    });
  }

  /// Send alert to guardians
  Future<void> _alertGuardians(String alertType, String message) async {
    if (_activeJourneyId == null) return;

    try {
      final doc = await _firestore
          .collection('safe_journeys')
          .doc(_activeJourneyId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final guardianPhones = List<String>.from(data['guardianPhones'] ?? []);
      final userName = data['userName'] ?? 'User';

      for (final phone in guardianPhones) {
        await _firestore.collection('guardian_notifications').add({
          'type': alertType,
          'guardianPhone': phone,
          'journeyId': _activeJourneyId,
          'userName': userName,
          'message': message,
          'trackingUrl': getJourneyTrackingUrl(_activeJourneyId!),
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      debugPrint('🚨 Guardians alerted: $alertType');
    } catch (e) {
      debugPrint('❌ Error alerting guardians: $e');
    }
  }

  /// Notify guardians when journey starts
  Future<void> _notifyGuardiansJourneyStarted(
    List<String> guardianPhones,
    String userName,
    String destination,
    DateTime eta,
  ) async {
    try {
      for (final phone in guardianPhones) {
        await _firestore.collection('guardian_notifications').add({
          'type': 'journey_started',
          'guardianPhone': phone,
          'journeyId': _activeJourneyId,
          'userName': userName,
          'destination': destination,
          'eta': eta.toIso8601String(),
          'message': '$userName started a journey to $destination',
          'trackingUrl': getJourneyTrackingUrl(_activeJourneyId!),
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      debugPrint('✅ Guardians notified of journey start');
    } catch (e) {
      debugPrint('❌ Error notifying guardians: $e');
    }
  }

  /// End journey
  Future<void> endJourney({required String reason}) async {
    debugPrint('🛑 Ending journey: $reason');

    _isJourneyActive = false;
    await _locationStreamSubscription?.cancel();
    _checkInTimer?.cancel();

    if (_activeJourneyId != null) {
      try {
        await _firestore
            .collection('safe_journeys')
            .doc(_activeJourneyId)
            .update({
          'status': 'completed',
          'endedAt': FieldValue.serverTimestamp(),
          'endReason': reason,
        });

        debugPrint('✅ Journey ended: $_activeJourneyId');

        // Notify guardians
        final doc = await _firestore
            .collection('safe_journeys')
            .doc(_activeJourneyId)
            .get();

        if (doc.exists) {
          final guardianPhones = List<String>.from(
              doc.data()?['guardianPhones'] ?? []);
          final userName = doc.data()?['userName'] ?? 'User';

          for (final phone in guardianPhones) {
            await _firestore.collection('guardian_notifications').add({
              'type': 'journey_ended',
              'guardianPhone': phone,
              'journeyId': _activeJourneyId,
              'userName': userName,
              'message': '$userName has completed their journey safely',
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
            });
          }
        }

        _activeJourneyId = null;
      } catch (e) {
        debugPrint('❌ Error ending journey: $e');
      }
    }
  }

  /// Get journey tracking stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getJourneyStream(String journeyId) {
    return _firestore
        .collection('safe_journeys')
        .doc(journeyId)
        .snapshots();
  }

  /// Get journey tracking URL
  String getJourneyTrackingUrl(String journeyId) {
    // Replace with your actual web app URL
    return 'https://yourapp.com/journey/$journeyId';
  }

  /// Check if journey is active
  bool get isJourneyActive => _isJourneyActive;

  /// Get active journey ID
  String? get activeJourneyId => _activeJourneyId;

  /// Dispose resources
  void dispose() {
    _locationStreamSubscription?.cancel();
    _checkInTimer?.cancel();
  }
}
