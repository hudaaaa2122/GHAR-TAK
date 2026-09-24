import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../core/network/api_response.dart';
import '../../core/order/order_edit_eligibility.dart';
import '../../core/order/order_tab_helpers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/models.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../providers.dart';
import 'edit_order_dialog.dart';
import 'order_cancel_dialogs.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  String _tab = 'all';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final reason = await showCancelOrderDialog(context, order);
    if (reason == null || reason.isEmpty || !mounted) return;

    try {
      await ref.read(orderRepositoryProvider).cancel(
            order.id,
            reason: reason,
            notifyCustomer: true,
          );
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      await showOrderCancelledSuccessDialog(
        context,
        tracking: order.displayId,
        onGoToCancelled: () => setState(() => _tab = 'cancelled'),
      );
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (mounted) showAppToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'My Orders',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: user == null ? _guestPrompt(context) : _loggedInBody(),
          ),
        ],
      ),
    );
  }

  Widget _guestPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              'Please login first if you want to see your orders',
              textAlign: TextAlign.center,
              style: AppFonts.style(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            WebPrimaryButton(
              label: 'Login',
              onPressed: () => context.push(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loggedInBody() {
    return ref.watch(ordersProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    friendlyUserMessage(
                      e,
                      fallback:
                          'Please login first if you want to see your orders',
                    ),
                    textAlign: TextAlign.center,
                    style: AppFonts.style(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      final msg = e.toString().toLowerCase();
                      if (msg.contains('auth') || msg.contains('401')) {
                        context.push(AppRoutes.login);
                      } else {
                        ref.invalidate(ordersProvider);
                      }
                    },
                    child: Text(
                      e.toString().toLowerCase().contains('auth') ||
                              e.toString().toLowerCase().contains('401')
                          ? 'Login'
                          : 'Retry',
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (orders) => Column(
            children: [
              _tabsRow(orders),
              _searchField(),
              Expanded(child: _ordersList(orders)),
            ],
          ),
        );
  }

  Widget _tabsRow(List<OrderModel> orders) {
    final counts = orderTabCounts(orders);
    final p = AppPalette.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          bottom: BorderSide(color: p.border),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: orderPageTabs.length,
        itemBuilder: (context, i) {
          final tab = orderPageTabs[i];
          return _OrderTabChip(
            label: tab.$2,
            count: counts[tab.$1] ?? 0,
            selected: _tab == tab.$1,
            onTap: () => setState(() => _tab = tab.$1),
          );
        },
      ),
    );
  }

  Widget _searchField() {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: AppFonts.style(fontSize: 13, color: p.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by order number or product',
          hintStyle: AppFonts.style(fontSize: 13, color: p.textMuted),
          prefixIcon: Icon(Icons.search, color: p.textMuted),
          filled: true,
          fillColor: p.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
        ),
      ),
    );
  }

  Widget _ordersList(List<OrderModel> allOrders) {
    var list = filterOrdersByTab(allOrders, _tab);
    list = searchOrders(list, _searchQuery);

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No orders found',
                style: AppFonts.style(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppPalette.of(context).textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filter options.',
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  fontSize: 13,
                  color: AppPalette.of(context).textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ordersProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _MyOrderCard(
          order: list[i],
          onCancel: () => _cancelOrder(list[i]),
        ),
      ),
    );
  }
}

class _OrderTabChip extends StatelessWidget {
  const _OrderTabChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  static const _trackTeal = Color(0xFF11788C);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? _trackTeal : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.style(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: selected ? _trackTeal : p.textSecondary,
              ),
            ),
            if (count > 0 || label == 'All') ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _trackTeal,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: AppFonts.style(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyOrderCard extends ConsumerWidget {
  const _MyOrderCard({
    required this.order,
    required this.onCancel,
  });

  final OrderModel order;
  final VoidCallback onCancel;

  static const _trackTeal = Color(0xFF11788C);
  static const _editGreen = Color(0xFF15824B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = badgeColorsForOrder(order);
    final canEdit = canEditOrder(
      status: order.status,
      deliveryTime: order.deliveryTime,
      createdAt: order.createdAt,
    );
    final showTrack = !order.isCancelled && !order.isRefunded;

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.of(context).border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.order(order.id)),
                        child: Text(
                          order.displayId,
                          style: AppFonts.style(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _trackTeal,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badge.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: AppFonts.style(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badge.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((order.createdAt ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatOrderDateTime(order.createdAt),
                    style: AppFonts.style(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          ...order.items.map(
            (item) => _OrderLineItem(item: item),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Text(
                  'Total:',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  formatRs(order.displayTotal),
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canEdit)
                  _actionButton(
                    label: 'Edit order',
                    icon: Icons.edit_outlined,
                    filled: true,
                    color: _editGreen,
                    onPressed: () => showEditOrderDialog(context, ref, order),
                  ),
                _actionButton(
                  label: 'View details',
                  icon: Icons.receipt_long_outlined,
                  outline: true,
                  onPressed: () => context.push(AppRoutes.order(order.id)),
                ),
                if (showTrack)
                  _actionButton(
                    label: 'Track order',
                    icon: Icons.local_shipping_outlined,
                    filled: true,
                    color: _trackTeal,
                    onPressed: () {
                      final id = order.trackingNumber?.isNotEmpty == true
                          ? order.trackingNumber!
                          : order.id;
                      context.push(AppRoutes.track(id));
                    },
                  ),
                if (order.canCancel)
                  _actionButton(
                    label: 'Cancel order',
                    icon: Icons.cancel_outlined,
                    outline: true,
                    danger: true,
                    onPressed: onCancel,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool filled = false,
    bool outline = false,
    bool danger = false,
    Color? color,
  }) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color ?? _trackTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: AppFonts.style(fontWeight: FontWeight.w700, fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? AppColors.error : AppColors.textPrimary,
        side: BorderSide(
          color: danger ? AppColors.error : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: AppFonts.style(fontWeight: FontWeight.w700, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _OrderLineItem extends StatelessWidget {
  const _OrderLineItem({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(item.image?.best);
    final metaParts = <String>[
      if ((item.variationLabel ?? '').isNotEmpty) item.variationLabel!,
      'Qty ${item.quantity}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 64,
              height: 64,
              color: AppColors.chipBg,
              child: url.isEmpty
                  ? Icon(Icons.image_outlined, color: AppColors.textMuted)
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.image_outlined),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metaParts.join(' · '),
                  style: AppFonts.style(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRs(item.lineTotal),
            style: AppFonts.style(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
