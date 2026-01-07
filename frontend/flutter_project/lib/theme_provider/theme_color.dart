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

/// Light Theme (Deep Ocean/Cream)
/// Designed for high legibility and a professional, calm aesthetic.
ThemeData buildLightTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    useMaterial3: true,

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: lightPrimary,
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      background: lightBackground,
      onBackground: Colors.black87,
      surface: Colors.white,
      onSurface: Colors.black87,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: lightBackground,

    // AppBar
    appBarTheme: const AppBarTheme(
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

    // Cards
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    //  Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: lightOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: lightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    //  Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightPrimary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
      space: 16,
    ),

    //Text
    textTheme: const TextTheme(
      bodyMedium:
          TextStyle(fontSize: 14, color: Colors.black87),
      titleLarge:
          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      labelLarge:
          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}

/// Dark Theme (Night Ocean/Ash)
/// Optimized for low-light environments and reduced eye strain.
ThemeData buildDarkTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    useMaterial3: true,

  
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkPrimary,
      primary: darkPrimary,
      onPrimary: Colors.white,
      background: darkBackground,
      onBackground: darkOnPrimary,
      surface: darkSurface,
      onSurface: darkOnPrimary,
      brightness: Brightness.dark,
    ),

    scaffoldBackgroundColor: darkBackground,
    canvasColor: darkSurface,

 
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkOnPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkOnPrimary,
      ),
    ),


    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

   
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),


    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      labelStyle: TextStyle(color: darkOnPrimary),
      hintStyle: TextStyle(color: darkOnPrimary.withOpacity(0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkPrimary, width: 1.5),
      ),
    ),

  
    popupMenuTheme: PopupMenuThemeData(
      color: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
