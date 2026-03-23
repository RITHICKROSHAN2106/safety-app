import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'bloc/theme/theme_cubit.dart';
import 'bloc/auth/auth_cubit.dart';
import 'bloc/location/location_cubit.dart';
import 'bloc/sos/sos_cubit.dart';
import 'services/global_sos_manager.dart';
import 'services/notification_service.dart';
import 'services/permissions_service.dart';
import 'services/offline_queue_service.dart';
import 'services/protection_service.dart';
import 'services/panic_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('⚠️  Please add google-services.json (Android) or GoogleService-Info.plist (iOS)');
  }

  // Initialize services
  await NotificationService.ensureInitialized();
  await PermissionsService.ensureNotifications();
  await OfflineQueueService.initialize();
  
  // Initialize panic widget
  try {
    await PanicWidgetService.initialize();
    debugPrint('✅ Panic widget initialized');
  } catch (e) {
    debugPrint('⚠️ Panic widget initialization error: $e');
  }
  
  // Check for pending background SOS triggers
  final pendingTrigger = await ProtectionService.checkPendingSOS();
  if (pendingTrigger != null) {
    debugPrint('⚠️ Found pending SOS trigger from background: $pendingTrigger');
  }
  
  // Check for widget panic trigger
  final widgetPanic = await PanicWidgetService.checkPanicTrigger();
  if (widgetPanic != null) {
    debugPrint('🚨 PANIC TRIGGERED FROM WIDGET!');
  }
  
  debugPrint('✅ Services initialized - App ready to launch');

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => LocationCubit()..init()),
        BlocProvider(create: (_) => SosCubit()),
      ],
      child: WomenSafetyApp(
        navigatorKey: GlobalSOSManager.navigatorKey,
      ),
    ),
  );
}

/// Backwards compatibility helpers while the rest of the app migrates.
Future<void> setupGlobalSOSListeners() => GlobalSOSManager.setup();

void stopGlobalSOSListeners() => GlobalSOSManager.teardown();
