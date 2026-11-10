import 'package:flutter/material.dart';

import 'package:app/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      primary: AppColors.brandPrimary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: 'Nunito',
  );
}
