import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:women_safety/bloc/auth/auth_cubit.dart';
import 'package:women_safety/bloc/location/location_cubit.dart';
import 'package:women_safety/screens/home_screen.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}
class MockLocationCubit extends MockCubit<LocationState> implements LocationCubit {}

void main() {
  late MockAuthCubit authCubit;
  late MockLocationCubit locationCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    locationCubit = MockLocationCubit();

    when(() => authCubit.state).thenReturn(const AuthState(initialized: true));
    when(() => locationCubit.state).thenReturn(
      LocationState(
        serviceEnabled: true,
        permission: LocationPermission.whileInUse,
        position: Position(
          longitude: 77.5946,
          latitude: 12.9716,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      ),
    );

    whenListen(authCubit, const Stream<AuthState>.empty());
    whenListen(locationCubit, const Stream<LocationState>.empty());
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<LocationCubit>.value(value: locationCubit),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets('Home screen renders title and nav destinations', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Women Safety'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Home screen switches tab on tap', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();

    expect(find.text('Women Safety'), findsOneWidget);
  });
}
