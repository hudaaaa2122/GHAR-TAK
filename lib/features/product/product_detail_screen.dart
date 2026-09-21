import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
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
    final url = resolveMediaUrl(p.image?.best);
    final inStock = (p.quantity ?? 1) > 0;
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

    return Column(
      children: [
        Material(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  FigmaBackButton(onPressed: () => context.pop()),
                  const Spacer(),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _wishlisted = !_wishlisted),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
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
                  child: thumbs[_thumbIndex].isEmpty
                      ? const ColoredBox(
                          color: AppColors.chipBg,
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: thumbs[_thumbIndex],
                          fit: BoxFit.contain,
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
                            ? const ColoredBox(color: AppColors.chipBg)
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
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.name,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Sold by ',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'GherTak Store',
                    style: GoogleFonts.manrope(
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
                          style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    ' ($reviews)',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$sold sold',
                    style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      color: AppColors.primary,
                    ),
                  ),
                  if (p.hasDiscount) ...[
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        formatRs(p.price),
                        style: GoogleFonts.manrope(
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
                        style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: inStock ? AppColors.successText : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                      onPressed: inStock ? () => _addToCart(p) : null,
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
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BrandGradientButton(
                      label: 'Buy now',
                      onPressed:
                          inStock ? () => _addToCart(p, buyNow: true) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        'Delivery in 45–90 mins within city limits',
                        style: GoogleFonts.manrope(
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
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Verified seller · $sold+ products sold',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: !enabled || qty <= 1
                ? null
                : () => onChanged(qty - 1),
            icon: const Icon(Icons.remove, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            onPressed: !enabled ? null : () => onChanged(qty + 1),
            icon: const Icon(Icons.add, size: 18),
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
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
            style: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
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
