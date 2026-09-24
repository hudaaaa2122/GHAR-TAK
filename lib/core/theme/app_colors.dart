import 'package:flutter/material.dart';

/// Design tokens aligned with website `globals.css` + `verticalTheme.ts`.
class AppColors {
  AppColors._();

  // ── Brand (website grocery primary) ──
  static const Color primaryTeal = Color(0xFF328FB8);
  static const Color primaryHover = Color(0xFF2A7DA2);
  static const Color primaryGreen = Color(0xFF2E9E54);
  static const Color primaryDarkBrand = Color(0xFF295F77);
  static const Color primaryMidGreen = Color(0xFF1B8A6E);

  /// Website `--brand-primary` / `--primary`.
  static const Color primary = Color(0xFF328FB8);
  static const Color primaryDark = Color(0xFF2A7DA2);
  static const Color primaryMid = Color(0xFF57A1C2);
  static const Color primarySoft = Color(0xFFD7EEF6);
  static const Color primarySoftAlt = Color(0xFFEEF7F8);
  static const Color logoBlue = primaryTeal;
  static const Color tealBright = Color(0xFF57A1C2);
  static const Color tealMid = Color(0xFF11788C);

  // ── Text (website profile / product neutrals) ──
  /// Call from [MaterialApp.builder] so text tokens follow light/dark mode.
  static Brightness _brightness = Brightness.light;

  static void bindBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get _isDark => _brightness == Brightness.dark;

  static const Color textPrimaryLight = Color(0xFF14181F);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryLight = Color(0xFF5C6675);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedLight = Color(0xFF8A93A3);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color textBodyLight = Color(0xFF3A4250);
  static const Color textBodyDark = Color(0xFFCBD5E1);

  /// Theme-aware — dark mode uses light text so copy stays readable.
  static Color get textPrimary =>
      _isDark ? textPrimaryDark : textPrimaryLight;
  static Color get textDark => textPrimary;
  static Color get textHeading => textPrimary;
  static Color get textBody => _isDark ? textBodyDark : textBodyLight;
  static Color get textSecondary =>
      _isDark ? textSecondaryDark : textSecondaryLight;
  static Color get textMuted => _isDark ? textMutedDark : textMutedLight;
  static Color get textHint => textMuted;
  static Color get textDisabled => textMuted;

  // ── Neutrals / surfaces ──
  static const Color gray700 = Color(0xFF3A4250);
  static const Color gray600 = Color(0xFF5C6675);
  static const Color gray500 = Color(0xFF8A93A3);
  static const Color gray300 = Color(0xFFC8CDD6);
  static const Color gray200 = Color(0xFFDCE0E6);
  static const Color gray150 = Color(0xFFE7EAEF);
  static const Color gray100 = Color(0xFFE7EAEF);
  static const Color gray75 = Color(0xFFEEF1F5);
  static const Color gray50 = Color(0xFFF0F2F5);
  static const Color gray25 = Color(0xFFF8FAFB);

  static const Color borderLightConst = Color(0xFFEEF1F5);
  static const Color borderDark = Color(0xFF243044);
  static const Color borderLightMode = Color(0xFFE7EAEF);
  static Color get border => _isDark ? borderDark : borderLightMode;
  static Color get borderLight => _isDark ? borderDark : borderLightConst;

  static const Color backgroundLight = Color(0xFFF7F8FA);
  static const Color backgroundDark = Color(0xFF0B1220);
  static Color get background => _isDark ? backgroundDark : backgroundLight;

  static const Color sectionBackgroundLight = Color(0xFFEEF1F5);
  static const Color sectionBackgroundDark = Color(0xFF1A2333);
  static Color get sectionBackground =>
      _isDark ? sectionBackgroundDark : sectionBackgroundLight;

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF151C2C);
  static Color get surface => _isDark ? surfaceDark : surfaceLight;
  static Color get surfaceOffWhite =>
      _isDark ? surfaceDark : const Color(0xFFF8FAFB);
  static const Color footerLight = textPrimaryLight;
  static Color get footer => textPrimary;

  static const Color inputFillLight = Color(0xFFF5F7FA);
  static const Color inputFillDark = Color(0xFF1A2333);
  static Color get inputFill => _isDark ? inputFillDark : inputFillLight;

  // ── Semantic ──
  static const Color success = Color(0xFF15824B);
  static const Color successLight = Color(0xFF34D399);
  static const Color successSoft = Color(0xFFE7F4EC);
  static const Color successText = Color(0xFF15824B);
  static const Color warning = Color(0xFF9A5800);
  static const Color warningSoft = Color(0xFFFFF4E5);
  static const Color error = Color(0xFFC0341F);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2A6FDB);
  static const Color infoBg = Color(0xFFE1F0F3);

  // Hero / announcement (website grocery)
  static const Color gradientStart = Color(0xFF328FB8);
  static const Color gradientMid = Color(0xFF57A1C2);
  static const Color gradientEnd = Color(0xFF295F77);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment(-0.8, -0.4),
    end: Alignment(0.9, 0.6),
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  /// Website cart / checkout / payment CTA:
  /// `linear-gradient(90deg, #14677d 0%, #1b8a6e 52%, #2e9e54 100%)`.
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF14677D), Color(0xFF1B8A6E), Color(0xFF2E9E54)],
    stops: [0.0, 0.52, 1.0],
  );

  /// Website confirm / track CTAs (`bg-[#11788c]`).
  static const Color checkoutConfirm = tealMid;

  static const LinearGradient announcementGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF295F77), Color(0xFF328FB8)],
  );

  // ── Category / vertical accents ──
  static const Color grocery = primary;
  static const Color pharmacyBg = Color(0xFFDCEFE9);
  static const Color pharmacyFg = Color(0xFF247B6A);
  static const Color bakeryBg = Color(0xFFFFE8CC);
  static const Color bakeryFg = Color(0xFFC2854D);
  static const Color businessBg = Color(0xFFDCE3F0);
  static const Color businessFg = Color(0xFF1E3A5F);

  static const Color brownDark = Color(0xFF331F0C);
  static const Color brown = Color(0xFF633E1C);
  static const Color brownWarm = Color(0xFF8C5837);
  static const Color brownGold = Color(0xFF9F6733);
  static const Color brownLight = Color(0xFFC2854D);

  static const Color orange = Color(0xFFF07A2E);
  static const Color orangeSoft = Color(0xFFFFF0E6);
  static const Color saleBadge = error;
  static const Color dealPill = Color(0xFFA6E7CB);
  static Color get chipBg => sectionBackground;

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;

  static const Color primarySoftLegacy = primarySoft;

  /// Soft retail card shadow matching website product cards.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF14181F).withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
}
