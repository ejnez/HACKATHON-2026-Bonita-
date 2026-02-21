import 'package:flutter/material.dart';

// we can customize this file to change the theme accross the entire app
final ThemeData appTheme = ThemeData(
  useMaterial3: true,

  // 🌸 Color Scheme
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB39DDB),       // soft lavender/purple
    onPrimary: Colors.white,
    secondary: Color(0xFF8BC5A0),     // pastel green accent
    onSecondary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    background: Color(0xFFF9F7FF),    // very light lavender cream
    onBackground: Colors.black87,
    surface: Colors.white,
    onSurface: Colors.black87,
  ),

  scaffoldBackgroundColor: const Color(0xFFF9F7FF),

  // 🌸 App Bar
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Colors.black87,
  ),

  // 💜 Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFB39DDB), // lavender
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFB39DDB), // lavender
    foregroundColor: Colors.white,
  ),

  // 🌿 Input Fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFFB39DDB), // lavender focus
        width: 2,
      ),
    ),
  ),

  // 💜 Bottom Navigation Bar
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Color(0xFFB39DDB), // lavender
    unselectedItemColor: Colors.grey,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
  ),

  // 🌸 Text
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Colors.black87,
    ),
  ),
);