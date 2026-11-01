import 'package:flutter/material.dart';

class AppTheme {
  // --- Google Stitch Design System: Abyssal Luminescence ---

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFFFFFFF);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFF7F3FF);
  static const Color surfaceContainerLow = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFF7F3FF);

  // Content / On-Surface Colors
  static const Color onSurface = Color(0xFF32145A);
  static const Color onSurfaceVariant = Color(0xFF6B5B85);
  static const Color inverseSurface = Color(0xFF32145A);
  static const Color inverseOnSurface = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFDDD0F7);
  static const Color outlineVariant = Color(0xFFDDD0F7);

  // Primary Bioluminescent Tones -> Purple + White Theme
  static const Color primary = Color(0xFF32145A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF6D28D9);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFF6D28D9);
  static const Color primaryFixedDim = Color(0xFF6D28D9);
  static const Color onPrimaryFixed = Color(0xFFFFFFFF);
  static const Color onPrimaryFixedVariant = Color(0xFF6B5B85);

  // Secondary Marine Current Blue Tones -> Muted Lavender / Secondary Text
  static const Color secondary = Color(0xFF6B5B85);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF6D28D9);
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);
  static const Color secondaryFixed = Color(0xFFF7F3FF);
  static const Color secondaryFixedDim = Color(0xFF6B5B85);
  static const Color onSecondaryFixed = Color(0xFF32145A);

  // Tertiary Sunken Gold / Coral Tones -> Soft Lavender Accents
  static const Color tertiary = Color(0xFFEDE5FF);
  static const Color onTertiary = Color(0xFF32145A);
  static const Color tertiaryContainer = Color(0xFFEDE5FF);
  static const Color onTertiaryContainer = Color(0xFF32145A);
  static const Color tertiaryFixed = Color(0xFFEDE5FF);
  static const Color tertiaryFixedDim = Color(0xFF6D28D9);

  // Functional Status Roles
  static const Color success = Color(0xFF2CE8B3);
  static const Color warning = Color(0xFFFFB443);
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Ambient Glow Tint
  static const Color surfaceTint = Color(0xFF6D28D9);

  // --- Google Stitch Design System: AquaSort Light Theme (Purple + White) ---
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFFF7F3FF);
  static const Color primaryPurple = Color(0xFF5B21B6);
  static const Color strongPurple = Color(0xFF6D28D9);
  static const Color secondaryPurple = Color(0xFFA78BFA);
  static const Color lightPurpleSurface = Color(0xFFEDE5FF);
  static const Color mainText = Color(0xFF32145A);
  static const Color secondaryText = Color(0xFF6B5B85);
  static const Color lightBorder = Color(0xFFDDD0F7);

  static const RadialGradient lightRadialCanvas = RadialGradient(
    center: Alignment(0.0, -1.0),
    radius: 1.25,
    colors: [Color(0xFFF7F3FF), Color(0xFFFFFFFF)],
    stops: [0.0, 0.75],
  );

  static const LinearGradient purpleButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5B21B6), Color(0xFF5B21B6)],
  );

  // Legacy Theme Color Palette Aliases (preserved for existing code & tests)
  static const Color deepNavy = surface;
  static const Color deepNavyEnd = Color(0xFFFFFFFF);
  static const Color primaryBlue = Color(0xFF5B21B6);
  static const Color aquaGlow = primaryContainer;
  static const Color iceWhite = Color(0xFF32145A);
  static const Color glassSurface = Color(0x1A6D28D9);
  static const Color glassBorder = Color(0xFFDDD0F7);

  // Puzzle Liquid Colors for Water-Drop Layers
  static const Color liquidCyan = Color(0xFF00E5FF);
  static const Color liquidPurple = Color(0xFF9D4EDD);
  static const Color liquidOrange = Color(0xFFFF9100);
  static const Color liquidEmerald = Color(0xFF00E676);

  // Stitch Gradients
  static const RadialGradient radialCanvas = RadialGradient(
    center: Alignment(0.0, -1.2),
    radius: 1.35,
    colors: [Color(0xFFF7F3FF), Color(0xFFFFFFFF)],
    stops: [0.0, 0.75],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5B21B6), Color(0xFF5B21B6)],
  );

  static const LinearGradient aquaBarGradient = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
      ),
      fontFamily: 'Outfit',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.8,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.28,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: 0.18,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          letterSpacing: 0.14,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          letterSpacing: 0.24,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: 0.56,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onSurfaceVariant,
          letterSpacing: 0.72,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        onPrimary: lightBackground,
        primaryContainer: strongPurple,
        onPrimaryContainer: lightBackground,
        secondary: secondaryPurple,
        onSecondary: lightBackground,
        secondaryContainer: lightPurpleSurface,
        onSecondaryContainer: mainText,
        tertiary: lightPurpleSurface,
        onTertiary: mainText,
        surface: lightBackground,
        onSurface: mainText,
        onSurfaceVariant: secondaryText,
        outline: lightBorder,
        outlineVariant: lightBorder,
      ),
      fontFamily: 'Outfit',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: mainText,
          letterSpacing: -0.8,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: mainText,
          letterSpacing: -0.28,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: mainText,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: mainText,
          letterSpacing: 0.18,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: mainText,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: secondaryText,
          letterSpacing: 0.14,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondaryText,
          letterSpacing: 0.24,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: mainText,
          letterSpacing: 0.56,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondaryText,
          letterSpacing: 0.72,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: secondaryText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
