import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/vertical_theme.dart';
import '../data/models/models.dart';
import '../features/providers.dart';

export 'brand_widgets.dart';

String resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  var url = path.trim();

  // Absolute URL: rewrite localhost media hosts to the configured API origin
  // (matches website `resolveMediaUrl` in mediaUrl.ts).
  if (url.startsWith('http://') || url.startsWith('https://')) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final isLocal = host == 'localhost' || host == '127.0.0.1';
      if (isLocal && uri.path.startsWith('/media/')) {
        final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
        url = '$base${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      } else if (isLocal) {
        final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
        url = '$base${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      }
    } catch (_) {
      url = url
          .replaceFirst(RegExp(r'https?://localhost(:\d+)?'), AppConfig.apiBaseUrl)
          .replaceFirst(
            RegExp(r'https?://127\.0\.0\.1(:\d+)?'),
            AppConfig.apiBaseUrl,
          );
    }
    // Emulator → host machine when API itself is local.
    if (AppConfig.apiBaseUrl.contains('10.0.2.2') ||
        AppConfig.apiBaseUrl.contains('localhost')) {
      url = url
          .replaceFirst('http://localhost', 'http://10.0.2.2')
          .replaceFirst('http://127.0.0.1', 'http://10.0.2.2');
    }
    return url;
  }

  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  if (url.startsWith('/')) return '$base$url';
  return '$base/$url';
}

String formatRs(num value) {
  final f = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
  return f.format(value);
}

class AnnouncementBar extends ConsumerWidget {
  const AnnouncementBar({super.key, this.text});

  /// Optional override; when null, uses live `/settings` free-shipping copy.
  final String? text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final String resolved = text ??
        settings.when(
          data: (s) => s.freeDeliveryAnnouncement,
          loading: () => AppConfig.announcement,
          error: (_, __) => AppConfig.announcement,
        );

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        resolved,
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class VerticalTabs extends StatelessWidget {
  const VerticalTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _items = [
    _Vert('grocery', 'Grocery', AppColors.grocery, Colors.white, Icons.shopping_cart_outlined),
    _Vert('pharmacy', 'Pharmacy', AppColors.pharmacyBg, AppColors.pharmacyFg, Icons.vaccines_outlined),
    _Vert('bakery', 'Bakery', AppColors.bakeryBg, AppColors.bakeryFg, Icons.bakery_dining_outlined),
    _Vert('business', 'Business', AppColors.businessBg, AppColors.businessFg, Icons.business_center_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Row(
        children: _items.map((v) {
          final active = selected == v.slug;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(v.slug),
              child: Container(
                height: 72,
                color: active ? AppColors.grocery : v.bg,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(v.icon, color: active ? Colors.white : v.fg, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      v.label,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: active ? Colors.white : v.fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Vert {
  const _Vert(this.slug, this.label, this.bg, this.fg, this.icon);
  final String slug;
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.hint = 'Search products, brands...',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              if (controller != null && onSubmitted != null) {
                onSubmitted!(controller!.text);
              } else {
                onTap?.call();
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.search, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel = 'View all',
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: GoogleFonts.manrope(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.sellingFast = false,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool sellingFast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(verticalThemeProvider);
    final url = resolveMediaUrl(product.image?.best);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sellingFast)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SELLING FAST',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange,
                  ),
                ),
              ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: url.isEmpty
                    ? Container(color: AppColors.chipBg)
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.chipBg),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  formatRs(product.displayPrice),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: theme.primary,
                  ),
                ),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 6),
                  Text(
                    formatRs(product.price),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            if (sellingFast && product.quantity != null) ...[
              const SizedBox(height: 4),
              Text(
                'Only ${product.quantity} left',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ((product.quantity ?? 0) / 20).clamp(0.05, 1),
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  color: AppColors.orange,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  textStyle: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                label: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoBannerTeal extends StatelessWidget {
  const PromoBannerTeal({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = (w * 0.052).clamp(17.0, 22.0);
    final pad = (w * 0.045).clamp(14.0, 20.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.brandGradient,
      ),
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ONLINE EXCLUSIVE',
            style: GoogleFonts.manrope(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pay Week Sale – Up to 40% Off',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: titleSize,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grab month-end savings on your basics.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onExplore,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Shop Now →',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma “Breakfast & Spreads” — same tan look on every vertical (Grocery/Pharmacy/Bakery/Business).
class PromoBannerOrange extends StatelessWidget {
  const PromoBannerOrange({super.key, this.onShop});

  final VoidCallback? onShop;

  static const _bg = Color(0xFFC9A882);
  static const _bgSoft = Color(0xFFD4B896);
  static const _title = Color(0xFF3E2723);
  static const _subtitle = Color(0xFF7E6A58);
  static const _cta = Color(0xFF2D1E17);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = (w * 0.055).clamp(18.0, 24.0);
    final pad = (w * 0.048).clamp(16.0, 22.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_bg, _bgSoft],
                ),
              ),
            ),
          ),
          Positioned(
            right: -w * 0.09,
            top: -w * 0.07,
            child: Container(
              width: w * 0.4,
              height: w * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            right: w * 0.06,
            bottom: -w * 0.12,
            child: Container(
              width: w * 0.28,
              height: w * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad * 0.9, pad, pad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breakfast & Spreads',
                  style: GoogleFonts.manrope(
                    color: _title,
                    fontWeight: FontWeight.w800,
                    fontSize: titleSize,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start your day right',
                  style: GoogleFonts.manrope(
                    color: _subtitle,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: _cta,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: onShop,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        'Shop Now →',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
