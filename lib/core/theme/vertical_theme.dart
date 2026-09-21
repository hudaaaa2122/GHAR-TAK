import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/providers.dart';

/// Per-vertical chrome (Figma Pharmacy / Bakery / Business / Grocery home).
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
  });

  final String slug;
  final String label;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final LinearGradient gradient;

  /// Always-on circle color behind the vertical icon (unselected look).
  final Color chipBg;
  final Color chipFg;

  static const grocery = VerticalTheme(
    slug: 'grocery',
    label: 'Grocery',
    primary: Color(0xFF3B9BC8),
    primaryDark: Color(0xFF2A6F94),
    primarySoft: Color(0xFFE8F4FA),
    gradient: LinearGradient(
      begin: Alignment(-0.9, -0.5),
      end: Alignment(1.0, 0.8),
      colors: [Color(0xFF2F8BB5), Color(0xFF4AA3C7), Color(0xFF2A6A8A)],
    ),
    chipBg: Color(0xFFD6EEF8),
    chipFg: Color(0xFF2A637C),
  );

  /// Figma Pharmacy home — green header + CTAs.
  static const pharmacy = VerticalTheme(
    slug: 'pharmacy',
    label: 'Pharmacy',
    primary: Color(0xFF2D6E5A),
    primaryDark: Color(0xFF1F4F41),
    primarySoft: Color(0xFFE3F6EC),
    gradient: LinearGradient(
      begin: Alignment(-0.6, -0.4),
      end: Alignment(0.8, 0.7),
      colors: [Color(0xFF2F8A5C), Color(0xFF3E9E70), Color(0xFF257A52)],
    ),
    chipBg: Color(0xFFDDF5E5),
    chipFg: Color(0xFF1F7A4F),
  );

  /// Figma Bakery home — tan / brown header + CTAs.
  static const bakery = VerticalTheme(
    slug: 'bakery',
    label: 'Bakery',
    primary: Color(0xFFC4895A),
    primaryDark: Color(0xFF8B5528),
    primarySoft: Color(0xFFF8EDE2),
    gradient: LinearGradient(
      begin: Alignment(-0.5, -0.3),
      end: Alignment(0.9, 0.7),
      colors: [Color(0xFFD49A5E), Color(0xFFE0B07A), Color(0xFFC4844A)],
    ),
    chipBg: Color(0xFFFBE8D8),
    chipFg: Color(0xFF8B5528),
  );

  /// Figma Business home — slate / navy header + CTAs.
  static const business = VerticalTheme(
    slug: 'business',
    label: 'Business',
    primary: Color(0xFF2C3E5C),
    primaryDark: Color(0xFF1C2A40),
    primarySoft: Color(0xFFE8EEF5),
    gradient: LinearGradient(
      begin: Alignment(-0.6, -0.4),
      end: Alignment(0.9, 0.7),
      colors: [Color(0xFF354D72), Color(0xFF4A6490), Color(0xFF2C4060)],
    ),
    chipBg: Color(0xFFDCE3F0),
    chipFg: Color(0xFF2F4768),
  );

  static VerticalTheme of(String slug) {
    switch (slug) {
      case 'pharmacy':
        return pharmacy;
      case 'bakery':
        return bakery;
      case 'business':
        return business;
      case 'grocery':
      default:
        return grocery;
    }
  }

  static const all = [grocery, pharmacy, bakery, business];
}

final verticalThemeProvider = Provider<VerticalTheme>((ref) {
  final slug = ref.watch(verticalProvider);
  return VerticalTheme.of(slug);
});
