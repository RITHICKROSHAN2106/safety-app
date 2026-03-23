import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Guardian Live Tracking Service
/// Streams real-time location updates to guardians during active SOS
/// Implements two-way acknowledgment and push notifications
class GuardianTrackingService {
  static final GuardianTrackingService _instance = GuardianTrackingService._internal();
  factory GuardianTrackingService() => _instance;
  GuardianTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<Position>? _locationStreamSubscription;
  Timer? _updateTimer;
  String? _activeTrackingSessionId;
  bool _isTracking = false;

  // Configuration
  static const int updateIntervalSeconds = 10; // Update every 10 seconds
  static const int highFrequencyIntervalSeconds = 5; // High frequency for first 2 minutes
  static const int highFrequencyDurationSeconds = 120;

  /// Start live tracking for an active SOS session
  Future<String> startTracking({
    required String userId,
    required String sosId,
    required List<String> guardianPhones,
    required Map<String, dynamic> initialLocation,
  }) async {
    debugPrint('🎯 Starting guardian live tracking...');
    
    if (_isTracking) {
      debugPrint('⚠️ Tracking already active, stopping previous session...');
      await stopTracking();
    }

    try {
      // Create tracking session in Firestore
      _activeTrackingSessionId = 'track_${DateTime.now().millisecondsSinceEpoch}';
      
      final trackingData = {
        'sessionId': _activeTrackingSessionId,
        'userId': userId,
        'sosId': sosId,
        'guardianPhones': guardianPhones,
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'lastUpdateAt': FieldValue.serverTimestamp(),
        'initialLocation': initialLocation,
        'currentLocation': initialLocation,
        'locationHistory': [
          {
            ...initialLocation,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
        'acknowledgments': {}, // guardianPhone: {acknowledged: bool, timestamp: DateTime}
      };

      await _firestore
          .collection('live_tracking')
          .doc(_activeTrackingSessionId)
          .set(trackingData);

      debugPrint('✅ Tracking session created: $_activeTrackingSessionId');

      // Send push notifications to guardians
      await _sendTrackingNotifications(guardianPhones, userId, _activeTrackingSessionId!);

      // Start location streaming with high frequency initially
      _isTracking = true;
      await _startLocationStream(highFrequency: true);

      // Switch to normal frequency after 2 minutes
      Future.delayed(Duration(seconds: highFrequencyDurationSeconds), () {
        if (_isTracking) {
          debugPrint('🔄 Switching to normal frequency updates...');
          _startLocationStream(highFrequency: false);
        }
      });

      return _activeTrackingSessionId!;
    } catch (e) {
      debugPrint('❌ Error starting tracking: $e');
      rethrow;
    }
  }

  /// Start streaming location updates
  Future<void> _startLocationStream({required bool highFrequency}) async {
    // Cancel existing stream if any
    await _locationStreamSubscription?.cancel();
    _updateTimer?.cancel();

    final interval = highFrequency 
        ? highFrequencyIntervalSeconds 
        : updateIntervalSeconds;

    debugPrint('📍 Starting location stream (interval: ${interval}s)');

    // Use timer-based updates for reliability
    _updateTimer = Timer.periodic(Duration(seconds: interval), (timer) async {
      if (!_isTracking || _activeTrackingSessionId == null) {
        timer.cancel();
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _updateLocation(position);
      } catch (e) {
        debugPrint('⚠️ Error updating location: $e');
      }
    });

    // Also listen to position stream for immediate updates
    _locationStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        if (_isTracking && _activeTrackingSessionId != null) {
          _updateLocation(position);
        }
      },
      onError: (error) {
        debugPrint('❌ Location stream error: $error');
      },
    );
  }

  /// Update location in Firestore
  Future<void> _updateLocation(Position position) async {
    if (_activeTrackingSessionId == null) return;

    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('live_tracking')
          .doc(_activeTrackingSessionId)
          .update({
        'currentLocation': locationData,
        'lastUpdateAt': FieldValue.serverTimestamp(),
        'locationHistory': FieldValue.arrayUnion([locationData]),
      });

      debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Error updating location in Firestore: $e');
    }
  }

  /// Send push notifications to guardians
  Future<void> _sendTrackingNotifications(
    List<String> guardianPhones,
    String userId,
    String trackingSessionId,
  ) async {
    debugPrint('📲 Sending tracking notifications to ${guardianPhones.length} guardians...');

    try {
      // Create notification payload
      final notificationData = {
        'type': 'live_tracking_started',
        'userId': userId,
        'trackingSessionId': trackingSessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'title': 'Emergency Alert - Live Tracking Active',
        'body': 'User needs help! Tap to view live location.',
      };

      // Store notification in Firestore for guardians to receive
      // In production, you'd use FCM topics or individual tokens
      for (final phone in guardianPhones) {
        await _firestore
            .collection('guardian_notifications')
            .add({
          ...notificationData,
          'guardianPhone': phone,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Notifications sent to guardians');
    } catch (e) {
      debugPrint('❌ Error sending notifications: $e');
    }
  }

  /// Guardian acknowledges they received the alert
  Future<void> acknowledgeAlert({
    required String trackingSessionId,
    required String guardianPhone,
    required String guardianName,
  }) async {
    debugPrint('✅ Guardian acknowledgment: $guardianName ($guardianPhone)');

    try {
      await _firestore
          .collection('live_tracking')
          .doc(trackingSessionId)
          .update({
        'acknowledgments.$guardianPhone': {
          'acknowledged': true,
          'guardianName': guardianName,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      // Send confirmation notification to user
      final doc = await _firestore
          .collection('live_tracking')
          .doc(trackingSessionId)
          .get();
      
      if (doc.exists) {
        final userId = doc.data()?['userId'];
        if (userId != null) {
          await _firestore.collection('user_notifications').add({
            'userId': userId,
            'type': 'guardian_acknowledged',
            'guardianName': guardianName,
            'guardianPhone': guardianPhone,
            'message': '$guardianName has been notified and is tracking your location.',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      debugPrint('✅ Acknowledgment recorded');
    } catch (e) {
      debugPrint('❌ Error recording acknowledgment: $e');
    }
  }

  /// Get real-time tracking stream for a session
  Stream<DocumentSnapshot<Map<String, dynamic>>> getTrackingStream(String trackingSessionId) {
    return _firestore
        .collection('live_tracking')
        .doc(trackingSessionId)
        .snapshots();
  }

  /// Get acknowledgments for current session
  Future<Map<String, dynamic>> getAcknowledgments() async {
    if (_activeTrackingSessionId == null) return {};

    try {
      final doc = await _firestore
          .collection('live_tracking')
          .doc(_activeTrackingSessionId)
          .get();

      return doc.data()?['acknowledgments'] ?? {};
    } catch (e) {
      debugPrint('❌ Error fetching acknowledgments: $e');
      return {};
    }
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    debugPrint('🛑 Stopping guardian live tracking...');

    _isTracking = false;
    await _locationStreamSubscription?.cancel();
    _updateTimer?.cancel();

    if (_activeTrackingSessionId != null) {
      try {
        await _firestore
            .collection('live_tracking')
            .doc(_activeTrackingSessionId)
            .update({
          'status': 'completed',
          'endedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Tracking session ended: $_activeTrackingSessionId');
      } catch (e) {
        debugPrint('❌ Error ending tracking session: $e');
      }

      _activeTrackingSessionId = null;
    }
  }

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Get active tracking session ID
  String? get activeSessionId => _activeTrackingSessionId;

  /// Get tracking URL for sharing
  String getTrackingUrl(String trackingSessionId) {
    // Replace with your actual web app URL
    return 'https://yourapp.com/track/$trackingSessionId';
  }

  /// Dispose resources
  void dispose() {
    _locationStreamSubscription?.cancel();
    _updateTimer?.cancel();
  }
}
