import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../core/location/delivery_location.dart';
import '../../core/location/delivery_location_provider.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../location/map_location_picker_screen.dart';
import '../providers.dart';

// ─── Payment ─────────────────────────────────────────────────────────────────

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _method = 0;
  bool _useWallet = false;
  bool _placing = false;

  static const _methods = [
    (
      Icons.payments_outlined,
      'Cash on Delivery',
      'Pay when your order arrives',
      true,
      'cash_on_delivery',
    ),
    (
      Icons.account_balance_wallet_outlined,
      'JazzCash',
      'Mobile wallet payment',
      false,
      'jazzcash',
    ),
    (
      Icons.credit_card_outlined,
      'PayFast',
      'Card & online banking',
      false,
      'payfast',
    ),
    (
      Icons.upload_file_outlined,
      'Pay & Upload Receipt',
      'Bank transfer then upload proof',
      false,
      'bank_transfer',
    ),
  ];

  Future<void> _placeOrder() async {
    if (_placing) return;
    final draft = ref.read(checkoutDraftProvider);
    if (draft == null || draft.shippingAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      context.go(AppRoutes.checkout);
      return;
    }

    setState(() => _placing = true);
    final placedAt = DateTime.now();
    try {
      final wallet = ref.read(walletProvider).valueOrNull;
      final settings = ref.read(settingsProvider).valueOrNull;
      final shipping = ref.read(shippingClassProvider).valueOrNull;
      final order = await ref.read(orderRepositoryProvider).createFromCart(
            shippingAddress: draft.shippingAddress,
            paymentGateway: _methods[_method].$5,
            deliveryTime: draft.deliveryTime,
            orderNotes: draft.orderNotes,
            useWallet: _useWallet,
            walletAmount: _useWallet ? wallet?.balance : null,
            shippingId: shipping?.id ?? settings?.shippingClassId,
            taxId: settings?.taxClassId,
          );
      _goToOrderSuccess(order);
    } on ApiException catch (e) {
      if (e.isTimeout) {
        final recovered = await _recoverOrderAfterSlowResponse(placedAt);
        if (recovered != null) {
          _goToOrderSuccess(recovered);
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      // Dio timeouts sometimes surface as generic errors.
      final recovered = await _recoverOrderAfterSlowResponse(placedAt);
      if (recovered != null) {
        _goToOrderSuccess(recovered);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _goToOrderSuccess(OrderModel order) {
    ref.read(checkoutDraftProvider.notifier).state = null;
    ref.read(selectedCheckoutAddressIdProvider.notifier).state = null;
    // Clear badge immediately — server already emptied the cart on success.
    ref.read(cartProvider.notifier).clearLocal();
    if (!mounted) return;
    context.go(
      AppRoutes.orderSuccessWith(
        orderId: order.id,
        trackingId: order.trackingNumber,
      ),
    );
    // ignore: unawaited_futures
    ref.read(cartProvider.notifier).refresh();
    ref.invalidate(ordersProvider);
    ref.invalidate(walletProvider);
  }

  /// When create-from-cart times out, the order may still have been created
  /// (backend email/notify runs before the HTTP response). Confirm via cart + orders.
  Future<OrderModel?> _recoverOrderAfterSlowResponse(DateTime placedAt) async {
    try {
      await ref.read(cartProvider.notifier).refresh();
      final cart = ref.read(cartProvider).valueOrNull ?? [];
      final orders = await ref.read(orderRepositoryProvider).listAllMine();
      if (orders.isEmpty) return null;

      OrderModel? newest;
      DateTime? newestAt;
      for (final o in orders) {
        final raw = o.createdAt;
        final at = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
        if (at == null) continue;
        if (newestAt == null || at.isAfter(newestAt)) {
          newestAt = at;
          newest = o;
        }
      }
      newest ??= orders.first;

      final recent = newestAt == null ||
          newestAt.isAfter(placedAt.subtract(const Duration(minutes: 3)));
      // Empty cart after place-order is strong evidence the order landed.
      if (cart.isEmpty && recent) return newest;
      if (recent &&
          newestAt != null &&
          newestAt.isAfter(placedAt.subtract(const Duration(seconds: 5)))) {
        return newest;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final walletLabel = walletAsync.when(
      data: (w) => 'Available: Rs ${w.balance.toStringAsFixed(0)}',
      loading: () => 'Loading wallet…',
      error: (_, __) => 'Wallet unavailable',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Payment',
            onBack: () => context.pop(),
          ),
          const CheckoutStepper(activeStep: 3),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Text(
                          'SELECT PAYMENT METHOD',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      for (var i = 0; i < _methods.length; i++) ...[
                        InkWell(
                          onTap: () => setState(() => _method = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _methods[i].$1,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _methods[i].$2,
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (_methods[i].$4) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.warningSoft,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Most popular',
                                                style: GoogleFonts.manrope(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 10,
                                                  color: AppColors.warning,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        _methods[i].$3,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Radio<int>(
                                  value: i,
                                  groupValue: _method,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) =>
                                      setState(() => _method = v ?? 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (i < _methods.length - 1)
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.borderLight,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Use wallet balance',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      walletLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    value: _useWallet,
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) => setState(() => _useWallet = v),
                  ),
                ),
                const SizedBox(height: 24),
                BrandGradientButton(
                  label: _placing ? 'Placing order…' : 'Place Order',
                  onPressed: _placing ? null : _placeOrder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Success ───────────────────────────────────────────────────────────

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    this.orderId,
    this.trackingId,
  });

  final String? orderId;
  final String? trackingId;

  @override
  Widget build(BuildContext context) {
    final displayId = trackingId?.isNotEmpty == true
        ? trackingId!
        : (orderId ?? '—');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Placed!',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order has been confirmed and will be\ndelivered soon.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    Text(
                      'ORDER ID',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayId,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              BrandGradientButton(
                label: 'Track Order',
                onPressed: () {
                  if (orderId != null && orderId!.isNotEmpty) {
                    context.go(AppRoutes.order(orderId!));
                  } else {
                    context.go(AppRoutes.orders);
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Continue Shopping',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Orders ──────────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'My Orders',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e is ApiException ? e.message : e.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(ordersProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders yet',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(ordersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return InkWell(
                        onTap: () =>
                            context.push(AppRoutes.order(o.id)),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.displayId,
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      o.status ?? 'Pending',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (o.createdAt != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        o.createdAt!,
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                'Rs ${(o.total ?? 0).toStringAsFixed(0)}',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Details ───────────────────────────────────────────────────────────

// OrderDetailScreen moved to order_detail_screens.dart

// ─── Wishlist ────────────────────────────────────────────────────────────────

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.wishlist,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e is ApiException ? e.message : e.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(wishlistProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Your wishlist is empty',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(wishlistProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return InkWell(
                        onTap: () => context.push(AppRoutes.product('${p.id}')),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Icon(
                                    Icons.favorite,
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    size: 48,
                                  ),
                                ),
                              ),
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatRs(p.displayPrice),
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await ref
                                            .read(cartProvider.notifier)
                                            .add(p);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Added to cart'),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: Text(
                                        'Add',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(accountRepositoryProvider)
                                            .removeFromWishlist(p.id);
                                        ref.invalidate(wishlistProvider);
                                      } on ApiException catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(e.message)),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Profile (tabs: Info | Password | Addresses) ──────────────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _saving = false;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;

  final _addrLabel = TextEditingController();
  final _addrLine = TextEditingController();
  final _addrCity = TextEditingController();
  final _addrPhone = TextEditingController();
  double? _mapLat;
  double? _mapLng;
  String? _mapLabel;

  String? _avatarPath;

  Future<void> _pickOnMap() async {
    final q = <String, String>{
      if (_mapLat != null) 'lat': '${_mapLat}',
      if (_mapLng != null) 'lng': '${_mapLng}',
    };
    final uri = q.isEmpty
        ? AppRoutes.mapPicker
        : Uri(path: AppRoutes.mapPicker, queryParameters: q).toString();
    final result = await context.push<MapPickResult>(uri);
    if (!mounted || result == null) return;
    setState(() {
      _mapLat = result.lat;
      _mapLng = result.lng;
      _mapLabel = result.label;
      if ((result.street ?? '').trim().isNotEmpty &&
          _addrLine.text.trim().isEmpty) {
        _addrLine.text = result.street!.trim();
      }
      if ((result.city ?? '').trim().isNotEmpty) {
        _addrCity.text = result.city!.trim();
      }
    });
    showAppToast(context, 'Map pin set', isError: false);
  }

  Future<void> _pickAvatar() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update profile photo',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(
                  'Take photo',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  'Choose from gallery',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (_avatarPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    'Remove photo',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    setState(() => _avatarPath = null);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    try {
      final file = await ImagePicker().pickImage(
        source: choice,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (file == null || !mounted) return;
      setState(() => _avatarPath = file.path);
      showAppToast(
        context,
        'Photo selected — tap Save Profile to upload',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    final user = ref.read(authStateProvider).valueOrNull;
    _name.text = user?.name ?? '';
    _phone.text = user?.phoneNo ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    _addrLabel.dispose();
    _addrLine.dispose();
    _addrCity.dispose();
    _addrPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'My Profile',
            onBack: () => context.pop(),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Profile Info'),
                Tab(text: 'Change Password'),
                Tab(text: 'Addresses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildProfileInfo(),
                _buildChangePassword(),
                _buildAddresses(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      Map<String, dynamic>? uploaded;
      if (_avatarPath != null) {
        uploaded =
            await ref.read(accountRepositoryProvider).uploadMedia(_avatarPath!);
      }
      final user = await ref.read(accountRepositoryProvider).updateProfile(
            name: _name.text.trim(),
            phoneNo: _phone.text.trim(),
            image: uploaded,
          );
      ref.read(authStateProvider.notifier).setUser(user);
      if (!mounted) return;
      setState(() => _avatarPath = null);
      showAppToast(context, 'Profile updated successfully', isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePassword() async {
    if (_saving) return;
    if (_next.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }
    if (_next.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(accountRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
            confirmPassword: _confirm.text,
          );
      if (!mounted) return;
      _current.clear();
      _next.clear();
      _confirm.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAddress() async {
    if (_saving) return;
    final label = _addrLabel.text.trim();
    final line = _addrLine.text.trim();
    final city = _addrCity.text.trim();
    if (label.isEmpty || line.isEmpty || city.isEmpty) {
      showAppToast(context, 'Please fill label, address and city');
      return;
    }
    setState(() => _saving = true);
    try {
      // Prefer explicit map pin; else device GPS / fallback.
      double? lat = _mapLat;
      double? lng = _mapLng;
      if (lat == null || lng == null) {
        var loc = ref.read(deliveryLocationProvider).valueOrNull;
        loc ??= await resolveDeliveryLocation();
        if (!mounted) return;
        lat = loc.lat;
        lng = loc.lng;
        if (lat == null || lng == null) {
          showAppToast(
            context,
            'Pick a location on the map or enable GPS',
          );
          return;
        }
        if (!loc.hasGps && _mapLat == null) {
          showAppToast(
            context,
            'Using default pin. Prefer “Pick on map” for accuracy.',
            isError: false,
          );
        }
      }

      final repo = ref.read(accountRepositoryProvider);
      final ok = await repo.isDeliverable(lat: lat, lng: lng);
      if (!mounted) return;
      if (!ok) {
        showAppToast(
          context,
          'We don\'t deliver here. Move the pin into the Islamabad F Markaz zone.',
        );
        return;
      }

      await repo.createAddress(
        title: label,
        type: 'shipping',
        street: line,
        city: city,
        lat: lat,
        lng: lng,
        isDefault: false,
      );
      ref.invalidate(addressesProvider);
      if (!mounted) return;
      _addrLabel.clear();
      _addrLine.clear();
      _addrCity.clear();
      _addrPhone.clear();
      setState(() {
        _mapLat = null;
        _mapLng = null;
        _mapLabel = null;
      });
      showAppToast(context, 'Address saved', isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildProfileInfo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep your profile up to date for faster checkout and delivery.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primarySoft,
                  backgroundImage: _avatarPath != null
                      ? FileImage(File(_avatarPath!))
                      : null,
                  child: _avatarPath == null
                      ? Text(
                          'A',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _pickAvatar,
            child: Text(
              'Change photo',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _formCard(
          children: [
            _fieldLabel('Full Name'),
            TextField(controller: _name),
            const SizedBox(height: 14),
            _fieldLabel('Email'),
            TextField(
              controller: _email,
              enabled: false,
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.lock_outline, size: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Email cannot be changed. Contact support if needed.',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Phone'),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        const SizedBox(height: 20),
        BrandGradientButton(
          label: _saving ? 'Saving…' : 'Update Profile',
          onPressed: _saving ? null : _saveProfile,
        ),
      ],
    );
  }

  Widget _buildChangePassword() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use a strong password with at least 12 characters.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _formCard(
          children: [
            _fieldLabel('Current Password'),
            TextField(
              controller: _current,
              obscureText: !_showCurrent,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrent ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showCurrent = !_showCurrent),
                ),
                counterText: '${_current.text.length}/12',
              ),
              maxLength: 64,
            ),
            const SizedBox(height: 8),
            _fieldLabel('New Password'),
            TextField(
              controller: _next,
              obscureText: !_showNext,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNext ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showNext = !_showNext),
                ),
                counterText: '${_next.text.length}/12',
              ),
              maxLength: 64,
            ),
            const SizedBox(height: 8),
            _fieldLabel('Confirm Password'),
            TextField(
              controller: _confirm,
              obscureText: !_showConfirm,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showConfirm = !_showConfirm),
                ),
                counterText: '${_confirm.text.length}/12',
              ),
              maxLength: 64,
            ),
          ],
        ),
        const SizedBox(height: 20),
        BrandGradientButton(
          label: _saving ? 'Updating…' : 'Update Password',
          onPressed: _saving ? null : _savePassword,
        ),
      ],
    );
  }

  Widget _buildAddresses() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Add New Address',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _formCard(
          children: [
            _fieldLabel('Label'),
            TextField(
              controller: _addrLabel,
              decoration: const InputDecoration(hintText: 'Home / Office'),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Address'),
            TextField(
              controller: _addrLine,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Street, area…'),
            ),
            const SizedBox(height: 12),
            _fieldLabel('City'),
            TextField(
              controller: _addrCity,
              decoration: const InputDecoration(hintText: 'Islamabad'),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Phone'),
            TextField(
              controller: _addrPhone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _fieldLabel('Delivery pin'),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickOnMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(
                _mapLat != null
                    ? (_mapLabel ?? 'Pin set — tap to change')
                    : 'Pick location on map',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_mapLat != null) ...[
              const SizedBox(height: 6),
              Text(
                '${_mapLat!.toStringAsFixed(5)}, ${_mapLng!.toStringAsFixed(5)}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 16),
            BrandGradientButton(
              label: _saving ? 'Saving…' : 'Save Address',
              onPressed: _saving ? null : _saveAddress,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Saved Addresses',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ..._buildSavedAddressCards(ref),
      ],
    );
  }


  List<Widget> _buildSavedAddressCards(WidgetRef ref) {
    final async = ref.watch(addressesProvider);
    return async.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [
        Text(
          e is ApiException ? e.message : e.toString(),
          style: GoogleFonts.manrope(color: AppColors.error),
        ),
      ],
      data: (addresses) {
        if (addresses.isEmpty) {
          return [
            Text(
              'No saved addresses yet',
              style: GoogleFonts.manrope(color: AppColors.textMuted),
            ),
          ];
        }
        final widgets = <Widget>[];
        for (var i = 0; i < addresses.length; i++) {
          if (i > 0) widgets.add(const SizedBox(height: 10));
          widgets.add(_apiAddressCard(addresses[i]));
        }
        return widgets;
      },
    );
  }

  Widget _apiAddressCard(AddressModel a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: a.isDefault
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                a.title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (a.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Default',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.lineSummary.isEmpty ? 'No street details' : a.lineSummary,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () async {
                try {
                  await ref
                      .read(accountRepositoryProvider)
                      .deleteAddress(a.id);
                  ref.invalidate(addressesProvider);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address deleted')),
                  );
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept for route compatibility — opens My Profile → Change Password tab.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProfileScreen(initialTab: 1);
  }
}

/// Kept for route compatibility — opens My Profile → Addresses tab.
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProfileScreen(initialTab: 2);
  }
}

// ─── Wallet ──────────────────────────────────────────────────────────────────

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txnsAsync = ref.watch(walletTransactionsProvider);
    final wallet = walletAsync.valueOrNull;
    final balance = wallet?.balance ?? 0;
    final credited = wallet?.totalCredited ?? 0;
    final debited = wallet?.totalDebited ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.wallet,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: GoogleFonts.manrope(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        walletAsync.isLoading
                            ? '…'
                            : 'Rs ${balance.toStringAsFixed(0)}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _walletStat(
                              'Total Credited',
                              'Rs ${credited.toStringAsFixed(0)}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            child: _walletStat(
                              'Total Debited',
                              'Rs ${debited.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transactions',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ...txnsAsync.when(
                  loading: () => [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (e, _) => [
                    Text(
                      e is ApiException ? e.message : e.toString(),
                      style: GoogleFonts.manrope(color: AppColors.error),
                    ),
                  ],
                  data: (txns) {
                    if (txns.isEmpty) {
                      return [
                        Text(
                          'No transactions yet',
                          style: GoogleFonts.manrope(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ];
                    }
                    return [
                      for (final t in txns)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: t.isCredit
                                      ? AppColors.successSoft
                                      : AppColors.errorSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  t.isCredit
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 18,
                                  color: t.isCredit
                                      ? AppColors.successText
                                      : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${t.isCredit ? 'Credit' : 'Debit'}'
                                      '${t.dateLabel.isEmpty ? '' : ' · ${t.dateLabel}'}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${t.isCredit ? '+' : '−'}${formatRs(t.amount.abs())}',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: t.isCredit
                                      ? AppColors.successText
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notifications ───────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.notifications,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e is ApiException ? e.message : e.toString(),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(notificationsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(notificationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: n.isRead
                              ? null
                              : Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            if (n.body != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                n.body!,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (n.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                n.createdAt!,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ReturnsScreen moved to order_detail_screens.dart

// TrackOrderScreen moved to order_detail_screens.dart

// ─── Seller ──────────────────────────────────────────────────────────────────

class SellerScreen extends StatefulWidget {
  const SellerScreen({super.key});

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _address.dispose();
    _city.dispose();
    _province.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Become a Seller',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'YOUR SHOPS',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                          Icons.storefront,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GherTak Grocery',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Lahore · Grocery',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: AppColors.successText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create New Shop',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _formCard(
                  children: [
                    _fieldLabel('Shop Name'),
                    TextField(
                      controller: _name,
                      decoration:
                          const InputDecoration(hintText: 'Your shop name'),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Description'),
                    TextField(
                      controller: _desc,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tell customers about your shop',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Upload Logo / Cover'),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(
                              'Logo',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.photo_outlined, size: 18),
                            label: Text(
                              'Cover',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Address'),
                    TextField(
                      controller: _address,
                      decoration:
                          const InputDecoration(hintText: 'Shop address'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel('City'),
                              TextField(
                                controller: _city,
                                decoration:
                                    const InputDecoration(hintText: 'Islamabad'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel('Province'),
                              TextField(
                                controller: _province,
                                decoration:
                                    const InputDecoration(hintText: 'Punjab'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Phone'),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(hintText: '+92 …'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                BrandGradientButton(
                  label: 'Create Shop',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shop created')),
                    );
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan (camera / QR modes) ────────────────────────────────────────────────

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.mode = 'qr'});

  /// `camera` | `qr`
  final String mode;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _busy = false;
  String? _previewPath;
  bool _awaitingConfirm = false;
  bool _handledBarcode = false;
  MobileScannerController? _scanner;
  MobileScannerController? _imageAnalyzer;

  bool get _isCamera => widget.mode == 'camera';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCamera());
  }

  Future<void> _prepareCamera() async {
    final ok = await AppPermissions.ensureCamera();
    if (!mounted) return;
    if (!ok) {
      showAppToast(context, 'Camera permission is required to scan.');
      if (!_isCamera) {
        await _fallbackManualBarcode();
      }
      return;
    }
    if (_isCamera) return;
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      // Empty = all formats (EAN, UPC, Code128, QR, …)
      formats: const [],
    );
    setState(() => _scanner = controller);
    try {
      await controller.start();
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, 'Could not start camera: $e');
    }
  }

  @override
  void dispose() {
    _scanner?.dispose();
    _imageAnalyzer?.dispose();
    super.dispose();
  }

  Future<void> _openBarcodeResult(String code) async {
    final cleaned = code.trim();
    if (cleaned.isEmpty) return;

    setState(() => _busy = true);
    try {
      final products = await ref.read(catalogRepositoryProvider).listProducts(
            vertical: ref.read(verticalProvider),
            columnFilters: [
              ['bar_code', cleaned],
            ],
            limit: 20,
          );

      if (!mounted) return;

      if (products.length == 1) {
        final p = products.first;
        final id = p.slug?.isNotEmpty == true ? p.slug! : '${p.id}';
        context.pushReplacement(AppRoutes.product(id));
        return;
      }

      if (products.isEmpty) {
        // Fallback: name/sku search once production list includes those fields.
        context.pushReplacement(
          AppRoutes.productsQuery(search: cleaned, barcode: cleaned),
        );
        showAppToast(
          context,
          'No exact barcode match. Searching catalog…',
          isError: false,
        );
        return;
      }

      context.pushReplacement(AppRoutes.productsQuery(barcode: cleaned));
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
      setState(() {
        _busy = false;
        _handledBarcode = false;
      });
      await _scanner?.start();
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e.toString());
      setState(() {
        _busy = false;
        _handledBarcode = false;
      });
      await _scanner?.start();
    }
  }

  Future<void> _capturePhoto() async {
    if (_busy) return;
    final ok = await AppPermissions.ensureCamera();
    if (!ok) {
      if (mounted) showAppToast(context, 'Camera permission is required.');
      return;
    }
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (shot == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (mounted) {
        setState(() {
          _previewPath = shot.path;
          _awaitingConfirm = true;
          _busy = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, 'Camera unavailable: $e');
      setState(() => _busy = false);
    }
  }

  Future<void> _searchWithPhoto() async {
    if (_busy) return;
    final path = _previewPath;
    if (path == null) {
      showAppToast(context, 'Take a photo first');
      return;
    }

    setState(() => _busy = true);
    try {
      _imageAnalyzer ??= MobileScannerController(autoStart: false);
      final capture = await _imageAnalyzer!.analyzeImage(path);
      final code = capture?.barcodes
          .map((b) => b.rawValue)
          .whereType<String>()
          .map((s) => s.trim())
          .firstWhere((s) => s.isNotEmpty, orElse: () => '');

      if (!mounted) return;

      if (code != null && code.isNotEmpty) {
        showAppToast(
          context,
          'Barcode found on photo',
          isError: false,
        );
        await _openBarcodeResult(code);
        return;
      }

      // No barcode on packaging — ask for a product name / keyword.
      setState(() => _busy = false);
      final query = await _askProductName(
        title: 'No barcode on this photo',
        hint: 'Type the product name you see on the label',
      );
      if (!mounted) return;
      if (query == null || query.isEmpty) return;
      context.pushReplacement(AppRoutes.productsQuery(search: query));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final query = await _askProductName(
        title: 'Search by name',
        hint: 'Could not read barcode — enter product name',
      );
      if (!mounted) return;
      if (query == null || query.isEmpty) return;
      context.pushReplacement(AppRoutes.productsQuery(search: query));
    }
  }

  Future<String?> _askProductName({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_handledBarcode || _busy) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    _handledBarcode = true;
    _scanner?.stop();
    _openBarcodeResult(raw);
  }

  Future<void> _fallbackManualBarcode() async {
    if (_busy) return;
    final query = await _askProductName(
      title: 'Search products',
      hint: 'Enter barcode or product name',
    );
    if (!mounted || query == null || query.isEmpty) return;

    final digitsOnly = RegExp(r'^\d{8,14}$').hasMatch(query);
    if (digitsOnly) {
      await _openBarcodeResult(query);
    } else {
      context.pushReplacement(AppRoutes.productsQuery(search: query));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      _isCamera ? 'Search by photo' : 'Scan barcode',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (!_isCamera)
                    IconButton(
                      tooltip: 'Torch',
                      onPressed: () => _scanner?.toggleTorch(),
                      icon: const Icon(
                        Icons.flashlight_on_outlined,
                        color: Colors.white,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _isCamera
                    ? _CameraMode(
                        previewPath: _previewPath,
                        awaitingConfirm: _awaitingConfirm,
                      )
                    : _BarcodeLiveView(
                        controller: _scanner,
                        onDetect: _onBarcodeDetect,
                        onErrorFallback: _fallbackManualBarcode,
                      ),
              ),
            ),
            if (_isCamera)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: _awaitingConfirm
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _searchWithPhoto,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _busy
                                    ? 'Looking for barcode…'
                                    : 'Search with this photo',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _previewPath = null;
                                      _awaitingConfirm = false;
                                    }),
                            child: Text(
                              'Retake',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _busy ? null : _capturePhoto,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _busy ? Colors.white54 : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: _busy
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _busy ? null : _capturePhoto,
                            icon: const Icon(
                              Icons.cameraswitch_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  children: [
                    Text(
                      _busy
                          ? 'Looking up product…'
                          : 'Point at a barcode to search',
                      style: GoogleFonts.manrope(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : _fallbackManualBarcode,
                      child: Text(
                        'Enter barcode manually',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryMid,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CameraMode extends StatelessWidget {
  const _CameraMode({
    this.previewPath,
    this.awaitingConfirm = false,
  });

  final String? previewPath;
  final bool awaitingConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (previewPath != null)
                  Image.file(
                    File(previewPath!),
                    fit: BoxFit.cover,
                  )
                else
                  const ColoredBox(color: Color(0xFF151C28)),
                if (previewPath == null)
                  Center(
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      awaitingConfirm ? 'REVIEW' : 'PHOTO',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          awaitingConfirm
              ? 'Looks good? Search products that match this photo.'
              : 'Point your camera at a product, then tap the shutter',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _BarcodeLiveView extends StatelessWidget {
  const _BarcodeLiveView({
    required this.controller,
    required this.onDetect,
    required this.onErrorFallback,
  });

  final MobileScannerController? controller;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onErrorFallback;

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (controller == null)
                  const ColoredBox(
                    color: Color(0xFF151C28),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else
                  MobileScanner(
                  controller: controller!,
                  onDetect: onDetect,
                  errorBuilder: (context, error, child) {
                    return ColoredBox(
                      color: const Color(0xFF151C28),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam_off_outlined,
                                color: Colors.white54,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Camera unavailable',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error.errorDetails?.message ??
                                    error.errorCode.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: onErrorFallback,
                                child: Text(
                                  'Enter search manually',
                                  style: GoogleFonts.manrope(
                                    color: AppColors.primaryMid,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(painter: _ScanFramePainter()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Align the barcode inside the frame',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF57A1C2)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 36.0;
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Voice Search dialog (shown from home) ───────────────────────────────────

Future<void> showVoiceSearchDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => const _VoiceSearchDialog(),
  );
}

class _VoiceSearchDialog extends StatefulWidget {
  const _VoiceSearchDialog();

  @override
  State<_VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<_VoiceSearchDialog> {
  final SpeechToText _speech = SpeechToText();
  String _heard = '';
  String _status = 'Listening…';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _start() async {
    final micOk = await AppPermissions.ensureMicrophone();
    if (!mounted) return;
    if (!micOk) {
      setState(() => _status = 'Microphone permission denied');
      showAppToast(context, 'Microphone permission is required for voice search.');
      return;
    }
    _ready = await _speech.initialize(
      onError: (e) {
        if (!mounted) return;
        setState(() => _status = e.errorMsg);
      },
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _status = _heard.isEmpty ? 'No speech detected' : 'Got it');
        }
      },
    );
    if (!_ready) {
      if (!mounted) return;
      setState(() => _status = 'Speech recognition unavailable');
      return;
    }
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _heard = result.recognizedWords;
          _status = result.finalResult ? 'Searching…' : 'Listening…';
        });
        if (result.finalResult && _heard.trim().isNotEmpty) {
          _finish(_heard.trim());
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        localeId: 'en_US',
        partialResults: true,
      ),
    );
  }

  void _finish(String query) {
    _speech.stop();
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRoutes.productsQuery(search: query));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121A26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () {
                  _speech.stop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ),
            Text(
              'Voice Search',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: GoogleFonts.manrope(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_heard.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '"$_heard"',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                final q = _heard.trim();
                if (q.isEmpty) {
                  showAppToast(context, 'Speak a product name, then try again.');
                  return;
                }
                _finish(q);
              },
              child: Text(
                'Search',
                style: GoogleFonts.manrope(
                  color: AppColors.primaryMid,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

Widget _formCard({required List<Widget> children}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

Widget _fieldLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
