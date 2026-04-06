/// Unit Tests for SOS Trigger Logic
/// Tests: SOS cubit validation, model round-trips, trigger orchestration basics

import 'package:flutter_test/flutter_test.dart';
import 'package:women_safety/bloc/sos/sos_cubit.dart';
import 'package:women_safety/models/app_user.dart';
import 'package:women_safety/models/guardian.dart';
import 'package:women_safety/models/sos_alert.dart';
import 'package:women_safety/utils/test_logger.dart';

void main() {
  TestLogger.init();

  group('SOS Trigger Logic Tests', () {
    test('SOS Trigger Should Reject Missing Emergency Contacts', () async {
      TestLogger.logSOSTrigger('Testing SOS with no emergency contacts');

      final cubit = SosCubit();
      final user = AppUser(
        uid: 'test_user_001',
        displayName: 'Test User',
        email: 'test@example.com',
        phoneNumber: '+919876543210',
      );

      await cubit.triggerSOS(
        user: user,
        emergencyContacts: const [],
        triggerType: 'BUTTON',
        recordVideo: false,
        makeCall: false,
        playAlarm: false,
      );

      expect(cubit.state.isTriggered, false);
      expect(cubit.state.isLoading, false);
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.error, contains('No emergency contacts'));
    });

    test('AppUser Should Expose Friendly Name', () {
      final user = AppUser(
        uid: 'test_user_001',
        displayName: 'Test User',
        email: 'test@example.com',
        phoneNumber: '+919876543210',
      );

      expect(user.id, 'test_user_001');
      expect(user.name, 'Test User');
    });

    test('Guardian Should Serialize Correctly', () {
      final guardian = Guardian(
        id: 'guardian_1',
        name: 'John Doe',
        phone: '+919123456789',
        email: 'john@example.com',
        relationship: 'family',
        isPrimary: true,
      );

      final json = guardian.toJson();
      final restored = Guardian.fromJson(json);

      expect(restored.name, guardian.name);
      expect(restored.phone, guardian.phone);
      expect(restored.isPrimary, true);
    });

    test('SOSAlert Should Serialize Correctly', () {
      final alert = SOSAlert(
        userId: 'test_user_001',
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: DateTime.parse('2026-04-03T10:00:00.000Z'),
        triggerType: 'BUTTON',
      );

      final json = alert.toJson();
      final restored = SOSAlert.fromJson(json);

      expect(restored.userId, alert.userId);
      expect(restored.latitude, alert.latitude);
      expect(restored.longitude, alert.longitude);
      expect(restored.triggerType, 'BUTTON');
    });
  });
}
