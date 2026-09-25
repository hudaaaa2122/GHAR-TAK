import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_fonts.dart';

import '../../constants/app_routes.dart';
import '../../core/location/delivery_location.dart';
import '../../core/location/delivery_location_provider.dart';
import '../../core/network/api_response.dart';
import '../../core/order/edit_order_session.dart';
import '../../core/pricing/delivery_pricing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets.dart';
import '../../shared/figma_chrome.dart';
import '../location/map_location_picker_screen.dart';
import '../providers.dart';
import 'allow_substitution_checkbox.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promo = TextEditingController();
  bool _applyingCoupon = false;

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

  Future<void> _applyCoupon(double subtotal) async {
    final code = _promo.text.trim();
    if (code.isEmpty) {
      showAppToast(context, 'Please enter a coupon code');
      return;
    }
    setState(() => _applyingCoupon = true);
    try {
      final coupon =
          await ref.read(orderRepositoryProvider).redeemCoupon(code);
      if (!mounted) return;
      if (coupon == null || coupon.id <= 0) {
        showAppToast(context, 'Invalid coupon code');
        ref.read(appliedCouponProvider.notifier).state = null;
        return;
      }
      final min = coupon.minimumCartAmount ?? 0;
      if (min > 0 && subtotal < min) {
        showAppToast(
          context,
          'Minimum cart amount of ${formatRs(min)} required for this coupon',
        );
        ref.read(appliedCouponProvider.notifier).state = null;
        return;
      }
      ref.read(appliedCouponProvider.notifier).state = coupon;
      showAppToast(context, 'Coupon applied successfully!', isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ref.read(appliedCouponProvider.notifier).state = null;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      ref.read(appliedCouponProvider.notifier).state = null;
      showAppToast(context, 'Failed to apply coupon');
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cartProvider);
    final coupon = ref.watch(appliedCouponProvider);
    final itemCount = async.valueOrNull?.fold<int>(0, (s, e) => s + e.quantity) ?? 0;

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
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
                style: AppFonts.style(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          if (ref.watch(editOrderSessionProvider) != null)
            Material(
              color: const Color(0xFFE7F6EE),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF126B3E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing order ${ref.watch(editOrderSessionProvider)!.trackingNumber}',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF126B3E),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(editOrderSessionProvider.notifier)
                            .clear();
                        await ref.read(cartProvider.notifier).clear();
                        if (!context.mounted) return;
                        showAppToast(
                          context,
                          'Edit cancelled. You are back to normal shopping.',
                          isError: false,
                        );
                        context.go(AppRoutes.home);
                      },
                      child: Text(
                        'Cancel',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
                        Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Your cart is empty', style: AppFonts.style(fontWeight: FontWeight.w700)),
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
                final couponDiscount = coupon?.discountFor(total) ?? 0;
                final settings = ref.watch(settingsProvider).valueOrNull;
                return Column(
                  children: [
                    FreeDeliveryBar(
                      subtotal: total,
                      threshold: settings?.freeShippingAmount ?? 0,
                      enabled: settings?.freeShipping == true,
                    ),
                    // Line items only — no rubber-band when the list is short.
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        physics: items.length <= 3
                            ? const NeverScrollableScrollPhysics()
                            : const ClampingScrollPhysics(),
                        children: [
                          const AllowSubstitutionCheckbox(),
                          ...items.map((item) {
                            final url =
                                resolveMediaUrl(item.product.image?.best);
                            return WebCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: url.isEmpty
                                          ? Container(color: AppColors.chipBg)
                                          : CachedNetworkImage(
                                              imageUrl: url,
                                              fit: BoxFit.contain,
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                color: AppColors.chipBg,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.style(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formatRs(item.product.displayPrice),
                                          style: AppFonts.style(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _QtyIcon(
                                        label: '−',
                                        color: AppColors.textMuted,
                                        onTap: () => ref
                                            .read(cartProvider.notifier)
                                            .setQty(item, item.quantity - 1),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: AppFonts.style(
                                            fontWeight: FontWeight.w800,
                                          ),
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
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Promo / delivery / summary stay pinned — no empty scroll.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WebCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_offer_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _promo,
                                    decoration: InputDecoration(
                                      hintText: coupon == null
                                          ? 'Enter promo code'
                                          : 'Applied: ${coupon.code ?? _promo.text}',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (coupon != null)
                                  TextButton(
                                    onPressed: () {
                                      ref
                                          .read(appliedCouponProvider.notifier)
                                          .state = null;
                                      _promo.clear();
                                      showAppToast(
                                        context,
                                        'Coupon removed',
                                        isError: false,
                                      );
                                    },
                                    child: Text(
                                      'Remove',
                                      style: AppFonts.style(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  )
                                else
                                  Material(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      onTap: _applyingCoupon
                                          ? null
                                          : () => _applyCoupon(total),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: _applyingCoupon
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                'Apply',
                                                style: AppFonts.style(
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
                          const SizedBox(height: 10),
                          _CartDeliveryCard(),
                          const SizedBox(height: 10),
                          if (ref.watch(authStateProvider).valueOrNull == null)
                            _GuestSignInCard(
                              onSignIn: () => context.push(AppRoutes.login),
                            ),
                          if (ref.watch(authStateProvider).valueOrNull == null)
                            const SizedBox(height: 10),
                          WebCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Summary',
                                  style: AppFonts.style(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _SummaryRow(
                                  label: 'Subtotal',
                                  value: formatRs(total),
                                ),
                                const SizedBox(height: 8),
                                if (couponDiscount > 0) ...[
                                  _SummaryRow(
                                    label: 'Coupon',
                                    value: '- ${formatRs(couponDiscount)}',
                                    valueColor: AppColors.successText,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                ..._deliveryRows(ref, total),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(color: AppColors.borderLight),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Total',
                                      style: AppFonts.style(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      formatRs(
                                        total -
                                            couponDiscount +
                                            _quote(ref, total).fee,
                                      ),
                                      style: AppFonts.style(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          WebGradientButton(
                            label: ref.watch(editOrderSessionProvider) != null
                                ? 'Update order →'
                                : 'Proceed to Checkout →',
                            onPressed: () {
                              final editing =
                                  ref.read(editOrderSessionProvider) != null;
                              final loggedIn = ref
                                      .read(authStateProvider)
                                      .valueOrNull !=
                                  null;
                              final guestOk = ref
                                      .read(settingsProvider)
                                      .valueOrNull
                                      ?.guestCheckout ??
                                  true;
                              if (!loggedIn && !guestOk && !editing) {
                                showAppToast(
                                  context,
                                  'Please login first to checkout',
                                  kind: AppToastKind.info,
                                );
                                context.push(AppRoutes.login);
                                return;
                              }
                              context.push(AppRoutes.checkout);
                            },
                          ),
                        ],
                      ),
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
                        onPressed: () => context.go(AppRoutes.home),
                        child: const Text('Continue shopping'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.login),
                        child: const Text('Sign in'),
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
        const _SummaryRow(label: 'Fulfillment', value: '…'),
      ];
    }
    if (shippingAsync.hasError) {
      return [
        const _SummaryRow(
          label: 'Fulfillment',
          value: 'Error',
          valueColor: AppColors.error,
        ),
      ];
    }
    final q = _quote(ref, subtotal);
    // Website checkout: when free-shipping discount applies, show
    // ~~Rs. base (e.g. 550)~~ COMPLIMENTARY — not the leftover fee after maxOff.
    if (q.discount > 0 && q.baseFee > 0) {
      return [
        _SummaryRow(
          label: 'Fulfillment',
          value: 'COMPLIMENTARY',
          valueColor: AppColors.successText,
          struckValue: formatRs(q.baseFee),
        ),
      ];
    }
    if (q.fee <= 0) {
      return [
        const _SummaryRow(
          label: 'Fulfillment',
          value: 'COMPLIMENTARY',
          valueColor: AppColors.successText,
        ),
      ];
    }
    return [
      _SummaryRow(
        label: 'Fulfillment',
        value: formatRs(q.fee),
      ),
    ];
  }
}

class _GuestSignInCard extends StatelessWidget {
  const _GuestSignInCard({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    // Website CheckoutPaymentPage guest header — also shown on cart.
    return WebCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue as guest',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No account needed — checkout with your details.',
                  style: AppFonts.style(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Have an account?',
                style: AppFonts.style(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: onSignIn,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Sign in',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartDeliveryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authStateProvider).valueOrNull != null;
    final locAsync = ref.watch(deliveryLocationProvider);
    final loc = locAsync.valueOrNull ?? DeliveryLocation.fallback;
    final line = [
      if ((loc.street ?? '').trim().isNotEmpty) loc.street!.trim(),
      if ((loc.city ?? '').trim().isNotEmpty) loc.city!.trim(),
    ].join(', ');

    return WebCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line.isNotEmpty ? line : loc.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (!loggedIn)
                  Text(
                    'Guest delivery place — not saved to an account',
                    style: AppFonts.style(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              if (loggedIn) {
                context.push(AppRoutes.addresses);
                return;
              }
              final result = await Navigator.of(context).push<MapPickResult>(
                MaterialPageRoute(
                  builder: (_) => MapLocationPickerScreen(
                    initialLat: loc.lat,
                    initialLng: loc.lng,
                  ),
                ),
              );
              if (result == null) return;
              final next = DeliveryLocation(
                label: result.label ??
                    [
                      if ((result.street ?? '').isNotEmpty) result.street,
                      if ((result.city ?? '').isNotEmpty) result.city,
                    ].whereType<String>().join(', '),
                lat: result.lat,
                lng: result.lng,
                hasGps: true,
                street: result.street,
                city: result.city,
              );
              ref.read(deliveryLocationOverrideProvider.notifier).state = next;
              await persistDeliveryLocation(next);
              ref.read(needsDeliveryGateProvider.notifier).state = false;
              ref.invalidate(deliveryLocationProvider);
            },
            child: Text(
              'Change',
              style: AppFonts.style(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.struckValue,
  });

  final String label;
  final String value;
  final Color? valueColor;
  /// Website-style crossed-out base fulfillment fee (e.g. ~~Rs. 50~~ COMPLIMENTARY).
  final String? struckValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppFonts.style(
            color: AppColors.textSecondary,
            fontSize: AppFonts.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (struckValue != null && struckValue!.isNotEmpty) ...[
          Text(
            struckValue!,
            style: AppFonts.style(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          value,
          style: AppFonts.style(
            fontWeight: FontWeight.w700,
            fontSize: AppFonts.body,
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
            style: AppFonts.style(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
