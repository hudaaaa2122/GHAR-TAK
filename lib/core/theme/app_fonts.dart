import 'package:flutter/material.dart';

/// Website font stack — Manrope (bundled, matches `next/font/google` Manrope).
///
/// Size tokens mirror common website classes:
/// `text-[11|12|12.5|13|13.5|14|15|16|18|22|24|26|28]`.
class AppFonts {
  AppFonts._();

  static const String family = 'Manrope';

  // ── Website type scale (px) ──────────────────────────────────────────────
  static const double xs = 11; // captions / badges
  static const double sm = 12; // muted meta
  static const double smPlus = 12.5; // FreeDeliveryBar / compact body
  static const double bodySm = 13; // secondary rows
  static const double body = 13.5; // summary labels / inputs (website default)
  static const double bodyMd = 14; // primary body / buttons
  static const double titleSm = 15; // section titles / “Total”
  static const double title = 16; // card titles
  static const double titleLg = 18; // screen headers
  static const double displaySm = 22; // order totals
  static const double display = 24; // success / hero titles
  static const double displayLg = 26;
  static const double displayXl = 28;

  static TextStyle style({
    FontWeight fontWeight = FontWeight.w400,
    double fontSize = body,
    Color? color,
    double height = 1.35,
    double letterSpacing = 0,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: family,
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      // Keep paint metrics close to website Manrope rendering.
      fontFamilyFallback: const ['Manrope', 'sans-serif'],
    );
  }

  /// Caption / chip — website `text-[11px]`.
  static TextStyle caption({
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) =>
      style(fontWeight: fontWeight, fontSize: xs, color: color, height: 1.25);

  /// Muted meta — website `text-[12px]`.
  static TextStyle meta({
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) =>
      style(fontWeight: fontWeight, fontSize: sm, color: color, height: 1.3);

  /// Compact body — website `text-[12.5px]` / `text-[13px]`.
  static TextStyle compact({
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double fontSize = smPlus,
  }) =>
      style(
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
        height: 1.25,
      );

  /// Default UI body — website `text-[13.5px]`.
  static TextStyle bodyText({
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) =>
      style(
        fontWeight: fontWeight,
        fontSize: body,
        color: color,
        height: 1.35,
      );

  /// Primary readable body — website `text-[14px]`.
  static TextStyle bodyPrimary({
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) =>
      style(
        fontWeight: fontWeight,
        fontSize: bodyMd,
        color: color,
        height: 1.45,
      );

  /// Section / row title — website `text-[15px]`–`text-[16px]`.
  static TextStyle titleText({
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double fontSize = title,
  }) =>
      style(
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
        height: 1.3,
      );

  /// Screen header — website `text-[18px]` extrabold.
  static TextStyle screenTitle({
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
  }) =>
      style(
        fontWeight: fontWeight,
        fontSize: titleLg,
        color: color,
        height: 1.25,
      );

  /// Large money / total — website `text-[22px]` extrabold.
  static TextStyle priceLg({
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
  }) =>
      style(
        fontWeight: fontWeight,
        fontSize: displaySm,
        color: color,
        height: 1.2,
      );

  static TextTheme textTheme(TextTheme base, {Color? color}) {
    TextStyle map(TextStyle? s, FontWeight w, double size, {double h = 1.35}) =>
        style(
          fontWeight: w,
          fontSize: size,
          color: color ?? s?.color,
          height: h,
        );

    return base.copyWith(
      displayLarge: map(base.displayLarge, FontWeight.w800, displayXl, h: 1.15),
      displayMedium: map(base.displayMedium, FontWeight.w800, display, h: 1.15),
      displaySmall:
          map(base.displaySmall, FontWeight.w800, displaySm, h: 1.2),
      headlineLarge:
          map(base.headlineLarge, FontWeight.w800, display, h: 1.2),
      headlineMedium:
          map(base.headlineMedium, FontWeight.w800, titleLg, h: 1.25),
      headlineSmall:
          map(base.headlineSmall, FontWeight.w700, title, h: 1.3),
      titleLarge: map(base.titleLarge, FontWeight.w700, titleLg, h: 1.25),
      titleMedium: map(base.titleMedium, FontWeight.w700, title, h: 1.3),
      titleSmall: map(base.titleSmall, FontWeight.w600, titleSm, h: 1.3),
      bodyLarge: map(base.bodyLarge, FontWeight.w400, body, h: 1.45),
      bodyMedium: map(base.bodyMedium, FontWeight.w500, body, h: 1.35),
      bodySmall: map(base.bodySmall, FontWeight.w500, smPlus, h: 1.3),
      labelLarge: map(base.labelLarge, FontWeight.w700, body, h: 1.25),
      labelMedium: map(base.labelMedium, FontWeight.w600, bodySm, h: 1.25),
      labelSmall: map(base.labelSmall, FontWeight.w600, xs, h: 1.2),
    );
  }
}
