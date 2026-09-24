import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware semantic colors for light / dark mode.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.inputFill,
    required this.card,
    required this.section,
    required this.teal,
    required this.tealSoft,
  });

  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color inputFill;
  final Color card;
  final Color section;
  final Color teal;
  final Color tealSoft;

  /// Aliases used by info / account screens.
  Color get scaffoldBg => background;
  Color get cardBg => card;

  static const light = AppPalette(
    background: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    border: AppColors.borderLightMode,
    inputFill: AppColors.inputFillLight,
    card: AppColors.surfaceLight,
    section: AppColors.sectionBackgroundLight,
    teal: AppColors.primary,
    tealSoft: AppColors.primarySoft,
  );

  static const dark = AppPalette(
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    border: AppColors.borderDark,
    inputFill: AppColors.inputFillDark,
    card: AppColors.surfaceDark,
    section: AppColors.sectionBackgroundDark,
    teal: AppColors.primaryMid,
    tealSoft: Color(0xFF1A3344),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
