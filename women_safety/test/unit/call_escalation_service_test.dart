import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:women_safety/models/guardian.dart';
import 'package:women_safety/services/call_escalation_service.dart';
import 'package:women_safety/services/call_service.dart';

void main() {
  group('CallEscalationService', () {
    setUp(() {
      CallEscalationService.stopEscalation();
      CallEscalationService.resetTestConfiguration();
    });

    tearDown(() {
      CallEscalationService.stopEscalation();
      CallEscalationService.resetTestConfiguration();
    });

    test('retries each guardian 3 times before next guardian', () async {
      final attempts = <String>[];
      final guardians = <Guardian>[
        Guardian(name: 'Primary', phone: '1111111111', isPrimary: true),
        Guardian(name: 'Secondary', phone: '2222222222', isPrimary: false),
      ];

      CallEscalationService.configureForTest(
        callAttemptHandler: (phone) async {
          attempts.add(phone);
          return true;
        },
        callOutcomeHandler: ({
          Duration timeout = const Duration(seconds: 45),
          Duration answeredThreshold = const Duration(seconds: 15),
        }) async {
          return CallOutcome.missed;
        },
        emergencyCallHandler: (_) async => true,
        maxAttempts: 3,
        retryDelay: const Duration(milliseconds: 15),
      );

      await CallEscalationService.startEscalation(
        guardians: guardians,
        callEmergencyServicesOnFailure: false,
      );

      await Future<void>.delayed(const Duration(milliseconds: 220));

      final primaryAttempts = attempts.where((p) => p == '1111111111').length;
      final secondaryAttempts = attempts.where((p) => p == '2222222222').length;

      expect(primaryAttempts, 3);
      expect(secondaryAttempts, 3);
      expect(CallEscalationService.isEscalating, false);
    });

    test('immediate technical failure retries guardian 3 times before next guardian', () async {
      final attempts = <String>[];
      final guardians = <Guardian>[
        Guardian(name: 'Primary', phone: '1111111111', isPrimary: true),
        Guardian(name: 'Secondary', phone: '2222222222', isPrimary: false),
      ];

      CallEscalationService.configureForTest(
        callAttemptHandler: (phone) async {
          attempts.add(phone);
          if (phone == '1111111111') return false;
          return true;
        },
        callOutcomeHandler: ({
          Duration timeout = const Duration(seconds: 45),
          Duration answeredThreshold = const Duration(seconds: 15),
        }) async {
          return CallOutcome.rejected;
        },
        emergencyCallHandler: (_) async => true,
        maxAttempts: 3,
        retryDelay: const Duration(milliseconds: 15),
      );

      await CallEscalationService.startEscalation(
        guardians: guardians,
        callEmergencyServicesOnFailure: false,
      );

      await Future<void>.delayed(const Duration(milliseconds: 140));

      final primaryAttempts = attempts.where((p) => p == '1111111111').length;
      final secondaryAttempts = attempts.where((p) => p == '2222222222').length;

      expect(primaryAttempts, 3);
      expect(secondaryAttempts, 3);
    });
  });
}
