import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_fonts.dart';
import 'package:intl/intl.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/vertical_theme.dart';
import '../data/models/models.dart';
import '../features/providers.dart';
import 'app_toast.dart';

export 'brand_widgets.dart';
export 'web_ui.dart';
export 'app_toast.dart';

/// Catalog search placeholder count — round down to thousands (`6100` → `6,000+`).
String formatRoundedItemCount(int count) {
  if (count < 1000) return NumberFormat('#,###').format(count);
  final rounded = (count ~/ 1000) * 1000;
  return '${NumberFormat('#,###').format(rounded)}+';
}

String resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  var url = path.trim();
  if (url.isEmpty) return '';

  // Generated SVG avatars (data URLs) — callers should fall back to initials.
  if (url.startsWith('data:')) return '';

  final apiBase = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  final siteBase = AppConfig.websiteBaseUrl.replaceAll(RegExp(r'/$'), '');

  // Absolute URL: rewrite localhost / 127.0.0.1 media hosts to the API origin
  // (matches website `resolveMediaUrl` in mediaUrl.ts).
  if (url.startsWith('http://') || url.startsWith('https://')) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final isLocal = host == 'localhost' || host == '127.0.0.1';
      if (isLocal && uri.path.startsWith('/media/')) {
        url = '$apiBase${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      } else if (isLocal) {
        url = '$apiBase${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      }
      // Keep non-local absolute URLs as-is (Shopify CDN, api.ghertak.com, …).
    } catch (_) {
      url = url
          .replaceFirst(RegExp(r'https?://localhost(:\d+)?'), apiBase)
          .replaceFirst(RegExp(r'https?://127\.0\.0\.1(:\d+)?'), apiBase);
    }

    // Android emulator → host machine when API itself is local.
    if (apiBase.contains('10.0.2.2') || apiBase.contains('localhost')) {
      url = url
          .replaceFirst('http://localhost', 'http://10.0.2.2')
          .replaceFirst('http://127.0.0.1', 'http://10.0.2.2');
    }
    return url;
  }

  // Bare icon name from browse-tiles (`lipstick`) → website static icons.
  if (!url.contains('/') &&
      !url.contains('.') &&
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(url)) {
    return '$siteBase/category-icons/$url.png';
  }

  // Category icon pack lives on the customer website, not the API host.
  // e.g. /category-icons/lipstick.png → https://ghertak.com/category-icons/...
  final normalized = url.startsWith('/') ? url : '/$url';
  if (normalized.startsWith('/category-icons/')) {
    return '$siteBase$normalized';
  }

  // Relative `/media/...` or other API paths.
  if (url.startsWith('/')) return '$apiBase$url';
  return '$apiBase/$url';
}

String formatRs(num value) {
  // Website `currencyFormatter` → "Rs. 1,250" (whole rupees).
  final n = NumberFormat('#,###');
  return 'Rs. ${n.format(value.round())}';
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
      decoration: const BoxDecoration(
        gradient: AppColors.announcementGradient,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        resolved,
        textAlign: TextAlign.center,
        style: AppFonts.style(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Website `FreeDeliveryBar` — progress toward complimentary delivery.
class FreeDeliveryBar extends StatelessWidget {
  const FreeDeliveryBar({
    super.key,
    required this.subtotal,
    required this.threshold,
    this.enabled = true,
  });

  final double subtotal;
  final double threshold;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || threshold <= 0) return const SizedBox.shrink();

    final remaining = (threshold - subtotal).clamp(0.0, double.infinity);
    final progress = (subtotal / threshold).clamp(0.0, 1.0);
    final qualified = remaining <= 0;

    if (qualified) {
      // One line only — omit the extra COMPLIMENTARY badge (shown in order summary).
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF6ED),
          border: Border(bottom: BorderSide(color: Color(0xFFC8E8D4))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 18, color: Color(0xFF15824B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your order qualifies for complimentary fulfillment!',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15824B),
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE1F0F3),
        border: Border(bottom: BorderSide(color: Color(0xFFC8DEDA))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_shipping_outlined,
              size: 18, color: Color(0xFF11788C)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add ${formatRs(remaining)} more for complimentary fulfillment',
                        style: AppFonts.style(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0C6376),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      formatRs(threshold),
                      style: AppFonts.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFC8DEDA),
                    color: const Color(0xFF11788C),
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
                      style: AppFonts.style(
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
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.hint = 'Search products, brands...',
    this.showSearchButton = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final String hint;
  final bool showSearchButton;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            autofocus: autofocus,
            onTap: onTap,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
          ),
        ),
        if (showSearchButton) ...[
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
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.22,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppFonts.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                style: AppFonts.style(
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
    this.onAdd,
    this.sellingFast = false,
    this.width,
  });

  final ProductModel product;
  final VoidCallback onTap;
  /// Optional override; when null, card manages cart via [cartProvider].
  final VoidCallback? onAdd;
  final bool sellingFast;
  /// Set for horizontal rails (e.g. home). Null fills the parent (grids).
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(verticalThemeProvider);
    final url = resolveMediaUrl(product.image?.best);
    final cardW = width;
    final compact = cardW != null && cardW < 140;
    final cartItems = ref.watch(cartProvider).valueOrNull ?? [];
    CartItemModel? cartItem;
    for (final i in cartItems) {
      if (i.product.id == product.id) {
        cartItem = i;
        break;
      }
    }
    final qtyInCart = cartItem?.quantity ?? 0;
    final inCart = qtyInCart > 0;
    final maxStock = product.quantity ?? 999;
    final inStock = product.inStock;
    final outOfStock = !inStock;

    Future<void> addOne() async {
      if (outOfStock) return;
      if (onAdd != null) {
        onAdd!();
        return;
      }
      try {
        await ref.read(cartProvider.notifier).add(product);
      } catch (e) {
        if (context.mounted) showAppToast(context, e);
      }
    }

    Future<void> setQty(int next) async {
      if (cartItem == null) return;
      try {
        await ref.read(cartProvider.notifier).setQty(cartItem, next);
      } catch (e) {
        if (context.mounted) showAppToast(context, e);
      }
    }

    final nameSize = compact ? 11.0 : 13.0;
    final priceSize = compact ? 12.0 : 15.0;
    final strikeSize = compact ? 9.5 : 11.0;
    final p = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardW,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : AppColors.cardShadow,
        ),
        padding: EdgeInsets.all(compact ? 7 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sellingFast && !outOfStock)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E6DC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SELLING FAST',
                  style: AppFonts.style(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8F4F2A),
                  ),
                ),
              ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: p.inputFill,
                      child: url.isEmpty
                          ? ColoredBox(color: p.section)
                          : Opacity(
                              opacity: outOfStock ? 0.55 : 1,
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                errorWidget: (_, __, ___) =>
                                    ColoredBox(color: p.section),
                              ),
                            ),
                    ),
                    // Website ProductCard: red OUT OF STOCK badge on image.
                    if (outOfStock)
                      ColoredBox(
                        color: Colors.white.withValues(alpha: 0.75),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 6 : 10,
                              vertical: compact ? 3 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OUT OF STOCK',
                              textAlign: TextAlign.center,
                              style: AppFonts.style(
                                fontSize: compact ? 8 : 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: AppFonts.style(
                fontWeight: FontWeight.w700,
                fontSize: nameSize,
                height: 1.25,
                color: outOfStock ? p.textMuted : p.textPrimary,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatRs(product.displayPrice),
                      maxLines: 1,
                      softWrap: false,
                      style: AppFonts.style(
                        fontWeight: FontWeight.w800,
                        fontSize: priceSize,
                        height: 1.1,
                        color: outOfStock
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRs(product.price),
                        maxLines: 1,
                        softWrap: false,
                        style: AppFonts.style(
                          fontSize: strikeSize,
                          height: 1.1,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (sellingFast && !outOfStock && product.quantity != null) ...[
              const SizedBox(height: 2),
              Text(
                'Only ${product.quantity} left',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8F4F2A),
                ),
              ),
            ],
            SizedBox(height: compact ? 6 : 8),
            SizedBox(
              width: double.infinity,
              height: compact ? 30 : 36,
              child: GestureDetector(
                onTap: () {}, // absorb tap so card onTap doesn't fire
                child: outOfStock
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Out of stock',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w700,
                              fontSize: compact ? 10 : 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    : inCart
                        ? Material(
                            color: theme.primary,
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
                                  _QtyCircleButton(
                                    icon: Icons.remove,
                                    onTap: () => setQty(qtyInCart - 1),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$qtyInCart',
                                      textAlign: TextAlign.center,
                                      style: AppFonts.style(
                                        fontWeight: FontWeight.w700,
                                        fontSize: compact ? 12 : 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  _QtyCircleButton(
                                    icon: Icons.add,
                                    onTap: qtyInCart >= maxStock
                                        ? null
                                        : () => setQty(qtyInCart + 1),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FilledButton(
                            onPressed: addOne,
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: AppFonts.style(
                                fontWeight: FontWeight.w700,
                                fontSize: compact ? 11 : 12,
                              ),
                            ),
                            child: Text(compact ? 'Add' : 'Add to cart'),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyCircleButton extends StatelessWidget {
  const _QtyCircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          color: Colors.white.withValues(alpha: onTap == null ? 0.2 : 0.0),
        ),
        child: Icon(
          icon,
          size: 14,
          color: Colors.white.withValues(alpha: onTap == null ? 0.5 : 1),
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
            style: AppFonts.style(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pay Week Sale – Up to 40% Off',
            style: AppFonts.style(
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
            style: AppFonts.style(
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
                  style: AppFonts.style(
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
                  style: AppFonts.style(
                    color: _title,
                    fontWeight: FontWeight.w800,
                    fontSize: titleSize,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start your day right',
                  style: AppFonts.style(
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
                        style: AppFonts.style(
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
