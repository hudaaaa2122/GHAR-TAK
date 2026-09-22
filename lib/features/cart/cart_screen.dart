import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_routes.dart';
import '../../core/pricing/delivery_pricing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets.dart';
import '../../shared/figma_chrome.dart';
import '../providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promo = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cartProvider);
    final itemCount = async.valueOrNull?.fold<int>(0, (s, e) => s + e.quantity) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'My Cart',
            onBack: () => context.go(AppRoutes.home),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$itemCount items',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const CheckoutStepper(activeStep: 1),
          Expanded(
            child: async.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Your cart is empty', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go(AppRoutes.home),
                          child: const Text('Continue shopping'),
                        ),
                      ],
                    ),
                  );
                }
                final total = items.fold<double>(
                  0,
                  (s, e) => s + e.product.displayPrice * e.quantity,
                );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    ...items.map((item) {
                      final url = resolveMediaUrl(item.product.image?.best);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: url.isEmpty
                                  ? const ColoredBox(color: AppColors.chipBg)
                                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if ((item.product.quantity ?? 0) > 0) ...[
                                    Text(
                                      'Stock: ${item.product.quantity}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    formatRs(item.product.displayPrice),
                                    style: GoogleFonts.manrope(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 35,
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _QtyIcon(
                                    label: '−',
                                    color: AppColors.textSecondary,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .setQty(item, item.quantity - 1),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  _QtyIcon(
                                    label: '+',
                                    color: AppColors.primary,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .setQty(item, item.quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFC8E6F5),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _promo,
                              decoration: const InputDecoration(
                                hintText: 'Enter promo code',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Material(
                            color: AppColors.primaryMid,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Text(
                                  'Apply',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow(label: 'Subtotal', value: formatRs(total)),
                          const SizedBox(height: 10),
                          ..._deliveryRows(ref, total),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: AppColors.borderLight),
                          ),
                          Row(
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                formatRs(
                                  total +
                                      _quote(ref, total).fee,
                                ),
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          ..._freeShipHint(ref, total),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    BrandGradientButton(
                      label: 'Proceed to Checkout →',
                      onPressed: () => context.push(AppRoutes.checkout),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$e', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push(AppRoutes.login),
                        child: const Text('Sign in to view cart'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DeliveryQuote _quote(WidgetRef ref, double subtotal) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final shipping = ref.watch(shippingClassProvider).valueOrNull;
    return quoteDelivery(
      subtotal: subtotal,
      settings: settings,
      baseShippingAmount: shipping?.amount ?? 0,
      shippingType: shipping?.type ?? 'fixed',
    );
  }

  List<Widget> _deliveryRows(WidgetRef ref, double subtotal) {
    final shippingAsync = ref.watch(shippingClassProvider);
    if (shippingAsync.isLoading) {
      return [
        const _SummaryRow(label: 'Delivery fee', value: '…'),
      ];
    }
    final q = _quote(ref, subtotal);
    if (q.baseFee <= 0 && shippingAsync.valueOrNull == null) {
      return [
        const _SummaryRow(label: 'Delivery fee', value: '—'),
      ];
    }
    if (q.isFree) {
      return [
        _SummaryRow(
          label: 'Delivery fee',
          value: 'FREE',
          valueColor: AppColors.successText,
        ),
      ];
    }
    return [
      _SummaryRow(
        label: 'Delivery fee',
        value: formatRs(q.fee),
      ),
    ];
  }

  List<Widget> _freeShipHint(WidgetRef ref, double subtotal) {
    final q = _quote(ref, subtotal);
    if (!q.freeShippingEnabled || q.threshold <= 0) return const [];
    if (subtotal >= q.threshold) {
      return [
        const SizedBox(height: 10),
        Text(
          'You qualify for free delivery',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.successText,
          ),
        ),
      ];
    }
    final need = q.threshold - subtotal;
    return [
      const SizedBox(height: 10),
      Text(
        'Add ${formatRs(need)} more for free delivery (orders over ${formatRs(q.threshold)})',
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: AppColors.textMuted,
          height: 1.35,
        ),
      ),
    ];
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _QtyIcon extends StatelessWidget {
  const _QtyIcon({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 34,
        height: 35,
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 18, color: color, height: 1),
          ),
        ),
      ),
    );
  }
}
