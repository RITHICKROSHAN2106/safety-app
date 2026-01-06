/// Theme Cubit
/// Manages app theme (light/dark mode)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  // Load saved theme
  void _loadTheme() {
    final themeModeString = _prefs.getString(_themeKey);
    if (themeModeString != null) {
      final themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
      emit(themeMode);
    }
  }

  // Set theme
  Future<void> setTheme(ThemeMode themeMode) async {
    await _prefs.setString(_themeKey, themeMode.toString());
    emit(themeMode);
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newTheme);
  }

  // Set light theme
  Future<void> setLightTheme() async {
    await setTheme(ThemeMode.light);
  }

  // Set dark theme
  Future<void> setDarkTheme() async {
    await setTheme(ThemeMode.dark);
  }

  // Set system theme
  Future<void> setSystemTheme() async {
    await setTheme(ThemeMode.system);
  }
}
