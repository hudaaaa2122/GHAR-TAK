import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';

// ─── Payment ─────────────────────────────────────────────────────────────────

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _method = 0;
  bool _useWallet = false;

  static const _methods = [
    (
      Icons.payments_outlined,
      'Cash on Delivery',
      'Pay when your order arrives',
      true,
    ),
    (
      Icons.account_balance_wallet_outlined,
      'JazzCash',
      'Mobile wallet payment',
      false,
    ),
    (
      Icons.credit_card_outlined,
      'PayFast',
      'Card & online banking',
      false,
    ),
    (
      Icons.upload_file_outlined,
      'Pay & Upload Receipt',
      'Bank transfer then upload proof',
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                      'Available: Rs 2,500',
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
                  label: 'Place Order',
                  onPressed: () => context.go(AppRoutes.orderSuccess),
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
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const FigmaScreenHeader(title: 'Confirm'),
          const CheckoutStepper(activeStep: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.successSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 52,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Order confirmed!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thanks for shopping with Gher Tak. We’ll notify you as your order moves.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'TRACKING NUMBER',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GT-88421',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                BrandGradientButton(
                  label: 'View order details',
                  onPressed: () => context.go(AppRoutes.order('GT-88421')),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppStrings.continueShopping,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
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

// ─── Orders ──────────────────────────────────────────────────────────────────

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const _orders = [
    _OrderCardData(
      id: 'GT-88421',
      date: '17 Sep 2026',
      status: 'Out for Delivery',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningSoft,
      items: 4,
      total: 4580,
    ),
    _OrderCardData(
      id: 'GT-87102',
      date: '12 Sep 2026',
      status: 'Delivered',
      statusColor: AppColors.successText,
      statusBg: AppColors.successSoft,
      items: 2,
      total: 1890,
    ),
    _OrderCardData(
      id: 'GT-86044',
      date: '3 Sep 2026',
      status: 'Processing',
      statusColor: AppColors.info,
      statusBg: AppColors.primarySoft,
      items: 6,
      total: 6720,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'My Orders',
            onBack: () => context.go(AppRoutes.home),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = _orders[i];
                return InkWell(
                  onTap: () => context.push(AppRoutes.order(o.id)),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              o.id,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: o.statusBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                o.status,
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: o.statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          o.date,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '${o.items} items',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatRs(o.total),
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.push(AppRoutes.track(o.id)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Track →',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _OrderCardData {
  const _OrderCardData({
    required this.id,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.items,
    required this.total,
  });

  final String id;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final int items;
  final num total;
}

// ─── Order Details ───────────────────────────────────────────────────────────

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Order placed', '17 Sep · 9:12 AM', true),
      ('Packed', '17 Sep · 10:40 AM', true),
      ('Out for delivery', '17 Sep · 2:05 PM', true),
      ('Delivered', 'Expected by 4:00 PM', false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Order Details',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderId,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '17 Sep 2026',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.push(AppRoutes.track(orderId)),
                        icon: const Icon(Icons.local_shipping_outlined, size: 16),
                        label: Text(
                          'Track',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _formCard(
                  children: [
                    Text(
                      'ORDER TIMELINE',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Timeline(steps: steps),
                  ],
                ),
                const SizedBox(height: 12),
                _formCard(
                  children: [
                    Text(
                      'ITEMS',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _orderItemRow('Organic Honey 500g', 2, 890),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _orderItemRow('Fresh Milk 1L', 1, 220),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _orderItemRow('Sourdough Loaf', 1, 350),
                  ],
                ),
                const SizedBox(height: 12),
                _formCard(
                  children: [
                    Text(
                      'SUMMARY',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _summaryRow('Subtotal', formatRs(2350)),
                    _summaryRow('Delivery', formatRs(150)),
                    _summaryRow('Discount', '−${formatRs(120)}'),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _summaryRow('Total', formatRs(2380), bold: true),
                  ],
                ),
                const SizedBox(height: 12),
                _formCard(
                  children: [
                    Text(
                      'ADDRESSES',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Shipping',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '23-B, Model Town Extension, Lahore',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Billing',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Same as shipping',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderItemRow(String name, int qty, num price) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$name × $qty',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          formatRs(price * qty),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 15 : 13,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: bold ? 15 : 13,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wishlist ────────────────────────────────────────────────────────────────

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _items = [
    ('Organic Honey 500g', 'GherTak GS', 890),
    ('Fresh Milk 1L', 'Dairy Farm', 220),
    ('Sourdough Loaf', 'Oven Fresh', 350),
    ('Green Tea Pack', 'Tea House', 640),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.wishlist,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'Your wishlist is empty',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.chipBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.textMuted,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'by ${item.$2}',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              item.$1,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRs(item.$3),
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart'),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Add to cart',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _items.removeAt(i)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Remove',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final _name = TextEditingController(text: 'Ahmed Ali');
  final _phone = TextEditingController(text: '+92 321 4567890');
  final _email = TextEditingController(text: 'ahmed@example.com');

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

  final _addresses = <_SavedAddress>[
    _SavedAddress(
      label: 'Home',
      line: '23-B, Model Town Extension, Block B, Lahore, Punjab — 54700',
      isDefault: true,
    ),
    _SavedAddress(
      label: 'Office',
      line: '12-A, Gulberg III, Main Boulevard, Lahore, Punjab — 54660',
    ),
  ];

  String? _avatarPath;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
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
          label: 'Update Profile',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated')),
            );
          },
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
          label: 'Update Password',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password updated')),
            );
          },
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
              decoration: const InputDecoration(hintText: 'Lahore'),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Phone'),
            TextField(
              controller: _addrPhone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            BrandGradientButton(
              label: 'Save Address',
              onPressed: () {
                if (_addrLabel.text.trim().isEmpty ||
                    _addrLine.text.trim().isEmpty) {
                  return;
                }
                setState(() {
                  _addresses.add(
                    _SavedAddress(
                      label: _addrLabel.text.trim(),
                      line:
                          '${_addrLine.text.trim()}${_addrCity.text.isEmpty ? '' : ', ${_addrCity.text.trim()}'}',
                    ),
                  );
                  _addrLabel.clear();
                  _addrLine.clear();
                  _addrCity.clear();
                  _addrPhone.clear();
                });
              },
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
        for (var i = 0; i < _addresses.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _addressCard(i, _addresses[i]),
        ],
      ],
    );
  }

  Widget _addressCard(int index, _SavedAddress a) {
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
                a.label,
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
            a.line,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!a.isDefault)
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (final x in _addresses) {
                        x.isDefault = false;
                      }
                      _addresses[index].isDefault = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Set as default',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => setState(() => _addresses.removeAt(index)),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedAddress {
  _SavedAddress({
    required this.label,
    required this.line,
    this.isDefault = false,
  });

  final String label;
  final String line;
  bool isDefault;
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

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const _txns = [
    (true, 'Cashback reward', '18 Sep 2026', 150),
    (false, 'Order GT-87102', '12 Sep 2026', 200),
    (true, 'Promo credit', '5 Sep 2026', 500),
    (false, 'Order GT-86044', '3 Sep 2026', 350),
    (true, 'Referral bonus', '1 Sep 2026', 100),
  ];

  @override
  Widget build(BuildContext context) {
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
                        'Rs 2,500',
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
                            child: _walletStat('Total Credited', 'Rs 3,400'),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            child: _walletStat('Total Debited', 'Rs 900'),
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
                for (final t in _txns) ...[
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
                            color: t.$1
                                ? AppColors.successSoft
                                : AppColors.errorSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            t.$1
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 18,
                            color: t.$1
                                ? AppColors.successText
                                : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.$2,
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${t.$1 ? 'Credit' : 'Debit'} · ${t.$3}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${t.$1 ? '+' : '−'}${formatRs(t.$4)}',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: t.$1
                                ? AppColors.successText
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = [
    (
      'N-1042',
      '18 Sep 2026',
      'Order out for delivery',
      'GT-88421 is on the way to your address.',
      'Orders',
      'Unread',
      true,
    ),
    (
      'N-1038',
      '17 Sep 2026',
      'Deal alert',
      '20% off bakery items today only.',
      'Promos',
      'Read',
      false,
    ),
    (
      'N-1021',
      '16 Sep 2026',
      'Wallet credited',
      'Rs 150 cashback added to your wallet.',
      'Wallet',
      'Unread',
      true,
    ),
    (
      'N-1005',
      '12 Sep 2026',
      'Order delivered',
      'GT-87102 was delivered successfully.',
      'Orders',
      'Read',
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.notifications,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = _items[i];
                final unread = n.$7;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 4,
                          color: unread
                              ? AppColors.info
                              : Colors.transparent,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      n.$1,
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      n.$2,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  n.$3,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.$4,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _pill(n.$5, AppColors.primarySoft,
                                        AppColors.primary),
                                    const SizedBox(width: 8),
                                    _pill(
                                      n.$6,
                                      unread
                                          ? AppColors.primarySoft
                                          : AppColors.chipBg,
                                      unread
                                          ? AppColors.info
                                          : AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Returns ─────────────────────────────────────────────────────────────────

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  static const _items = [
    (
      'GT-87102',
      '14 Sep 2026',
      'Full refund',
      1890,
      'Completed',
      AppColors.successText,
      AppColors.successSoft,
    ),
    (
      'GT-86044',
      '8 Sep 2026',
      'Partial refund',
      450,
      'Processed',
      AppColors.info,
      AppColors.primarySoft,
    ),
    (
      'GT-85210',
      '1 Sep 2026',
      'Exchange',
      0,
      'Rejected',
      AppColors.error,
      AppColors.errorSoft,
    ),
    (
      'GT-84888',
      '28 Aug 2026',
      'Full refund',
      920,
      'Pending',
      AppColors.warning,
      AppColors.warningSoft,
    ),
    (
      'GT-84102',
      '20 Aug 2026',
      'Partial refund',
      300,
      'Approved',
      AppColors.primary,
      AppColors.primarySoft,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.returns,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = _items[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            r.$1,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: r.$7,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              r.$5,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: r.$6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.$2,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            r.$3,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            r.$4 > 0 ? formatRs(r.$4) : '—',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ─── Track Order ─────────────────────────────────────────────────────────────

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  late final TextEditingController _tracking;
  bool _tracked = false;

  @override
  void initState() {
    super.initState();
    _tracking = TextEditingController(text: widget.orderId);
    _tracked = widget.orderId.isNotEmpty;
  }

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Order placed', '17 Sep · 9:12 AM', true),
      ('Packed', '17 Sep · 10:40 AM', true),
      ('Out for delivery', '17 Sep · 2:05 PM', true),
      ('Delivered', 'Expected by 4:00 PM', false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Track Your Order',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _formCard(
                  children: [
                    _fieldLabel('Tracking Number'),
                    TextField(
                      controller: _tracking,
                      decoration: const InputDecoration(
                        hintText: 'e.g. GT-88421',
                      ),
                    ),
                    const SizedBox(height: 16),
                    BrandGradientButton(
                      label: 'Track Order',
                      onPressed: () {
                        setState(() => _tracked = true);
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.contact),
                        child: Text(
                          'Contact support',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_tracked) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.successText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tracking found for ${_tracking.text.trim().isEmpty ? 'GT-88421' : _tracking.text.trim()}',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.successText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _tracking.text.trim().isEmpty
                              ? 'GT-88421'
                              : _tracking.text.trim(),
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Out for Delivery',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _formCard(
                    children: [
                      Text(
                        'ORDER TIMELINE',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Timeline(steps: steps),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<(String, String, bool)> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: steps[i].$3
                          ? AppColors.success
                          : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: steps[i].$3
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 36,
                      color: steps[i].$3
                          ? AppColors.success
                          : AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].$1,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: steps[i].$3
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        steps[i].$2,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

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
                                    const InputDecoration(hintText: 'Lahore'),
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

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.mode = 'qr'});

  /// `camera` | `qr`
  final String mode;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _busy = false;
  String? _previewPath;
  bool _awaitingConfirm = false;
  bool _handledBarcode = false;
  MobileScannerController? _scanner;

  bool get _isCamera => widget.mode == 'camera';

  @override
  void initState() {
    super.initState();
    if (!_isCamera) {
      _scanner = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.qrCode,
        ],
      );
    }
  }

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1280,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera unavailable: $e')),
      );
      setState(() => _busy = false);
      _goVisualSearch();
    }
  }

  void _goVisualSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Visual search: using your photo when backend is ready. Showing matching products for now.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
    context.pushReplacement(
      AppRoutes.productsQuery(search: 'milk'),
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
    setState(() => _busy = true);
    _scanner?.stop();
    final query = raw.length > 32 ? raw.substring(0, 32) : raw;
    context.pushReplacement(AppRoutes.productsQuery(search: query));
  }

  Future<void> _fallbackManualBarcode() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanner unavailable — showing sample results')),
    );
    context.pushReplacement(AppRoutes.productsQuery(search: 'rice'));
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
                              onPressed: _busy ? null : _goVisualSearch,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Search with this photo',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
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
                                border: Border.all(color: Colors.white, width: 4),
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
                      _busy ? 'Opening products…' : 'Point at a barcode to search',
                      style: GoogleFonts.manrope(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
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
      return Center(
        child: TextButton(
          onPressed: onErrorFallback,
          child: const Text('Continue without camera'),
        ),
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
                              TextButton(
                                onPressed: onErrorFallback,
                                child: Text(
                                  'Use sample scan',
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.of(context);
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.of(context).pop();
        router.push(AppRoutes.productsQuery(search: 'organic honey'));
      });
    });
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
                onPressed: () => Navigator.of(context).pop(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final h in [12.0, 22.0, 16.0, 28.0, 14.0, 24.0, 10.0])
                  Container(
                    width: 4,
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gradientMid,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Listening...',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Say the product name',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.white60,
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
