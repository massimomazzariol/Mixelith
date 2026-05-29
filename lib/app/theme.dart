import 'package:flutter/material.dart';

class MixelithColors {
  const MixelithColors._();

  static const background = Color(0xFF0D0B10);
  static const backgroundDeep = Color(0xFF070509);
  static const surface = Color(0xFF17141C);
  static const surfaceElevated = Color(0xFF201A26);
  static const textPrimary = Color(0xFFF2F2F2);
  static const textSecondary = Color(0xFFA8A8A8);
  static const orange = Color(0xFFFF5A1F);
  static const red = Color(0xFFFF2D55);
  static const yellow = Color(0xFFFFC247);
  static const magenta = Color(0xFFD946EF);
  static const cyan = orange;
  static const violet = red;
  static const danger = Color(0xFFFF6B6B);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, red, yellow],
  );

  static const hotGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, magenta, orange],
  );
}

ThemeData buildMixelithTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: MixelithColors.orange,
        brightness: Brightness.dark,
      ).copyWith(
        surface: MixelithColors.surface,
        surfaceContainerHighest: MixelithColors.surfaceElevated,
        primary: MixelithColors.orange,
        secondary: MixelithColors.red,
        tertiary: MixelithColors.yellow,
        error: MixelithColors.danger,
        onSurface: MixelithColors.textPrimary,
        onSurfaceVariant: MixelithColors.textSecondary,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MixelithColors.background,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: MixelithColors.background,
      foregroundColor: MixelithColors.textPrimary,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: MixelithColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: MixelithColors.textPrimary,
        fontSize: 42,
        fontWeight: FontWeight.w800,
        height: 1.02,
      ),
      headlineSmall: TextStyle(
        color: MixelithColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
      titleMedium: TextStyle(
        color: MixelithColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: MixelithColors.textPrimary,
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: MixelithColors.textSecondary,
        fontSize: 14,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        color: MixelithColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: const Color(0xFF05070D),
        backgroundColor: MixelithColors.cyan,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: MixelithColors.orange,
      inactiveTrackColor: MixelithColors.surfaceElevated,
      thumbColor: MixelithColors.yellow,
      overlayColor: MixelithColors.orange.withValues(alpha: 0.16),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: MixelithColors.textPrimary,
        backgroundColor: MixelithColors.surface,
        shape: const CircleBorder(),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: MixelithColors.surfaceElevated,
      contentTextStyle: const TextStyle(color: MixelithColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
