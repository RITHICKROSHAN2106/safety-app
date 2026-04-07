import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/theme/theme_cubit.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/gemini_assistant_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/revolutionary_features_screen.dart';

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({
    super.key,
    this.navigatorKey,
    this.launchFromWidgetPanic = false,
  });

  final GlobalKey<NavigatorState>? navigatorKey;
  final bool launchFromWidgetPanic;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Women Safety',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
              initialRoute: SplashScreen.routeName,
          routes: {
            SplashScreen.routeName: (_) => const SplashScreen(),
            LoginScreen.routeName: (_) => const LoginScreen(),
            HomeScreen.routeName: (_) => const HomeScreen(),
            SosScreen.routeName: (_) => const SosScreen(),
            MapScreen.routeName: (_) => const MapScreen(),
            GeminiAssistantScreen.routeName: (_) => const GeminiAssistantScreen(),
            ProfileScreen.routeName: (_) => const ProfileScreen(),
            SettingsScreen.routeName: (_) => const SettingsScreen(),
            RevolutionaryFeaturesScreen.routeName: (_) => const RevolutionaryFeaturesScreen(),
          },
        );
      },
    );
  }
}
