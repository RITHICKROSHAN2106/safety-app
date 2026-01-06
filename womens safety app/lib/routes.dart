/// Application Routes Configuration
/// Centralizes navigation and route management
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/map_screen.dart';
import 'screens/guardian_management_screen.dart';
import 'screens/revolutionary_features_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String sos = '/sos';
  static const String map = '/map';
  static const String guardians = '/guardians';
  static const String revolutionaryFeatures = '/revolutionary-features';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case sos:
        return MaterialPageRoute(builder: (_) => const SosScreen());

      case map:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MapScreen(
            latitude: args?['latitude'] as double?,
            longitude: args?['longitude'] as double?,
          ),
        );

      case guardians:
        return MaterialPageRoute(
          builder: (_) => const GuardianManagementScreen(),
        );

      case revolutionaryFeatures:
        return MaterialPageRoute(
          builder: (_) => const RevolutionaryFeaturesScreen(),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
