import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Provider
/// Manages app theme (light/dark mode) with persistence
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  SharedPreferences? _prefs;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final isDark = _prefs?.getBool(_themeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await _prefs?.setBool(_themeKey, _themeMode == ThemeMode.dark);
    notifyListeners();
    print(
      '🎨 Theme changed to: ${_themeMode == ThemeMode.dark ? 'Dark' : 'Light'}',
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setBool(_themeKey, mode == ThemeMode.dark);
    notifyListeners();
  }
}
