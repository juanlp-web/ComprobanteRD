import 'package:flutter/material.dart';

class AppTheme {
  static const Color defaultSeedColor = Color(0xFF2D6A4F);

  static const List<Color> seedPalette = [
    Color(0xFF2D6A4F),
    Color(0xFF0057B8),
    Color(0xFF0B4F6C),
    Color(0xFF0A9396),
    Color(0xFFDA291C),
    Color(0xFFD9A441),
    Color(0xFF7B2CBF),
    Color(0xFF264653),
    Color(0xFFF4A261),
    Color(0xFF3A0CA3),
  ];

  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      secondary: const Color(0xFFDA291C),
      tertiary: const Color(0xFFD9A441),
      surface: const Color(0xFFF5F6FA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      secondary: const Color(0xFFFFB4A4),
      tertiary: const Color(0xFFE8C171),
      surface: const Color(0xFF121826),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
