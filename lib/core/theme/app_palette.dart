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
    background: AppColors.background,
    surface: AppColors.surface,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
    inputFill: AppColors.inputFill,
    card: AppColors.surface,
    section: AppColors.sectionBackground,
    teal: AppColors.primary,
    tealSoft: AppColors.primarySoft,
  );

  static const dark = AppPalette(
    background: Color(0xFF0B1220),
    surface: Color(0xFF151C2C),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    border: Color(0xFF243044),
    inputFill: Color(0xFF1A2333),
    card: Color(0xFF151C2C),
    section: Color(0xFF1A2333),
    teal: AppColors.primaryMid,
    tealSoft: Color(0xFF1A3344),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
