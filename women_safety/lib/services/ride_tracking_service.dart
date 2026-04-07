import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/guardian.dart';
import '../models/sos_alert.dart';
import 'config.dart';
import 'whatsapp_service.dart';

/// 🚗 Ride Tracking Service - Track Uber/Ola rides and alert on route deviation
class RideTrackingService {
  static bool _isTracking = false;
  static StreamSubscription<Position>? _positionStream;
  static String? _currentRideId;
  static final List<Position> _routePoints = [];
  static final List<Position> _expectedRoute = [];
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final StreamController<RideTrackingSnapshot> _updatesController =
      StreamController<RideTrackingSnapshot>.broadcast();
  static RideTrackingSnapshot? _lastSnapshot;
  static const double _routeDeviationThresholdMeters = 250;
  static const int _maxLocalRoutePoints = 500;
  static const Duration _firestoreUpdateInterval = Duration(seconds: 15);
  static const double _minMovementForFirestoreMeters = 25;
  static const Duration _deviationAlertCooldown = Duration(minutes: 2);
  static DateTime? _lastFirestoreUpdateAt;
  static Position? _lastPersistedPosition;
  static DateTime? _lastDeviationAlertAt;

  /// Check if currently tracking a ride
  static bool get isTracking => _isTracking;

  /// Get current ride ID
  static String? get currentRideId => _currentRideId;
  static Stream<RideTrackingSnapshot> get trackingUpdates =>
      _updatesController.stream;
  static RideTrackingSnapshot? get lastSnapshot => _lastSnapshot;

  /// Start tracking a ride
  static Future<String?> startRideTracking({
    required String userId,
    required List<Guardian> guardians,
    required Map<String, dynamic> rideDetails,
    Position? destination,
  }) async {
    if (_isTracking) {
      debugPrint('⚠️ Already tracking a ride');
      return _currentRideId;
    }

    try {
      final locationReady = await _ensureLocationReady();
      if (!locationReady) {
        debugPrint(
          '❌ Cannot start ride tracking without location permission/services',
        );
        _emitSnapshot(
          status: 'TRACKING_BLOCKED',
          statusMessage: 'Location permission or service unavailable',
        );
        return null;
      }

      // Generate unique ride ID
      _currentRideId =
          'ride_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Store ride details in Firestore
      await _firestore.collection('rides').doc(_currentRideId).set({
        'userId': userId,
        'rideId': _currentRideId,
        'driverName': rideDetails['driverName'] ?? 'Unknown',
        'driverPhone': rideDetails['driverPhone'] ?? '',
        'vehicleNumber': rideDetails['vehicleNumber'] ?? '',
        'vehicleModel': rideDetails['vehicleModel'] ?? '',
        'rideType': rideDetails['rideType'] ?? 'unknown', // uber, ola, auto
        'startTime': FieldValue.serverTimestamp(),
        'status': 'ongoing',
        'guardianIds': guardians.map((g) => g.id).toList(),
        'expectedDestination': destination != null
            ? {
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              }
            : null,
      });

      // Build a naive expected route if destination provided (straight line sampling)
      if (destination != null) {
        Position? startPosition;
        try {
          startPosition = await Geolocator.getCurrentPosition();
        } catch (_) {
          startPosition = await Geolocator.getLastKnownPosition();
        }

        if (startPosition == null) {
          debugPrint(
            '⚠️ Unable to resolve current position for expected route; skipping expected route setup',
          );
        }

        _expectedRoute.clear();
        if (startPosition != null) {
          final routedPoints = await _buildExpectedRouteFromDirections(
            start: startPosition,
            destination: destination,
          );

          if (routedPoints.isNotEmpty) {
            _expectedRoute.addAll(routedPoints);
            debugPrint(
              '🗺️ Expected route generated from Google Directions with ${_expectedRoute.length} points',
            );
          } else {
            const samples = 10;
            for (int i = 0; i <= samples; i++) {
              final lat =
                  startPosition.latitude +
                  (destination.latitude - startPosition.latitude) *
                      (i / samples);
              final lng =
                  startPosition.longitude +
                  (destination.longitude - startPosition.longitude) *
                      (i / samples);
              _expectedRoute.add(
                Position(
                  longitude: lng,
                  latitude: lat,
                  timestamp: DateTime.now(),
                  accuracy: 0,
                  altitude: 0,
                  heading: 0,
                  speed: 0,
                  speedAccuracy: 0,
                  altitudeAccuracy: 0,
                  headingAccuracy: 0,
                ),
              );
            }
            debugPrint(
              '🗺️ Directions unavailable, using straight-line expected route with ${_expectedRoute.length} points',
            );
          }
        }
      }

      // Notify guardians about ride start
      await _notifyGuardiansRideStart(guardians, rideDetails);

      // Start location tracking
      _startLocationTracking(userId, guardians, destination);

      _isTracking = true;
      _emitSnapshot(
        status: 'TRACKING_STARTED',
        statusMessage: 'Ride tracking is active and guardians are informed.',
      );
      debugPrint('🚗 Ride tracking started: $_currentRideId');
      debugPrint('📍 Guardians can track your location in real-time');

      return _currentRideId;
    } catch (e) {
      debugPrint('❌ Start ride tracking error: $e');
      return null;
    }
  }

  static Future<bool> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Auto-detect ride from location speed and movement patterns
  static Future<bool> detectRideAutomatically() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final speed = position.speed * 3.6; // m/s to km/h

      // Detect if user is in a moving vehicle (speed 20-100 km/h)
      if (speed >= 20 && speed <= 100) {
        debugPrint('🚗 Ride detected! Speed: ${speed.toStringAsFixed(1)} km/h');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check for route deviation and alert guardians
  static Future<void> checkRouteDeviation(Position current) async {
    if (_expectedRoute.isEmpty) return;

    // Find nearest expected route point
    double minDistance = double.infinity;
    for (final point in _expectedRoute) {
      final distance = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) minDistance = distance;
    }

    // Alert if more than 500m off route
    if (minDistance > _routeDeviationThresholdMeters) {
      debugPrint(
        '⚠️ ROUTE DEVIATION: ${minDistance.toInt()}m off expected route!',
      );
      await _alertRouteDeviationAlert(current, minDistance);
    }
  }

  /// Alert guardians about route deviation (simple version)
  static Future<void> _alertRouteDeviationAlert(
    Position position,
    double distance,
  ) async {
    try {
      await _firestore.collection('rides').doc(_currentRideId).update({
        'routeDeviation': true,
        'deviationDistance': distance,
        'deviationLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'deviationTime': FieldValue.serverTimestamp(),
      });
      debugPrint('🚨 Route deviation alert sent to guardians');
    } catch (e) {
      debugPrint('❌ Route deviation alert error: $e');
    }
  }

  /// Notify guardians about ride start
  static Future<void> _notifyGuardiansRideStart(
    List<Guardian> guardians,
    Map<String, dynamic> rideDetails,
  ) async {
    // Send WhatsApp messages
    for (final guardian in guardians) {
      await WhatsAppService.sendWhatsAppMessage(
        phoneNumber: guardian.phone,
        alert: SOSAlert(
          userId: 'tracking',
          timestamp: DateTime.now(),
          latitude: 0,
          longitude: 0,
          triggerType: 'RIDE_START',
        ),
        contactName: guardian.name,
      );

      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('📱 Guardians notified about ride start');
  }

  /// Start continuous location tracking
  static void _startLocationTracking(
    String userId,
    List<Guardian> guardians,
    Position? destination,
  ) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 75, // Lower update frequency to save battery
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            _routePoints.add(position);
            if (_routePoints.length > _maxLocalRoutePoints) {
              _routePoints.removeAt(0);
            }
            final totalDistance = _calculateTotalDistance();
            double? remainingDistance;
            if (destination != null) {
              remainingDistance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                destination.latitude,
                destination.longitude,
              );
            }

            _emitSnapshot(
              status: 'TRACKING_ACTIVE',
              statusMessage: 'Live tracking active',
              position: position,
              totalDistanceMeters: totalDistance,
              remainingDistanceMeters: remainingDistance,
              speedKmh: position.speed * 3.6,
            );

            // Update location in Firestore with throttling to reduce battery/network load.
            await _updateRideLocationThrottled(position);

            // Check for route deviation
            if (_expectedRoute.isNotEmpty) {
              await _checkRouteDeviation(position, guardians);
            }

            // Check if reached destination
            if (destination != null) {
              final distance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                destination.latitude,
                destination.longitude,
              );

              if (distance < 100) {
                // Within 100 meters
                await _notifyReachedDestination(guardians);
              }
            }
          },
          onError: (e) {
            debugPrint('❌ Location tracking error: $e');
            _emitSnapshot(
              status: 'TRACKING_ERROR',
              statusMessage: 'Location stream error: $e',
            );
          },
        );
  }

  /// Update ride location in Firestore
  static Future<void> _updateRideLocation(Position position) async {
    if (_currentRideId == null) return;

    try {
      await _firestore.collection('rides').doc(_currentRideId).update({
        'lastLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'speed': position.speed,
          'heading': position.heading,
        },
        'routePoints': FieldValue.arrayUnion([
          {
            'lat': position.latitude,
            'lng': position.longitude,
            'time': DateTime.now().toIso8601String(),
          },
        ]),
      });
    } catch (e) {
      debugPrint('❌ Update location error: $e');
    }
  }

  static Future<void> _updateRideLocationThrottled(Position position) async {
    final now = DateTime.now();
    if (_lastFirestoreUpdateAt != null &&
        now.difference(_lastFirestoreUpdateAt!) < _firestoreUpdateInterval) {
      return;
    }

    if (_lastPersistedPosition != null) {
      final delta = Geolocator.distanceBetween(
        _lastPersistedPosition!.latitude,
        _lastPersistedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (delta < _minMovementForFirestoreMeters) {
        return;
      }
    }

    _lastFirestoreUpdateAt = now;
    _lastPersistedPosition = position;
    await _updateRideLocation(position);
  }

  /// Check for route deviation
  static Future<void> _checkRouteDeviation(
    Position currentPosition,
    List<Guardian> guardians,
  ) async {
    // Calculate if current position deviates from expected route
    // This is a simplified check - in production, use proper route deviation algorithms

    if (_expectedRoute.isEmpty) return;

    // Find closest point on expected route
    double minDistance = double.infinity;
    for (final expectedPoint in _expectedRoute) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        expectedPoint.latitude,
        expectedPoint.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // If deviated significantly from expected route, alert guardians
    if (minDistance > _routeDeviationThresholdMeters) {
      debugPrint(
        '⚠️ ROUTE DEVIATION DETECTED! Distance: ${minDistance.toStringAsFixed(0)}m',
      );
      await _alertRouteDeviation(guardians, currentPosition, minDistance);
    }
  }

  static Future<List<Position>> _buildExpectedRouteFromDirections({
    required Position start,
    required Position destination,
  }) async {
    if (Config.googleMapsApiKey.isEmpty) {
      debugPrint(
        'ℹ️ GOOGLE_MAPS_API_KEY not configured; skipping Directions API route',
      );
      return const <Position>[];
    }

    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
            'origin': '${start.latitude},${start.longitude}',
            'destination': '${destination.latitude},${destination.longitude}',
            'mode': 'driving',
            'alternatives': 'true',
            'key': Config.googleMapsApiKey,
          });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint('⚠️ Directions API HTTP ${response.statusCode}');
        return const <Position>[];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (decoded['status'] ?? '').toString();
      if (status != 'OK') {
        debugPrint('⚠️ Directions API status: $status');
        return const <Position>[];
      }

      final routes = decoded['routes'] as List<dynamic>? ?? const <dynamic>[];
      if (routes.isEmpty) {
        return const <Position>[];
      }

      Map<String, dynamic>? bestRoute;
      var bestDistanceMeters = double.infinity;
      for (final raw in routes) {
        if (raw is! Map) continue;
        final route = raw.map((key, value) => MapEntry('$key', value));
        final legs = route['legs'] as List<dynamic>? ?? const <dynamic>[];
        var distanceMeters = 0.0;
        for (final legRaw in legs) {
          if (legRaw is! Map) continue;
          final leg = legRaw.map((key, value) => MapEntry('$key', value));
          final distance = leg['distance'];
          if (distance is Map && distance['value'] is num) {
            distanceMeters += (distance['value'] as num).toDouble();
          }
        }

        if (distanceMeters > 0 && distanceMeters < bestDistanceMeters) {
          bestDistanceMeters = distanceMeters;
          bestRoute = route;
        }
      }

      bestRoute ??= (routes.first as Map).map(
        (key, value) => MapEntry('$key', value),
      );
      final overview = bestRoute['overview_polyline'];
      if (overview is! Map || overview['points'] is! String) {
        return const <Position>[];
      }

      return _decodePolyline(overview['points'] as String);
    } catch (e) {
      debugPrint('⚠️ Directions route fetch failed: $e');
      return const <Position>[];
    }
  }

  static List<Position> _decodePolyline(String encoded) {
    final points = <Position>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var result = 1;
      var shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63 - 1;
        result += b << shift;
        shift += 5;
      } while (b >= 0x1f && index < encoded.length);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      result = 1;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63 - 1;
        result += b << shift;
        shift += 5;
      } while (b >= 0x1f && index < encoded.length);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(
        Position(
          latitude: lat / 1E5,
          longitude: lng / 1E5,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );
    }

    return points;
  }

  /// Alert guardians about route deviation
  static Future<void> _alertRouteDeviation(
    List<Guardian> guardians,
    Position position,
    double deviationDistance,
  ) async {
    final now = DateTime.now();
    if (_lastDeviationAlertAt != null &&
        now.difference(_lastDeviationAlertAt!) < _deviationAlertCooldown) {
      debugPrint('ℹ️ Deviation alert suppressed (cooldown active)');
      return;
    }
    _lastDeviationAlertAt = now;

    debugPrint('⚠️ Route deviation: ${deviationDistance.toStringAsFixed(0)}m');
    _emitSnapshot(
      status: 'ROUTE_DEVIATION',
      statusMessage: 'Route deviation detected',
      position: position,
      routeDeviationMeters: deviationDistance,
      totalDistanceMeters: _calculateTotalDistance(),
      speedKmh: position.speed * 3.6,
    );

    // Send emergency alerts
    for (final guardian in guardians) {
      await WhatsAppService.sendWhatsAppMessage(
        phoneNumber: guardian.phone,
        alert: SOSAlert(
          userId: 'tracking',
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          triggerType: 'ROUTE_DEVIATION',
        ),
        contactName: guardian.name,
      );

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Notify guardians that destination was reached
  static Future<void> _notifyReachedDestination(
    List<Guardian> guardians,
  ) async {
    debugPrint('✅ Destination reached safely');
    _emitSnapshot(
      status: 'DESTINATION_REACHED',
      statusMessage: 'Destination reached safely',
      totalDistanceMeters: _calculateTotalDistance(),
    );

    // Send notifications
    for (final guardian in guardians) {
      await WhatsAppService.sendWhatsAppMessage(
        phoneNumber: guardian.phone,
        alert: SOSAlert(
          userId: 'tracking',
          timestamp: DateTime.now(),
          latitude: 0,
          longitude: 0,
          triggerType: 'RIDE_COMPLETE',
        ),
        contactName: guardian.name,
      );
    }

    // Auto-stop tracking
    await stopRideTracking(reachedSafely: true);
  }

  /// Stop ride tracking
  static Future<void> stopRideTracking({bool reachedSafely = false}) async {
    if (!_isTracking) {
      debugPrint('⚠️ Not tracking any ride');
      return;
    }

    try {
      // Stop location tracking
      await _positionStream?.cancel();
      _positionStream = null;

      // Update ride status in Firestore
      if (_currentRideId != null) {
        await _firestore.collection('rides').doc(_currentRideId).update({
          'status': reachedSafely ? 'completed' : 'cancelled',
          'endTime': FieldValue.serverTimestamp(),
          'totalDistance': _calculateTotalDistance(),
        });
      }

      _isTracking = false;
      _currentRideId = null;
      _lastFirestoreUpdateAt = null;
      _lastPersistedPosition = null;
      _lastDeviationAlertAt = null;
      _routePoints.clear();
      _expectedRoute.clear();

      _emitSnapshot(
        status: reachedSafely ? 'TRACKING_COMPLETED' : 'TRACKING_STOPPED',
        statusMessage: reachedSafely
            ? 'Ride ended safely'
            : 'Ride tracking stopped',
      );

      debugPrint('✅ Ride tracking stopped');
    } catch (e) {
      debugPrint('❌ Stop ride tracking error: $e');
    }
  }

  /// Calculate total distance travelled
  static double _calculateTotalDistance() {
    if (_routePoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        _routePoints[i].latitude,
        _routePoints[i].longitude,
        _routePoints[i + 1].latitude,
        _routePoints[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  /// Get ride statistics
  static Future<Map<String, dynamic>?> getRideStats(String rideId) async {
    try {
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      return rideDoc.data();
    } catch (e) {
      debugPrint('❌ Get ride stats error: $e');
      return null;
    }
  }

  /// Emergency panic during ride
  static Future<void> triggerRidePanic(List<Guardian> guardians) async {
    if (!_isTracking || _currentRideId == null) return;

    try {
      // Mark ride as emergency
      await _firestore.collection('rides').doc(_currentRideId).update({
        'status': 'emergency',
        'emergencyTime': FieldValue.serverTimestamp(),
      });

      // Send emergency alerts to guardians
      final position = await Geolocator.getCurrentPosition();

      final alert = SOSAlert(
        userId: 'tracking',
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        triggerType: 'RIDE_EMERGENCY',
      );

      for (final guardian in guardians) {
        await WhatsAppService.sendSOSWhatsApp(
          contacts: [guardian],
          alert: alert,
        );
      }

      // Mark deviation strongly by clearing expected route
      _expectedRoute.clear();

      _emitSnapshot(
        status: 'RIDE_EMERGENCY',
        statusMessage: 'Emergency alert sent to guardians',
        position: position,
        totalDistanceMeters: _calculateTotalDistance(),
      );

      debugPrint('🚨 Ride emergency alert sent!');
    } catch (e) {
      debugPrint('❌ Ride panic error: $e');
    }
  }

  static void _emitSnapshot({
    required String status,
    required String statusMessage,
    Position? position,
    double? totalDistanceMeters,
    double? remainingDistanceMeters,
    double? routeDeviationMeters,
    double? speedKmh,
  }) {
    final snapshot = RideTrackingSnapshot(
      rideId: _currentRideId,
      status: status,
      statusMessage: statusMessage,
      timestamp: DateTime.now(),
      latitude: position?.latitude,
      longitude: position?.longitude,
      speedKmh: speedKmh,
      totalDistanceMeters: totalDistanceMeters,
      remainingDistanceMeters: remainingDistanceMeters,
      routeDeviationMeters: routeDeviationMeters,
    );
    _lastSnapshot = snapshot;
    if (!_updatesController.isClosed) {
      _updatesController.add(snapshot);
    }
  }
}

class RideTrackingSnapshot {
  final String? rideId;
  final String status;
  final String statusMessage;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? speedKmh;
  final double? totalDistanceMeters;
  final double? remainingDistanceMeters;
  final double? routeDeviationMeters;

  const RideTrackingSnapshot({
    required this.rideId,
    required this.status,
    required this.statusMessage,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.speedKmh,
    this.totalDistanceMeters,
    this.remainingDistanceMeters,
    this.routeDeviationMeters,
  });
}
