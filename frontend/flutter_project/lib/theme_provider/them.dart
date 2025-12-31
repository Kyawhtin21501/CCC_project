import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A ChangeNotifier that manages the application's visual theme (Light vs Dark).
/// It uses the 'Provider' pattern to notify the entire app when the theme changes
/// and persists the user's choice using local storage.
class ThemeProvider extends ChangeNotifier {
  
  /// Internal state for the current theme mode.
  /// Initialized to light, but updated immediately by [_loadTheme].
  ThemeMode _themeMode = ThemeMode.light;

  /// Public getter to allow the [MaterialApp] to access the current mode.
  ThemeMode get themeMode => _themeMode;

  /// Constructor: Automatically attempts to load the saved preference 
  /// from the device storage as soon as the provider is created.
  ThemeProvider() {
    _loadTheme();
  }

  /// PERSISTENCE: Loads the 'isDarkMode' boolean from SharedPreferences.
  /// This ensures that if the user chose Dark Mode yesterday, the app 
  /// starts in Dark Mode today.
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to false (Light Mode) if no preference has been saved yet.
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      
      // Notify all listening widgets (like MaterialApp) to rebuild with the loaded theme.
      notifyListeners();
    } catch (e) {
      // Fallback or error handling can be added here if storage fails.
      debugPrint('Error loading theme: $e');
    }
  }

  /// ACTION: Toggles the theme between Light and Dark.
  /// [isDark] - True for Dark Mode, False for Light Mode.
  Future<void> toggleTheme(bool isDark) async {
    // 1. Update the in-memory state.
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // 2. Trigger a UI rebuild across the entire application.
    notifyListeners();

    // 3. Save the choice to the device's physical storage.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  /// UTILITY: A simple boolean helper to check the current state 
  /// (Useful for Switch widgets or Icon changes).
  bool get isDarkMode => _themeMode == ThemeMode.dark;
}