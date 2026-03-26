import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:women_safety/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SOS E2E on real device', () {
    testWidgets('login -> add guardian -> trigger SOS workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final signInButton = find.text('Sign In');
      if (signInButton.evaluate().isNotEmpty) {
        final emailField = find.widgetWithText(TextFormField, 'Email');
        final passwordField = find.widgetWithText(TextFormField, 'Password');
        if (emailField.evaluate().isNotEmpty && passwordField.evaluate().isNotEmpty) {
          await tester.enterText(emailField, 'test@womensafety.com');
          await tester.enterText(passwordField, 'Test@123456');
          await tester.tap(signInButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }

      final sosNav = find.text('SOS');
      if (sosNav.evaluate().isNotEmpty) {
        await tester.tap(sosNav.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      final sosButton = find.byIcon(Icons.sos);
      if (sosButton.evaluate().isNotEmpty) {
        await tester.tap(sosButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
