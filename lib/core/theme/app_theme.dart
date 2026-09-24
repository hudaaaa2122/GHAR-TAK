import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.family,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
    );
    return _finish(
      base,
      AppColors.textPrimaryLight,
      AppColors.surfaceLight,
      AppColors.borderLightMode,
      AppColors.inputFillLight,
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppFonts.family,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primaryMid,
        surface: const Color(0xFF151C2C),
        brightness: Brightness.dark,
      ),
    );
    return _finish(
      base,
      const Color(0xFFF1F5F9),
      const Color(0xFF151C2C),
      const Color(0xFF243044),
      const Color(0xFF1A2333),
    );
  }

  static ThemeData _finish(
    ThemeData base,
    Color text,
    Color surface,
    Color border,
    Color inputFill,
  ) {
    final manrope = AppFonts.textTheme(base.textTheme, color: text);
    return base.copyWith(
      textTheme: manrope,
      primaryTextTheme: manrope,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.style(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: text,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
          ),
          textStyle: AppFonts.style(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
          ),
          textStyle: AppFonts.style(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tealMid,
          backgroundColor: AppColors.primarySoftAlt,
          side: const BorderSide(color: AppColors.tealMid),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
          ),
          textStyle: AppFonts.style(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(height: 0, fontSize: 0),
        hintStyle: AppFonts.style(
          color: text.withValues(alpha: 0.45),
          fontSize: AppFonts.body,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: AppFonts.style(
          fontSize: AppFonts.xs,
          fontWeight: FontWeight.w700,
          color: text.withValues(alpha: 0.7),
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStatePropertyAll(
          AppFonts.style(
            fontWeight: FontWeight.w600,
            fontSize: AppFonts.sm,
            color: text,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppFonts.style(
          fontWeight: FontWeight.w600,
          fontSize: AppFonts.bodyMd,
          color: text,
        ),
        subtitleTextStyle: AppFonts.style(
          fontWeight: FontWeight.w500,
          fontSize: AppFonts.smPlus,
          color: text.withValues(alpha: 0.65),
        ),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: AppFonts.style(
          fontWeight: FontWeight.w800,
          fontSize: AppFonts.titleLg,
          color: text,
        ),
        contentTextStyle: AppFonts.style(
          fontWeight: FontWeight.w500,
          fontSize: AppFonts.body,
          color: text,
          height: 1.45,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: AppFonts.style(
          fontWeight: FontWeight.w600,
          fontSize: AppFonts.bodySm,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
