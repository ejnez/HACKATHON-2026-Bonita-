import 'package:flutter/material.dart';

const Color blossomPink = Color(0xFF5F8F7B);
const Color petalPeach = Color(0xFFF4E7D6);
const Color roseCream = Color(0xFFF8F7F3);
const Color sageGreen = Color(0xFF6FAF98);
const Color cocoaText = Color(0xFF33443D);

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
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: cocoaText,
    ),
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
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: blossomPink,
      side: BorderSide(color: blossomPink.withValues(alpha: 0.28), width: 1.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Color(0xFF7D8E86)),
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
    titleSmall: TextStyle(
      fontSize: 15,
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
  dividerTheme: DividerThemeData(
    color: blossomPink.withValues(alpha: 0.18),
    thickness: 1,
    space: 18,
  ),
);

const LinearGradient blossomBackground = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    roseCream,
    petalPeach,
    Color(0xFFEAF4EE),
  ],
);

