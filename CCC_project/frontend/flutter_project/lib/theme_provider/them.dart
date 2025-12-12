import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A ChangeNotifier that handles light/dark theme switching and persistence.
class ThemeProvider extends ChangeNotifier {
  /// Current theme mode (light/dark/system)
  ThemeMode _themeMode = ThemeMode.light;

  /// Public getter for the current theme
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  /// Load the saved theme mode from SharedPreferences (runs at app startup)
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Toggle between light and dark themes, and persist the choice
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  /// Convenience helper (optional): returns `true` if current theme is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
