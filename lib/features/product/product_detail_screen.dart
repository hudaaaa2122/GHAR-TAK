import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_fonts.dart';

import '../../constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/models.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.idOrSlug});

  final String idOrSlug;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  int _thumbIndex = 0;
  bool _wishlisted = false;
  bool _wishlistBusy = false;
  bool _wishlistLoaded = false;

  Future<void> _syncWishlistFlag(ProductModel p) async {
    if (_wishlistLoaded) return;
    _wishlistLoaded = true;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      final on = await ref.read(accountRepositoryProvider).isInWishlist(p.id);
      if (mounted) setState(() => _wishlisted = on);
    } catch (_) {}
  }

  Future<void> _toggleWishlist(ProductModel p) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      showAppToast(context, 'Sign in to save items to your wishlist');
      context.push(AppRoutes.login);
      return;
    }
    if (_wishlistBusy) return;
    setState(() => _wishlistBusy = true);
    final next = !_wishlisted;
    setState(() => _wishlisted = next);
    try {
      final repo = ref.read(accountRepositoryProvider);
      if (next) {
        await repo.addToWishlist(p.id);
        if (mounted) {
          showAppToast(context, 'Added to wishlist', isError: false);
        }
      } else {
        await repo.removeFromWishlist(p.id);
        if (mounted) {
          showAppToast(context, 'Removed from wishlist', isError: false);
        }
      }
      ref.invalidate(wishlistProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _wishlisted = !next);
        showAppToast(context, e);
      }
    } finally {
      if (mounted) setState(() => _wishlistBusy = false);
    }
  }

  Future<void> _addToCart(ProductModel p, {bool buyNow = false}) async {
    try {
      await ref.read(cartProvider.notifier).add(p, qty: _qty);
      if (!mounted) return;
      if (buyNow) {
        context.push(AppRoutes.checkout);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.idOrSlug));

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: async.when(
        data: (p) => _buildBody(p),
        loading: () => const Column(
          children: [
            FigmaScreenHeader(title: 'Product'),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        error: (e, _) => Column(
          children: [
            const FigmaScreenHeader(title: 'Product'),
            Expanded(child: Center(child: Text('$e'))),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProductModel p) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWishlistFlag(p));
    final url = resolveMediaUrl(p.image?.best);
    final inStock = p.inStock;
    final cartItems = ref.watch(cartProvider).valueOrNull ?? [];
    CartItemModel? cartItem;
    for (final i in cartItems) {
      if (i.product.id == p.id) {
        cartItem = i;
        break;
      }
    }
    final qtyInCart = cartItem?.quantity ?? 0;
    final inCart = qtyInCart > 0;
    final maxStock = p.quantity ?? 999;
    final savePct = p.hasDiscount && p.price > 0
        ? (((p.price - p.displayPrice) / p.price) * 100).round()
        : 0;
    final rating = p.rating ?? 4.6;
    final reviews = p.reviewCount ?? 128;
    final sold = ((p.id % 40) + 12) * 17;

    final thumbs = [
      url,
      url,
      url,
    ];

    final palette = AppPalette.of(context);

    return Column(
      children: [
        Material(
          color: palette.surface,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: [
                  FigmaBackButton(onPressed: () => context.pop()),
                  const Spacer(),
                  Material(
                    color: palette.surface,
                    shape: CircleBorder(
                      side: BorderSide(color: palette.border),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _wishlistBusy ? null : () => _toggleWishlist(p),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: _wishlistBusy
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _wishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: _wishlisted
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      thumbs[_thumbIndex].isEmpty
                          ? ColoredBox(
                              color: AppColors.chipBg,
                              child: Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                            )
                          : Opacity(
                              opacity: inStock ? 1 : 0.55,
                              child: CachedNetworkImage(
                                imageUrl: thumbs[_thumbIndex],
                                fit: BoxFit.contain,
                              ),
                            ),
                      if (!inStock)
                        ColoredBox(
                          color: Colors.white.withValues(alpha: 0.75),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'OUT OF STOCK',
                                style: AppFonts.style(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < thumbs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _thumbIndex = i),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _thumbIndex == i
                                ? AppColors.primary
                                : AppColors.border,
                            width: _thumbIndex == i ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: thumbs[i].isEmpty
                            ? ColoredBox(color: AppColors.chipBg)
                            : CachedNetworkImage(
                                imageUrl: thumbs[i],
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'GHER TAK',
                style: AppFonts.style(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.name,
                style: AppFonts.style(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1.2,
                  letterSpacing: -0.4,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Sold by ',
                    style: AppFonts.style(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'GherTak Store',
                    style: AppFonts.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 12,
                          color: AppColors.successText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: AppFonts.style(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: AppColors.successText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: AppFonts.style(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    ' ($reviews)',
                    style: AppFonts.style(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$sold sold',
                    style: AppFonts.style(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRs(p.displayPrice),
                    style: AppFonts.style(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      height: 1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (p.hasDiscount) ...[
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        formatRs(p.price),
                        style: AppFonts.style(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Save $savePct%',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    inStock ? 'In stock' : 'Out of stock',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: inStock ? AppColors.successText : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!inStock)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Out of stock',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
              else if (inCart)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _DetailQtyCircle(
                            icon: Icons.remove,
                            onTap: () async {
                              try {
                                await ref
                                    .read(cartProvider.notifier)
                                    .setQty(cartItem!, qtyInCart - 1);
                              } catch (e) {
                                if (mounted) showAppToast(context, e);
                              }
                            },
                          ),
                          Expanded(
                            child: Text(
                              '$qtyInCart',
                              textAlign: TextAlign.center,
                              style: AppFonts.style(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          _DetailQtyCircle(
                            icon: Icons.add,
                            onTap: qtyInCart >= maxStock
                                ? null
                                : () async {
                                    try {
                                      await ref
                                          .read(cartProvider.notifier)
                                          .setQty(cartItem!, qtyInCart + 1);
                                    } catch (e) {
                                      if (mounted) showAppToast(context, e);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    _QtyStepper(
                      qty: _qty,
                      enabled: inStock,
                      onChanged: (v) => setState(() => _qty = v),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _addToCart(p),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Add to cart',
                          style: AppFonts.style(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BrandGradientButton(
                        label: 'Buy now',
                        onPressed: () => _addToCart(p, buyNow: true),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TrustItem(Icons.payments_outlined, 'COD'),
                    _TrustItem(Icons.replay_outlined, 'Easy returns'),
                    _TrustItem(Icons.lock_outline, 'Secure payment'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Arrives in 45–90 mins within city limits',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Product details',
                child: Column(
                  children: [
                    _DetailRow('SKU', 'GT-${p.id}'),
                    _DetailRow('Category', 'Grocery'),
                    _DetailRow(
                      'Availability',
                      inStock ? 'In stock' : 'Out of stock',
                    ),
                    _DetailRow(
                      'Description',
                      p.description?.replaceAll(RegExp(r'<[^>]*>'), '').trim().isNotEmpty ==
                              true
                          ? p.description!
                              .replaceAll(RegExp(r'<[^>]*>'), '')
                              .trim()
                          : 'Fresh quality product from verified sellers.',
                      last: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Seller',
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GherTak Store',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Verified seller · $sold+ products sold',
                            style: AppFonts.style(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onChanged,
    this.enabled = true,
  });

  final int qty;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: !enabled || qty <= 1
                ? null
                : () => onChanged(qty - 1),
            icon: Icon(Icons.remove, size: 18, color: p.textPrimary),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: AppFonts.style(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: p.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: !enabled ? null : () => onChanged(qty + 1),
            icon: Icon(Icons.add, size: 18, color: p.textPrimary),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppFonts.style(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: AppPalette.of(context).textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DetailQtyCircle extends StatelessWidget {
  const _DetailQtyCircle({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.white.withValues(alpha: onTap == null ? 0.5 : 1),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.style(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppFonts.style(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.style(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
