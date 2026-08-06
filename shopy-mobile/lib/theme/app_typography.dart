import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text theme dasar Shopy, pakai Poppins di seluruh skala Material 3.
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return GoogleFonts.poppinsTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }
}
