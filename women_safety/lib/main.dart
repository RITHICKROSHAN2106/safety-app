import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

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
import 'services/danger_zone_monitor_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final widgetPanic = await PanicWidgetService.checkPanicTrigger();
  final pendingTrigger = await ProtectionService.checkPendingSOS(clearOnRead: false);
  final launchFromWidget = widgetPanic != null || pendingTrigger == 'WIDGET';
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('⚠️  Please add google-services.json (Android) or GoogleService-Info.plist (iOS)');
  }

  if (launchFromWidget) {
    debugPrint('🚨 PANIC TRIGGERED FROM WIDGET! Launching SOS screen...');
  }

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
        launchFromWidgetPanic: launchFromWidget,
      ),
    ),
  );

  unawaited(_initializeServicesInBackground());
}

Future<void> _initializeServicesInBackground() async {
  try {
    await NotificationService.ensureInitialized();
  } catch (e) {
    debugPrint('⚠️ Notification initialization error: $e');
  }

  try {
    await PermissionsService.ensureNotifications();
  } catch (e) {
    debugPrint('⚠️ Notification permission setup error: $e');
  }

  try {
    await OfflineQueueService.initialize();
  } catch (e) {
    debugPrint('⚠️ Offline queue initialization error: $e');
  }

  try {
    await PanicWidgetService.initialize();
    debugPrint('✅ Panic widget initialized');
  } catch (e) {
    debugPrint('⚠️ Panic widget initialization error: $e');
  }

  try {
    await DangerZoneMonitorService.startMonitoring();
  } catch (e) {
    debugPrint('⚠️ Danger zone monitoring initialization error: $e');
  }

  debugPrint('✅ Background services initialized');
}

/// Backwards compatibility helpers while the rest of the app migrates.
Future<void> setupGlobalSOSListeners() => GlobalSOSManager.setup();

void stopGlobalSOSListeners() => GlobalSOSManager.teardown();
