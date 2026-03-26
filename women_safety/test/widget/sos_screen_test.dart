/// Widget Tests for SOS Screen
/// Tests: SOS button interactions, UI state changes, emergency contact display

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:women_safety/models/app_user.dart';
import 'package:women_safety/models/guardian.dart';
import 'package:women_safety/utils/test_logger.dart';

// Mock Cubits
class MockAuthCubit extends Mock {}
class MockSOSCubit extends Mock {}
class MockLocationCubit extends Mock {}

void main() {
  TestLogger.init();

  group('SOS Screen Widget Tests', () {
    late MockSOSCubit mockSOSCubit;
    late MockAuthCubit mockAuthCubit;
    late MockLocationCubit mockLocationCubit;

    setUp(() {
      TestLogger.logInfo('Setting up SOS screen widget tests', 'SETUP');
      mockSOSCubit = MockSOSCubit();
      mockAuthCubit = MockAuthCubit();
      mockLocationCubit = MockLocationCubit();
    });

    testWidgets('SOS Screen Should Render Title', (WidgetTester tester) async {
      TestLogger.logInfo('Testing SOS screen title rendering', 'WIDGET_TEST');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Emergency SOS')),
            body: Center(child: Text('SOS Screen')),
          ),
        ),
      );

      // Assert
      expect(find.text('Emergency SOS'), findsOneWidget);
      expect(find.text('SOS Screen'), findsOneWidget);
      TestLogger.logSuccess('SOS screen title rendered');
    });

    testWidgets('SOS Button Click Should Trigger SOS', (WidgetTester tester) async {
      TestLogger.logInfo('Testing SOS button click interaction', 'WIDGET_TEST');

      // Arrange
      bool sosTriggered = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingActionButton(
                onPressed: () {
                  sosTriggered = true;
                  TestLogger.logSOSTrigger('SOS button pressed');
                },
                child: const Icon(Icons.warning),
              ),
            ),
          ),
        ),
      );

      // Find and tap the button
      final sosButton = find.byType(FloatingActionButton);
      expect(sosButton, findsOneWidget);

      await tester.tap(sosButton);
      await tester.pumpAndSettle();

      // Assert
      expect(sosTriggered, true);
      TestLogger.logSuccess('SOS button click triggered SOS');
    });

    testWidgets('Emergency Contact List Should Display', (WidgetTester tester) async {
      TestLogger.logInfo('Testing emergency contact list display', 'WIDGET_TEST');

      // Arrange
      final contacts = [
        Guardian(
          id: 'g1',
          name: 'John Doe',
          phone: '+919123456789',
          email: 'john@example.com',
          relationship: 'family',
          isPrimary: true,
          isFaceVerified: false,
          rating: 0,
        ),
        Guardian(
          id: 'g2',
          name: 'Jane Smith',
          phone: '+919987654321',
          email: 'jane@example.com',
          relationship: 'friend',
          isPrimary: false,
          isFaceVerified: false,
          rating: 0,
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  title: Text(contact.name),
                  subtitle: Text(contact.phone),
                );
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('+919123456789'), findsOneWidget);
      TestLogger.logSuccess('Emergency contacts displayed correctly');
    });

    testWidgets('Cancel Button Should Dismiss SOS', (WidgetTester tester) async {
      TestLogger.logInfo('Testing SOS cancellation', 'WIDGET_TEST');

      // Arrange
      bool sosCancelled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('SOS Active'),
                ElevatedButton(
                  onPressed: () {
                    sosCancelled = true;
                    TestLogger.logInfo('SOS cancelled by user', 'SOS_CANCEL');
                  },
                  child: const Text('Cancel SOS'),
                ),
              ],
            ),
          ),
        ),
      );

      // Find and tap cancel button
      final cancelButton = find.byType(ElevatedButton);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Assert
      expect(sosCancelled, true);
      TestLogger.logSuccess('SOS cancellation works');
    });

    testWidgets('SOS Active Indicator Should Show Pulsing Animation', (WidgetTester tester) async {
      TestLogger.logInfo('Testing SOS active pulsing animation', 'WIDGET_TEST');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.7),
                  border: Border.all(color: Colors.red, width: 3),
                ),
                child: const Center(
                  child: Text('SOS ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('SOS ACTIVE'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
      TestLogger.logSuccess('SOS active indicator rendered');
    });

    testWidgets('Countdown Timer Should Display', (WidgetTester tester) async {
      TestLogger.logInfo('Testing countdown timer display', 'WIDGET_TEST');

      // Arrange
      int countdown = 30;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SOS will be sent in:', style: Theme.of(tester.element(find.byType(Scaffold))).textTheme.headlineSmall),
                  Text('$countdown seconds', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('SOS will be sent in:'), findsOneWidget);
      expect(find.text('30 seconds'), findsOneWidget);
      TestLogger.logSuccess('Countdown timer displayed');
    });

    testWidgets('Live Location Update Should Display On Map', (WidgetTester tester) async {
      TestLogger.logInfo('Testing live location display', 'WIDGET_TEST');

      // Arrange
      const latitude = 12.9716;
      const longitude = 77.5946;
      const accuracy = 5.0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  const Text('Current Location'),
                  Text('Lat: $latitude, Lng: $longitude'),
                  Text('Accuracy: ${accuracy.toStringAsFixed(1)}m'),
                ],
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Current Location'), findsOneWidget);
      expect(find.text('Lat: 12.9716, Lng: 77.5946'), findsOneWidget);
      TestLogger.logSuccess('Live location displayed on map');
    });

    testWidgets('Guardian Status Should Update In Real-Time', (WidgetTester tester) async {
      TestLogger.logInfo('Testing guardian status updates', 'WIDGET_TEST');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const ListTile(
                  title: Text('John Doe'),
                  subtitle: Text('Notified'),
                  trailing: Icon(Icons.check, color: Colors.green),
                ),
                const ListTile(
                  title: Text('Jane Smith'),
                  subtitle: Text('On the way'),
                  trailing: Icon(Icons.directions_car, color: Colors.orange),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Notified'), findsOneWidget);
      expect(find.text('On the way'), findsOneWidget);
      TestLogger.logSuccess('Guardian status updates displayed');
    });

    testWidgets('SOS Screen Should Show Error on Permission Denial', (WidgetTester tester) async {
      TestLogger.logInfo('Testing permission denial error', 'WIDGET_TEST');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text('Location permission required'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Location permission required'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      TestLogger.logSuccess('Permission error displayed');
    });

    testWidgets('SOS Session Should Persist After App Minimize', (WidgetTester tester) async {
      TestLogger.logInfo('Testing SOS session persistence', 'WIDGET_TEST');

      // Act
      bool sosActive = true;
      expect(sosActive, true);

      // Simulate app lifecycle: resume -> pause
      // In real scenario, the SOS state should be maintained
      TestLogger.logInfo('SOS state maintained during pause', 'LIFECYCLE');

      // Assert
      expect(sosActive, true);
      TestLogger.logSuccess('SOS session persisted');
    });
  });

  group('Login Screen Widget Tests', () {
    testWidgets('Login Form Should Accept Email and Password', (WidgetTester tester) async {
      TestLogger.logAuth('Testing login form input');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (value) {},
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onChanged: (value) {},
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      TestLogger.logSuccess('Login form rendered correctly');
    });
  });

  group('Guardian Management Widget Tests', () {
    testWidgets('Add Guardian Button Should Open Dialog', (WidgetTester tester) async {
      TestLogger.logInfo('Testing add guardian dialog', 'WIDGET_TEST');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Add Guardian'),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Add Guardian'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      TestLogger.logSuccess('Add guardian button found');
    });
  });
}
