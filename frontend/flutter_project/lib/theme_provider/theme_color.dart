import 'package:flutter/material.dart';

// --- Custom Color Definitions ---
// Light Mode Colors
const Color lightPrimary = Color(0xFF0B4C6E); // Deep Ocean
const Color lightOnPrimary = Color(0xFFF8F4E3); // Cream
const Color lightBackground = Color(0xFFF9F9F9); // Light Background

// Dark Mode Colors
const Color darkPrimary = Color(0xFF1E3F66); // Night Ocean (A deep, elegant blue)
const Color darkOnPrimary = Color(0xFFDDE0E3); // Ash (Off-white for contrast)
const Color darkBackground = Color(0xFF121212); // True black/very dark grey for background
const Color darkSurface = Color(0xFF1E1E1E); // Slightly lighter dark surface for cards/inputs

/// 💡 Light Theme (Deep Ocean/Cream)
ThemeData buildLightTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    // 1. ColorScheme: Defines all foundational colors
    colorScheme: ColorScheme.fromSeed(
      seedColor: lightPrimary,
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      surface: Colors.white,
      onSurface: Colors.black87,
      background: lightBackground,
      brightness: Brightness.light,
    ),
    
    // 2. Scaffold Background
    scaffoldBackgroundColor: lightBackground,

    // 3. AppBar Theme (Used for CustomMenuBar background)
    appBarTheme: AppBarTheme(
      backgroundColor: lightPrimary,
      foregroundColor: lightOnPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightOnPrimary,
      ),
    ),
    
    // 4. Card Theme
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    
    // 5. Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: lightOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    
    // 6. Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: lightPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
    ),
    
    // 7. Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none), // Start with no border for a minimal look
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    
    // 8. Divider Theme
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
      space: 16,
    ),
    
    // 9. Text Theme
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
    ),
  );
}
ThemeData buildDarkTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    // ... existing colorScheme
    
    // Fix for Dropdown Menus and Dialogs
    canvasColor: darkSurface, 
    
    // Ensure the dropdown background is distinct from the card
    popupMenuTheme: PopupMenuThemeData(
      color: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      labelStyle: const TextStyle(color: darkOnPrimary), // Fixes label visibility
      hintStyle: TextStyle(color: darkOnPrimary.withOpacity(0.5)),
      // ... existing borders
    ),

    // Add this to ensure the "Save" button text is always legible
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkPrimary,
      primary: darkPrimary,
      onPrimary: Colors.white, // Pure white for button text in dark mode
      surface: darkSurface,
      onSurface: darkOnPrimary,
      background: darkBackground,
      brightness: Brightness.dark,
    ),
  );
}