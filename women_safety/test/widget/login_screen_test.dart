import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:women_safety/bloc/auth/auth_cubit.dart';
import 'package:women_safety/screens/home_screen.dart';
import 'package:women_safety/screens/login_screen.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(const AuthState(initialized: true));
    whenListen(authCubit, Stream<AuthState>.fromIterable(const [AuthState(initialized: true)]));
  });

  Widget createWidgetUnderTest() {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        routes: {
          HomeScreen.routeName: (_) => const Scaffold(body: Text('Home')),
        },
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('Login screen renders essential fields', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Sign In'), findsWidgets);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('Login form validates empty input', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Switch to create account mode', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.widgetWithText(TextButton, 'Need an account? Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Full name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Confirm password'), findsOneWidget);
  });
}
