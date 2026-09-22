import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../core/location/delivery_location.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../providers.dart';

// ─── Order Details (Figma) ───────────────────────────────────────────────────

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _acting = false;

  Future<void> _cancelOrder(OrderModel order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Cancel order'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(hintText: 'Reason (optional)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep order'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Cancel order'),
            ),
          ],
        );
      },
    );
    if (reason == null || !mounted) return;
    setState(() => _acting = true);
    try {
      await ref.read(orderRepositoryProvider).cancel(
            order.id,
            reason: reason.isEmpty ? null : reason,
          );
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      showAppToast(context, 'Order cancelled', isError: false);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (mounted) showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _requestRefund(OrderModel order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController(text: 'Customer requested return');
        return AlertDialog(
          title: const Text('Request refund / return'),
          content: TextField(
            controller: c,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Reason for return'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    final orderId = int.tryParse(order.id);
    if (orderId == null) {
      showAppToast(context, 'Invalid order id');
      return;
    }
    setState(() => _acting = true);
    try {
      await ref.read(orderRepositoryProvider).requestReturn(
            orderId: orderId,
            reason: reason,
          );
      ref.invalidate(returnsProvider);
      if (!mounted) return;
      showAppToast(context, 'Return request submitted', isError: false);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (mounted) showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _updateOrder(OrderModel order) async {
    final notesCtrl = TextEditingController(text: order.orderNotes ?? '');
    final timeCtrl = TextEditingController(text: order.deliveryTime ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You can update notes or delivery slot while the order is still processing.',
              style: GoogleFonts.manrope(fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(
                labelText: 'Delivery time',
                hintText: 'e.g. Morning · 8.00 AM - 11.00 AM',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Order notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final items = order.items
        .where((i) => i.productId != null)
        .map(
          (i) => {
            'product_id': i.productId,
            if (i.variationOptionId != null)
              'variation_option_id': i.variationOptionId,
            'quantity': i.quantity,
          },
        )
        .toList();
    if (items.isEmpty) {
      showAppToast(
        context,
        'Cannot update items for this order. Try cancelling and reordering.',
      );
      return;
    }

    setState(() => _acting = true);
    try {
      await ref.read(orderRepositoryProvider).customerEdit(
            orderId: order.id,
            items: items,
            deliveryTime: timeCtrl.text.trim().isEmpty
                ? null
                : timeCtrl.text.trim(),
            orderNotes:
                notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      showAppToast(context, 'Order updated', isError: false);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (mounted) showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reorder(OrderModel order) async {
    var added = 0;
    for (final item in order.items) {
      if (item.productId == null) continue;
      try {
        await ref.read(cartProvider.notifier).add(
              ProductModel(
                id: item.productId!,
                name: item.name,
                price: item.price,
                image: item.image,
              ),
              qty: item.quantity,
            );
        added++;
      } catch (_) {}
    }
    if (!mounted) return;
    if (added == 0) {
      showAppToast(context, 'Could not add items to cart');
      return;
    }
    showAppToast(context, 'Added to cart', isError: false);
    context.push(AppRoutes.cart);
  }

  Future<void> _share(OrderModel order) async {
    final text =
        'Gher Tak order ${order.displayId}\nStatus: ${order.statusLabel}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppToast(context, 'Order details copied', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Order Details',
            onBack: () => context.pop(),
            trailing: orderAsync.maybeWhen(
              data: (order) => IconButton(
                onPressed: () => _share(order),
                icon: const Icon(Icons.ios_share_rounded, size: 22),
              ),
              orElse: () => null,
            ),
          ),
          Expanded(
            child: orderAsync.when(
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
                        onPressed: () => ref
                            .invalidate(orderDetailProvider(widget.orderId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (order) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(orderDetailProvider(widget.orderId)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _OrderHeroCard(
                      order: order,
                      onTrack: () => context.push(AppRoutes.track(order.id)),
                    ),
                    const SizedBox(height: 12),
                    _OrderQuickFacts(order: order),
                    const SizedBox(height: 16),
                    Text(
                      'Order Status',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OrderStatusTimeline(steps: order.figmaTimeline),
                    const SizedBox(height: 16),
                    Text(
                      'Order Items',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OrderItemsCard(
                      order: order,
                      onReorder: () => _reorder(order),
                    ),
                    const SizedBox(height: 12),
                    _OrderSummaryCard(order: order),
                    if (order.canUpdate ||
                        order.canCancel ||
                        order.canRequestReturn) ...[
                      const SizedBox(height: 12),
                      _OrderActionsCard(
                        order: order,
                        acting: _acting,
                        onUpdate: () => _updateOrder(order),
                        onCancel: () => _cancelOrder(order),
                        onRefund: () => _requestRefund(order),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go(AppRoutes.home),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continue shopping',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.go(AppRoutes.orders),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'All orders',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (order.addressLine(order.shippingAddress) != null) ...[
                      Text(
                        'Shipping Address',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AddressCard(
                        text: order.addressLine(order.shippingAddress)!,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (order.addressLine(order.billingAddress) != null) ...[
                      Text(
                        'Billing Address',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AddressCard(
                        text: order.addressLine(order.billingAddress)!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHeroCard extends StatelessWidget {
  const _OrderHeroCard({required this.order, required this.onTrack});

  final OrderModel order;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final placed = formatOrderDateTime(order.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Order ${order.displayId}',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusLabel,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (placed.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Placed on $placed',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTrack,
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: Text(
                'Track order',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderQuickFacts extends StatelessWidget {
  const _OrderQuickFacts({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _fact('Total amount', formatRs(order.total ?? 0)),
              ),
              Expanded(
                child: _fact('Items', '${order.resolvedItemsCount}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _fact(
                  'Delivery window',
                  (order.deliveryTime?.trim().isNotEmpty == true)
                      ? order.deliveryTime!
                      : '—',
                ),
              ),
              Expanded(
                child: _fact('Payment method', order.paymentLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fact(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _OrderStatusTimeline extends StatelessWidget {
  const _OrderStatusTimeline({required this.steps});

  final List<OrderTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: steps[i].done
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: steps[i].done
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: steps[i].done
                                  ? AppColors.primary.withValues(alpha: 0.35)
                                  : AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < steps.length - 1 ? 18 : 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].title,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: steps[i].done
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                          if ((steps[i].subtitle ?? '').isNotEmpty)
                            Text(
                              steps[i].subtitle!,
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
            ),
        ],
      ),
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.order, required this.onReorder});

  final OrderModel order;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            Text(
              'No item details available',
              style: GoogleFonts.manrope(color: AppColors.textMuted),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _OrderItemTile(item: items[i]),
              if (i < items.length - 1)
                const Divider(height: 22, color: AppColors.borderLight),
            ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onReorder,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(
                'Buy these items again',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(item.image?.best);
    final saved = item.savedAmount;
    final reg = item.regularPrice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 56,
            height: 56,
            color: AppColors.chipBg,
            child: url.isEmpty
                ? const Icon(Icons.image_outlined, color: AppColors.textMuted)
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
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    formatRs(item.price),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  if (reg != null && reg > item.price)
                    Text(
                      formatRs(reg),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (saved > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Saved ${formatRs(saved)}',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.successText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: ${item.quantity}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final discount = order.resolvedDiscount;
    final delivery = order.deliveryFee;
    final subtotal = order.subtotal ??
        order.items.fold<double>(0, (s, e) => s + e.lineTotal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _sumRow('Subtotal', formatRs(subtotal)),
          if (discount > 0)
            _sumRow(
              'Discount',
              '-${formatRs(discount)}',
              valueColor: AppColors.successText,
            ),
          _sumRow(
            'Delivery',
            (delivery == null)
                ? '—'
                : (delivery <= 0 ? 'Free' : formatRs(delivery)),
            valueColor: (delivery != null && delivery <= 0)
                ? AppColors.successText
                : null,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.borderLight),
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
                formatRs(order.total ?? subtotal),
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payments_outlined,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                order.paymentLabel,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActionsCard extends StatelessWidget {
  const _OrderActionsCard({
    required this.order,
    required this.acting,
    required this.onUpdate,
    required this.onCancel,
    required this.onRefund,
  });

  final OrderModel order;
  final bool acting;
  final VoidCallback onUpdate;
  final VoidCallback onCancel;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order actions',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          if (order.canUpdate)
            OutlinedButton.icon(
              onPressed: acting ? null : onUpdate,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Update order'),
            ),
          if (order.canCancel) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: acting ? null : onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ],
          if (order.canRequestReturn) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: acting ? null : onRefund,
              icon: const Icon(Icons.currency_exchange, size: 18),
              label: const Text('Request refund / return'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 13,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Returns (live API) ──────────────────────────────────────────────────────

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(returnsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
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
                        style: GoogleFonts.manrope(color: AppColors.textMuted),
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
                      style: GoogleFonts.manrope(color: AppColors.textMuted),
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
                                      style: GoogleFonts.manrope(
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
                                      style: GoogleFonts.manrope(
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
                                style: GoogleFonts.manrope(
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
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    (r.refundAmount ?? 0) > 0
                                        ? formatRs(r.refundAmount!)
                                        : '—',
                                    style: GoogleFonts.manrope(
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
                                  style: GoogleFonts.manrope(
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
      return 'Your order has been delivered. Enjoy!';
    }
    if (k.contains('out-for-delivery') || k.contains('out for')) {
      return 'Your order is out for delivery and on its way to you.';
    }
    if (k.contains('processing') || k.contains('packed')) {
      return 'We are preparing your order for shipment.';
    }
    return 'We have received your order and will start preparing it soon.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
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
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tracking Number',
                  style: GoogleFonts.manrope(
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
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
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
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
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
                      style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(color: AppColors.error),
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
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.successText,
                                ),
                              ),
                              Text(
                                'Here are the latest details for your shipment.',
                                style: GoogleFonts.manrope(
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
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total  ${formatRs(_order!.total ?? 0)}',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if ((_order!.createdAt ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Placed on ${formatOrderDateTime(_order!.createdAt)}',
                            style: GoogleFonts.manrope(
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
                                    style: GoogleFonts.manrope(
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
                            style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _OrderStatusTimeline(steps: _order!.figmaTimeline),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.order(_order!.id)),
                    child: Text(
                      'View full order details',
                      style: GoogleFonts.manrope(
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
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}
