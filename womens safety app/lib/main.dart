/// Main entry point of Women Safety App
/// Initializes Firebase, registers services, and launches the app
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  await Firebase.initializeApp();

  // Initialize core services
  await NotificationService().initialize();
  await PermissionsService().requestInitialPermissions();

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
