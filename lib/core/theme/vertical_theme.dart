import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/providers.dart';

/// Per-vertical chrome — hex values match website `verticalTheme.ts`.
class VerticalTheme {
  const VerticalTheme({
    required this.slug,
    required this.label,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.gradient,
    required this.chipBg,
    required this.chipFg,
    required this.heroAccent,
    required this.heroAccentText,
    required this.heroHighlight,
    required this.heroBody,
    required this.heroHeadline,
    required this.heroSubtitle,
  });

  final String slug;
  final String label;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final LinearGradient gradient;
  final Color chipBg;
  final Color chipFg;
  final Color heroAccent;
  final Color heroAccentText;
  final Color heroHighlight;
  final Color heroBody;
  final String heroHeadline;
  final String heroSubtitle;

  static const grocery = VerticalTheme(
    slug: 'grocery',
    label: 'Grocery',
    primary: Color(0xFF328FB8),
    primaryDark: Color(0xFF2A7DA2),
    primarySoft: Color(0xFFD7EEF6),
    gradient: LinearGradient(
      begin: Alignment(-0.9, -0.5),
      end: Alignment(1.0, 0.8),
      colors: [Color(0xFF328FB8), Color(0xFF57A1C2), Color(0xFF295F77)],
    ),
    chipBg: Color(0xFFD7EEF6),
    chipFg: Color(0xFF295F77),
    heroAccent: Color(0xFFD7EEF6),
    heroAccentText: Color(0xFF295F77),
    heroHighlight: Color(0xFFD7EEF6),
    heroBody: Color(0xFFE8F4F8),
    heroHeadline: 'Fresh groceries, up to 30% off.',
    heroSubtitle: 'Delivered to your door in under an hour.',
  );

  static const pharmacy = VerticalTheme(
    slug: 'pharmacy',
    label: 'Pharmacy',
    primary: Color(0xFF247B6A),
    primaryDark: Color(0xFF1F695B),
    primarySoft: Color(0xFFA6E7CB),
    gradient: LinearGradient(
      begin: Alignment(-0.6, -0.4),
      end: Alignment(0.8, 0.7),
      colors: [Color(0xFF247B6A), Color(0xFF38AA73), Color(0xFF2E9E54)],
    ),
    chipBg: Color(0xFFDCEFE9),
    chipFg: Color(0xFF247B6A),
    heroAccent: Color(0xFFA6E7CB),
    heroAccentText: Color(0xFF0E3F3A),
    heroHighlight: Color(0xFFA6E7CB),
    heroBody: Color(0xFFDCEFE9),
    heroHeadline: 'Medicines & wellness, delivered fast.',
    heroSubtitle: 'Trusted pharmacy essentials to your door.',
  );

  static const bakery = VerticalTheme(
    slug: 'bakery',
    label: 'Bakery',
    primary: Color(0xFFC2854D),
    primaryDark: Color(0xFFA87444),
    primarySoft: Color(0xFFFFE8CC),
    gradient: LinearGradient(
      begin: Alignment(-0.5, -0.3),
      end: Alignment(0.9, 0.7),
      colors: [Color(0xFFC2854D), Color(0xFFE3A66E), Color(0xFF9F6733)],
    ),
    chipBg: Color(0xFFFFE8CC),
    chipFg: Color(0xFF9F6733),
    heroAccent: Color(0xFFFFE8CC),
    heroAccentText: Color(0xFF9F6733),
    heroHighlight: Color(0xFFFFE8CC),
    heroBody: Color(0xFFFFF4E8),
    heroHeadline: 'Fresh bakery, warm from the oven.',
    heroSubtitle: 'Breads, cakes and snacks — same-day delivery.',
  );

  static const business = VerticalTheme(
    slug: 'business',
    label: 'Business',
    primary: Color(0xFF1E3A5F),
    primaryDark: Color(0xFF19314F),
    primarySoft: Color(0xFFDCE3F0),
    gradient: LinearGradient(
      begin: Alignment(-0.6, -0.4),
      end: Alignment(0.9, 0.7),
      colors: [Color(0xFF1E3A5F), Color(0xFF304F78), Color(0xFF1E3A5F)],
    ),
    chipBg: Color(0xFFDCE3F0),
    chipFg: Color(0xFF1E3A5F),
    heroAccent: Color(0xFFDCE3F0),
    heroAccentText: Color(0xFF2A3140),
    heroHighlight: Color(0xFFDCE3F0),
    heroBody: Color(0xFFE7ECF2),
    heroHeadline: 'Bulk supplies for your business.',
    heroSubtitle: 'Wholesale packs with reliable delivery.',
  );

  static VerticalTheme of(String slug) {
    switch (slug) {
      case 'pharmacy':
        return pharmacy;
      case 'bakery':
        return bakery;
      case 'business':
      case 'shop':
      case 'b2b':
        return business;
      case 'grocery':
      default:
        return grocery;
    }
  }

  static const all = [grocery, pharmacy, bakery, business];

  Color get cta => primary;
}

final verticalThemeProvider = Provider<VerticalTheme>((ref) {
  final slug = ref.watch(verticalProvider);
  return VerticalTheme.of(slug);
});
