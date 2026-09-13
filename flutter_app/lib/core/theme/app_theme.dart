import 'package:flutter/material.dart';

/// Mada Explorer visual identity: baobab bark / laterite earth tones with
/// accents of rainforest green and the red-white of the Malagasy flag.
class AppColors {
  AppColors._();
  static const baobab = Color(0xFF8B4A2B); // baobab bark brown
  static const laterite = Color(0xFFC1440E); // red earth of the Highlands
  static const forest = Color(0xFF1E5B3A); // rainforest green
  static const sunset = Color(0xFFF2A65A); // sunset over the Avenue of the Baobabs
  static const ocean = Color(0xFF13678A); // Nosy Be lagoon
  static const cream = Color(0xFFFBF3E7);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.laterite,
        primary: AppColors.laterite,
        secondary: AppColors.forest,
        tertiary: AppColors.sunset,
        surface: AppColors.cream,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.baobab,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.laterite,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
