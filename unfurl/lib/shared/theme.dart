import 'package:flutter/material.dart';

const Color blossomPink = Color(0xFFFF6FAE);
const Color petalPeach = Color(0xFFFFE0CC);
const Color roseCream = Color(0xFFFFF5F7);
const Color sageGreen = Color(0xFF6FAF98);
const Color cocoaText = Color(0xFF4E3344);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Trebuchet MS',
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: blossomPink,
    onPrimary: Colors.white,
    secondary: sageGreen,
    onSecondary: Colors.white,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: roseCream,
    onSurface: cocoaText,
  ),
  scaffoldBackgroundColor: roseCream,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Colors.transparent,
    foregroundColor: cocoaText,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    color: Colors.white.withValues(alpha: 0.9),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: blossomPink,
      foregroundColor: Colors.white,
      shadowColor: blossomPink.withValues(alpha: 0.25),
      elevation: 3,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: blossomPink,
    foregroundColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Color(0xFFA27B90)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: blossomPink.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: blossomPink.withValues(alpha: 0.18)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: blossomPink, width: 1.8),
    ),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: cocoaText,
      letterSpacing: 0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: cocoaText,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: cocoaText,
      height: 1.35,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: cocoaText,
      height: 1.35,
    ),
  ),
);

const LinearGradient blossomBackground = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    roseCream,
    petalPeach,
    Color(0xFFFFE8F1),
  ],
);

