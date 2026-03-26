import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'ai_danger_prediction_service.dart';
import 'config.dart';
import 'notification_service.dart';

/// Monitors user location and sends local alerts when entering unsafe areas.
class DangerZoneMonitorService {
  static StreamSubscription<Position>? _positionSubscription;
  static bool _isMonitoring = false;
  static bool _wasInDangerZone = false;
  static DateTime? _lastHighRiskNotificationAt;

  static const double _highRiskThreshold = 7.0;
  static const Duration _highRiskNotificationCooldown = Duration(minutes: 10);

  static bool get isMonitoring => _isMonitoring;

  static Future<void> startMonitoring() async {
    if (_isMonitoring) {
      return;
    }

    if (!Config.isAIDangerPredictionEnabled) {
      debugPrint('ℹ️ Danger zone monitoring skipped: AI danger feature is disabled');
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Danger zone monitoring skipped: location services are disabled');
      return;
    }

    final permission = await Geolocator.checkPermission();
    final hasLocationPermission =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!hasLocationPermission) {
      debugPrint('⚠️ Danger zone monitoring skipped: location permission not granted');
      return;
    }

    await AIDangerPredictionService.initialize();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen(
      _handlePositionUpdate,
      onError: (Object error) {
        debugPrint('❌ Danger zone monitor stream error: $error');
      },
      cancelOnError: false,
    );

    _isMonitoring = true;
    debugPrint('✅ Danger zone monitoring started');
  }

  static Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isMonitoring = false;
    _wasInDangerZone = false;
    debugPrint('🛑 Danger zone monitoring stopped');
  }

  static Future<void> _handlePositionUpdate(Position position) async {
    try {
      final prediction = await AIDangerPredictionService.predictDanger(
        position: position,
        time: DateTime.now(),
      );

      final score = (prediction['dangerScore'] as num?)?.toDouble() ?? 0.0;
      final level = (prediction['level'] as String?) ?? 'UNKNOWN';
      final zoneDetails = prediction['zoneDetails'] as Map<String, dynamic>?;
      final inDangerZone = zoneDetails?['inDangerZone'] == true;

      if (inDangerZone && !_wasInDangerZone) {
        final zoneName = zoneDetails?['zoneName'] as String? ?? 'an unsafe area';
        await NotificationService.showNotification(
          id: 1201,
          title: '⚠️ Unsafe Area Alert',
          body: 'You entered $zoneName. Stay alert and avoid isolated routes.',
          payload: 'danger_zone_entered',
        );
      }

      if (!inDangerZone && _wasInDangerZone) {
        await NotificationService.showNotification(
          id: 1202,
          title: '✅ Safer Area Reached',
          body: 'You appear to have moved out of the marked unsafe zone.',
          payload: 'danger_zone_exited',
        );
      }

      final now = DateTime.now();
      final canSendHighRiskAlert = _lastHighRiskNotificationAt == null ||
          now.difference(_lastHighRiskNotificationAt!) >=
              _highRiskNotificationCooldown;

      if (score >= _highRiskThreshold && canSendHighRiskAlert) {
        final roundedScore = score.toStringAsFixed(1);
        await NotificationService.showNotification(
          id: 1203,
          title: '🚨 High Risk Area Nearby',
          body: 'Current safety risk is $level ($roundedScore/10). Consider safer routes.',
          payload: 'danger_score_high',
        );
        _lastHighRiskNotificationAt = now;
      }

      _wasInDangerZone = inDangerZone;
    } catch (e) {
      debugPrint('❌ Danger zone monitor update error: $e');
    }
  }
}
