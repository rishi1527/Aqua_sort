import 'package:flutter/material.dart';

class AppTheme {
  // Theme Color Palette
  static const Color deepNavy = Color(0xFF071A33);
  static const Color deepNavyEnd = Color(0xFF030D1B);
  static const Color primaryBlue = Color(0xFF087ECA);
  static const Color aquaGlow = Color(0xFF38D9FF);
  static const Color iceWhite = Color(0xFFEAF7FF);
  static const Color glassSurface = Color(0x1A38D9FF);
  static const Color glassBorder = Color(0x3338D9FF);

  // Puzzle Liquid Colors for Water-Drop Layers
  static const Color liquidCyan = Color(0xFF00E5FF);
  static const Color liquidPurple = Color(0xFF9D4EDD);
  static const Color liquidOrange = Color(0xFFFF9100);
  static const Color liquidEmerald = Color(0xFF00E676);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepNavy,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: aquaGlow,
        surface: deepNavy,
        onSurface: iceWhite,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: iceWhite,
          letterSpacing: 1.2,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xB3EAF7FF),
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
