/// Main entry point of Women Safety App
/// Initializes Firebase, registers services, and launches the app
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/permissions_service.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/theme_cubit.dart';
import 'cubits/sos_cubit.dart';
import 'cubits/location_cubit.dart';
import 'cubits/guardian_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize core services that depend on Firebase
    await NotificationService().initialize();
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase for now (web platform)
  }

  // Initialize permissions
  try {
    await PermissionsService().requestInitialPermissions();
  } catch (e) {
    print('Permissions request failed: $e');
  }

  // Get shared preferences instance
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => ThemeCubit(prefs)),
        BlocProvider(create: (context) => SosCubit()),
        BlocProvider(create: (context) => LocationCubit()),
        BlocProvider(create: (context) => GuardianCubit()),
      ],
      child: const WomenSafetyApp(),
    ),
  );
}
