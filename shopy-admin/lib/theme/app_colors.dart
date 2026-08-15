import 'package:flutter/material.dart';

/// Palet warna dasar Shopy. Primary oranye (#FF6B35) sesuai TASKS.md Fase 0.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFF6B35);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF2B2D42);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color divider = Color(0xFFE0E0E0);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    surface: surface,
    onSurface: textPrimary,
    error: error,
    onError: onPrimary,
  );
}
