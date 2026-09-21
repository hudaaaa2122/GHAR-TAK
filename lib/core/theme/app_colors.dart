import 'package:flutter/material.dart';

/// Gher Tak design tokens — aligned with Figma → CSS `:root` variables.
class AppColors {
  AppColors._();

  // ── Brand ──
  static const Color primaryTeal = Color(0xFF328FB8);
  static const Color primaryGreen = Color(0xFF2E9E54);
  static const Color primaryDarkBrand = Color(0xFF14677D);
  static const Color primaryMidGreen = Color(0xFF1B8A6E);

  /// App accent / CTA teal (`--color-teal`).
  static const Color primary = Color(0xFF0E7C8C);
  static const Color primaryDark = Color(0xFF0C6376);
  static const Color primaryMid = primaryTeal;
  static const Color primarySoft = Color(0xFFE1F0F3); // --color-bg-teal-light
  static const Color primarySoftAlt = Color(0xFFDCEFE9); // --color-bg-green-light
  static const Color logoBlue = primaryTeal;
  static const Color tealBright = Color(0xFF46B0C9);
  static const Color tealMid = Color(0xFF11788C);

  // ── Text ──
  static const Color textPrimary = Color(0xFF0B0F16);
  static const Color textDark = Color(0xFF101622);
  static const Color textHeading = Color(0xFF14181F);
  static const Color textBody = Color(0xFF1B2333);
  static const Color textSecondary = Color(0xFF5A6672); // --color-text-light
  static const Color textMuted = Color(0xFF7A8496); // --color-text-placeholder
  static const Color textHint = Color(0xFF9AA1AB);
  static const Color textDisabled = Color(0xFF8A93A3);

  // ── Neutrals / surfaces ──
  static const Color gray700 = Color(0xFF3A4250);
  static const Color gray600 = Color(0xFF5A6672);
  static const Color gray500 = Color(0xFF7A8496);
  static const Color gray300 = Color(0xFF94A3B8);
  static const Color gray200 = Color(0xFFC8CDD6);
  static const Color gray150 = Color(0xFFDCE0E6);
  static const Color gray100 = Color(0xFFE7EAEF);
  static const Color gray75 = Color(0xFFEEF1F4);
  static const Color gray50 = Color(0xFFF0F2F5);
  static const Color gray25 = Color(0xFFF5F6F8);

  static const Color border = Color(0xFFE7EAEF); // gray-100
  static const Color borderLight = Color(0xFFF0F2F5); // gray-50
  static const Color background = Color(0xFFF5F7FA); // --color-bg-light
  static const Color sectionBackground = Color(0xFFEEF2F6); // --color-bg-subtle
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceOffWhite = Color(0xFFF8FAFB);
  static const Color footer = textDark;
  static const Color inputFill = Color(0xFFF5F7FA);

  // ── Semantic ──
  static const Color success = Color(0xFF15824B);
  static const Color successLight = Color(0xFF34D399);
  static const Color successSoft = Color(0xFFE7F4EC); // --color-success-bg
  static const Color successText = Color(0xFF15824B);
  static const Color warning = Color(0xFF9A5800);
  static const Color warningSoft = Color(0xFFFFF4E5);
  static const Color error = Color(0xFFC0341F);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2A6FDB);
  static const Color infoBg = Color(0xFFE1F0F3);

  // —— Header / CTA gradient (teal family — do not mix green into brand chrome) ——
  static const Color gradientStart = Color(0xFF328FB8);
  static const Color gradientMid = Color(0xFF57A1C2);
  static const Color gradientEnd = Color(0xFF2A637C);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment(-0.8, -0.4),
    end: Alignment(0.9, 0.6),
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientStart, gradientEnd],
  );

  // ── Category / vertical accents ──
  static const Color grocery = primary;
  static const Color pharmacyBg = infoBg;
  static const Color pharmacyFg = primaryTeal;
  static const Color bakeryBg = Color(0xFFEDCEB1); // --color-brown-bg
  static const Color bakeryFg = Color(0xFF633E1C); // --color-brown
  static const Color businessBg = Color(0xFFDCEFE9);
  static const Color businessFg = Color(0xFF247B6A); // --color-green-sage

  static const Color brownDark = Color(0xFF331F0C);
  static const Color brown = Color(0xFF633E1C);
  static const Color brownWarm = Color(0xFF8C5837);
  static const Color brownGold = Color(0xFF9F6733);
  static const Color brownLight = Color(0xFFC2854D);

  static const Color orange = Color(0xFFF07A2E);
  static const Color orangeSoft = Color(0xFFFFF0E6);
  static const Color saleBadge = error;
  static const Color dealPill = Color(0xFFA6E7CB);
  static const Color chipBg = sectionBackground;

  // Spacing / radius helpers (logical px matching tokens)
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

  // Legacy aliases
  static const Color primarySoftLegacy = primarySoft;
}
