import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_fonts.dart';

import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/models.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../providers.dart';
import 'order_detail_website.dart';

// ─── Order Details (website parity) ──────────────────────────────────────────

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderDetailWebsiteScreen(orderId: orderId);
  }
}

// ─── Returns (live API) ──────────────────────────────────────────────────────

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(returnsProvider);
    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.returns,
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
                        style: AppFonts.style(color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(returnsProvider),
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
                      'No return or refund requests yet',
                      style: AppFonts.style(color: AppColors.textMuted),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(returnsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = items[i];
                      final colors = _returnStatusColors(r.statusLabel);
                      return InkWell(
                        onTap: r.orderId != null
                            ? () => context.push(AppRoutes.order('${r.orderId}'))
                            : null,
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
                                  Expanded(
                                    child: Text(
                                      r.displayOrder,
                                      style: AppFonts.style(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.$2,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      r.statusLabel,
                                      style: AppFonts.style(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: colors.$1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatOrderDateTime(r.createdAt),
                                style: AppFonts.style(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.typeLabel,
                                      style: AppFonts.style(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    (r.refundAmount ?? 0) > 0
                                        ? formatRs(r.refundAmount!)
                                        : '—',
                                    style: AppFonts.style(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if ((r.reason ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  r.reason!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.style(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
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

  (Color, Color) _returnStatusColors(String label) {
    final s = label.toLowerCase();
    if (s.contains('complet') || s.contains('approv')) {
      return (AppColors.successText, AppColors.successSoft);
    }
    if (s.contains('reject') || s.contains('fail')) {
      return (AppColors.error, AppColors.errorSoft);
    }
    if (s.contains('process')) {
      return (AppColors.info, AppColors.primarySoft);
    }
    return (AppColors.warning, AppColors.warningSoft);
  }
}

// ─── Track Order (Figma) ─────────────────────────────────────────────────────

class TrackOrderScreen extends ConsumerStatefulWidget {
  const TrackOrderScreen({super.key, this.orderId = ''});

  final String orderId;

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  late final TextEditingController _tracking;
  OrderModel? _order;
  String? _error;
  bool _loading = false;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _tracking = TextEditingController(text: widget.orderId);
    if (widget.orderId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _tracking.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final id = _tracking.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Enter a tracking number or order id');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _found = false;
    });
    try {
      final order = await ref.read(orderRepositoryProvider).read(id);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _found = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _order = null;
        _loading = false;
        _found = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _order = null;
        _loading = false;
        _found = false;
      });
    }
  }

  String get _statusMessage {
    final o = _order;
    if (o == null) return '';
    final k = o.statusKey;
    if (k.contains('deliver') || k.contains('completed')) {
      return 'Your order has been completed. Enjoy!';
    }
    if (k.contains('out-for-delivery') || k.contains('out for')) {
      return 'Your order is on the way to you.';
    }
    if (k.contains('processing') || k.contains('packed')) {
      return 'We are preparing your order for shipment.';
    }
    return 'We have received your order and will start preparing it soon.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Track Your Order',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Text(
                  'Enter your tracking number to get real-time updates on your order status.',
                  style: AppFonts.style(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tracking Number',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tracking,
                  decoration: InputDecoration(
                    hintText: 'e.g. GTISB-2026-08-12-AF29DEAA',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _lookup,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _loading ? 'Looking up…' : 'Track Order',
                      style: AppFonts.style(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.contact),
                    child: Text(
                      "Can't find your tracking number? Contact Support.",
                      textAlign: TextAlign.center,
                      style: AppFonts.style(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppFonts.style(color: AppColors.error),
                  ),
                ],
                if (_found && _order != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.successText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order found successfully',
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.successText,
                                ),
                              ),
                              Text(
                                'Here are the latest details for your shipment.',
                                style: AppFonts.style(
                                  fontSize: 12,
                                  color: AppColors.successText,
                                ),
                              ),
                            ],
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${_order!.displayId}',
                          style: AppFonts.style(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total  ${formatRs(_order!.total ?? 0)}',
                          style: AppFonts.style(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if ((_order!.createdAt ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Placed on ${formatOrderDateTime(_order!.createdAt)}',
                            style: AppFonts.style(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _pill(
                              'Order: ${_order!.statusLabel}',
                              AppColors.primarySoft,
                              AppColors.primary,
                            ),
                            _pill(
                              _order!.paymentLabel,
                              const Color(0xFFEEF0F3),
                              AppColors.textSecondary,
                            ),
                          ],
                        ),
                        if (_order!.deliveryTime?.trim().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _order!.deliveryTime!,
                                    style: AppFonts.style(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusMessage,
                            style: AppFonts.style(
                              fontSize: 13,
                              height: 1.35,
                              color: const Color(0xFF1E4B7A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order Timeline',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OrderDetailStatusTimeline(steps: _order!.figmaTimeline),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.order(_order!.id)),
                    child: Text(
                      'View full order details',
                      style: AppFonts.style(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
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

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppFonts.style(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}
