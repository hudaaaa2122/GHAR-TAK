import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_routes.dart';
import '../../core/invoice/invoice_pdf.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/models.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../providers.dart';
import 'order_cancel_dialogs.dart';

bool canReturn(OrderModel o, SiteSettingsModel? s) =>
    o.canRequestReturnBase && (s?.isReturnAllowed(o.orderCompletedDate) ?? false);

bool canReview(OrderModel o, SiteSettingsModel? s) {
  if (!(s?.enableReviewPopup ?? false)) return false;
  if (!o.isCompleted) return false;
  return s?.isOrderReviewAllowed(o.reviewEligibleDate) ?? false;
}

Map<String, dynamic> _photoPayload(Map<String, dynamic> media) => {
      if (media['id'] != null) 'id': media['id'],
      'original': media['original']?.toString() ?? '',
      'thumbnail':
          media['thumbnail']?.toString() ?? media['original']?.toString() ?? '',
    };

/// Shared order timeline (also used by [TrackOrderScreen]).
class OrderDetailStatusTimeline extends StatelessWidget {
  const OrderDetailStatusTimeline({super.key, required this.steps});

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
                                ? AppColors.checkoutConfirm
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: steps[i].done
                                  ? AppColors.checkoutConfirm
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
                                  ? AppColors.checkoutConfirm
                                      .withValues(alpha: 0.35)
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
                            style: AppFonts.style(
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
                              style: AppFonts.style(
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

class OrderDetailWebsiteScreen extends ConsumerStatefulWidget {
  const OrderDetailWebsiteScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailWebsiteScreen> createState() =>
      _OrderDetailWebsiteScreenState();
}

class _OrderDetailWebsiteScreenState
    extends ConsumerState<OrderDetailWebsiteScreen> {
  bool _acting = false;

  Future<void> _openCancelDialog(OrderModel order) async {
    final reason = await showCancelOrderDialog(context, order);
    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _acting = true);
    try {
      await ref.read(orderRepositoryProvider).cancel(
            order.id,
            reason: reason,
            notifyCustomer: true,
          );
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      await showOrderCancelledSuccessDialog(
        context,
        tracking: order.displayId,
        onGoToCancelled: () => context.go(AppRoutes.orders),
      );
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (mounted) showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _openReturnDialog(
    OrderModel order, {
    OrderItemModel? item,
  }) async {
    final orderId = int.tryParse(order.id);
    if (orderId == null) {
      showAppToast(context, 'Invalid order id');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ReturnRequestDialog(
        order: order,
        item: item,
        uploadFile: (path) =>
            ref.read(accountRepositoryProvider).uploadMedia(path),
      ),
    );
    if (ok != true || !mounted) return;
    ref.invalidate(orderDetailProvider(widget.orderId));
    ref.invalidate(returnsProvider);
    showAppToast(context, 'Return request submitted', isError: false);
  }

  Future<void> _openReviewDialog(OrderModel order) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _OrderReviewDialog(
        order: order,
        uploadFile: (path) =>
            ref.read(accountRepositoryProvider).uploadMedia(path),
        onSubmitted: () {
          ref.invalidate(orderDetailProvider(widget.orderId));
        },
      ),
    );
  }

  void _goTrack(OrderModel order) {
    final id = (order.trackingNumber?.trim().isNotEmpty == true)
        ? order.trackingNumber!.trim()
        : order.id;
    context.push(AppRoutes.track(id));
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Order Details',
            onBack: () => context.pop(),
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
                        style: AppFonts.style(color: AppColors.textMuted),
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
              data: (order) {
                final returnEligible = canReturn(order, settings);
                final reviewEligible = canReview(order, settings);
                final showReviewAction =
                    (settings?.enableReviewPopup ?? false) &&
                        (reviewEligible || order.hasOrderReview);

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(orderDetailProvider(widget.orderId)),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _HeaderCard(
                        order: order,
                        acting: _acting,
                        showReviewAction: showReviewAction,
                        onTrack: () => _goTrack(order),
                        onCancel: order.canCancel
                            ? () => _openCancelDialog(order)
                            : null,
                        onReturn: returnEligible && !order.isReturn
                            ? () => _openReturnDialog(order)
                            : null,
                        onReview: showReviewAction
                            ? () => _openReviewDialog(order)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _StatusSummaryTiles(order: order),
                      const SizedBox(height: 12),
                      _ProcessingBanner(),
                      if (order.paymentProof.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _PaymentProofSection(urls: order.paymentProof),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Order Timeline',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OrderDetailStatusTimeline(steps: order.figmaTimeline),
                      const SizedBox(height: 16),
                      Text(
                        'Order Items',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _OrderItemsSection(
                        order: order,
                        returnEligible: returnEligible,
                        acting: _acting,
                        onReturnItem: (item) =>
                            _openReturnDialog(order, item: item),
                      ),
                      const SizedBox(height: 12),
                      _OrderSummarySection(
                        order: order,
                        returnEligible: returnEligible,
                        acting: _acting,
                        onReturnEntireOrder: returnEligible && !order.isReturn
                            ? () => _openReturnDialog(order)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      if (order.addressLine(order.shippingAddress) !=
                          null) ...[
                        _sectionHeading('Fulfillment Address'),
                        const SizedBox(height: 8),
                        _InfoCard(
                          text: order.addressLine(order.shippingAddress)!,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (order.addressLine(order.billingAddress) != null) ...[
                        _sectionHeading('Billing Address'),
                        const SizedBox(height: 8),
                        _InfoCard(
                          text: order.addressLine(order.billingAddress)!,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if ((order.orderNotes ?? '').trim().isNotEmpty) ...[
                        _sectionHeading('Order Notes'),
                        const SizedBox(height: 8),
                        _InfoCard(text: order.orderNotes!.trim()),
                        const SizedBox(height: 14),
                      ],
                      if ((order.fulfillmentName ?? '').trim().isNotEmpty) ...[
                        _sectionHeading('Fulfillment Officer'),
                        const SizedBox(height: 8),
                        _FulfillmentOfficerCard(order: order),
                        const SizedBox(height: 14),
                      ],
                      _sectionHeading('Invoice'),
                      const SizedBox(height: 8),
                      _SimpleInvoiceCard(order: order),
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

  Widget _sectionHeading(String text) => Text(
        text,
        style: AppFonts.style(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.order,
    required this.acting,
    required this.showReviewAction,
    required this.onTrack,
    this.onCancel,
    this.onReturn,
    this.onReview,
  });

  final OrderModel order;
  final bool acting;
  final bool showReviewAction;
  final VoidCallback onTrack;
  final VoidCallback? onCancel;
  final VoidCallback? onReturn;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final posted = formatOrderDateTime(order.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onTrack,
                      child: Text(
                        'Order ${order.displayId}',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.checkoutConfirm,
                          decoration: TextDecoration.underline,
                        ).copyWith(
                          decorationColor: AppColors.checkoutConfirm,
                        ),
                      ),
                    ),
                    if (posted.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Posted on $posted',
                        style: AppFonts.style(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
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
                  style: AppFonts.style(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onCancel != null)
                _HeaderIconAction(
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  tooltip: 'Cancel order',
                  onPressed: acting ? null : onCancel,
                ),
              if (order.isReturn)
                _HeaderIconAction(
                  icon: Icons.assignment_return,
                  color: AppColors.error.withValues(alpha: 0.45),
                  tooltip: 'Returned',
                  onPressed: null,
                )
              else if (onReturn != null)
                _HeaderIconAction(
                  icon: Icons.assignment_return_outlined,
                  color: AppColors.error,
                  tooltip: 'Return order',
                  onPressed: acting ? null : onReturn,
                ),
              if (showReviewAction)
                _HeaderIconAction(
                  icon: order.hasOrderReview
                      ? Icons.star
                      : Icons.star_outline,
                  color: AppColors.checkoutConfirm,
                  tooltip: order.hasOrderReview ? 'View review' : 'Leave review',
                  onPressed: acting ? null : onReview,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconAction extends StatelessWidget {
  const _HeaderIconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _StatusSummaryTiles extends StatelessWidget {
  const _StatusSummaryTiles({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final delivery = (order.shippingType?.trim().isNotEmpty == true)
        ? order.shippingType!.trim()
        : 'Standard Delivery';
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Order',
            value: order.statusLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Payment',
            value: order.paymentStatusLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Delivery',
            value: delivery,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.style(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Our order has been received and is being processed',
        style: AppFonts.style(
          fontSize: 13,
          height: 1.35,
          color: const Color(0xFF1E4B7A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaymentProofSection extends StatelessWidget {
  const _PaymentProofSection({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment screenshot',
            style: AppFonts.style(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: urls.map((raw) {
              final url = resolveMediaUrl(raw);
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: url.isEmpty
                      ? Container(color: AppColors.chipBg)
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image_outlined),
                        ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _OrderItemsSection extends StatelessWidget {
  const _OrderItemsSection({
    required this.order,
    required this.returnEligible,
    required this.acting,
    required this.onReturnItem,
  });

  final OrderModel order;
  final bool returnEligible;
  final bool acting;
  final void Function(OrderItemModel item) onReturnItem;

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
              style: AppFonts.style(color: AppColors.textMuted),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _OrderItemRow(
                item: items[i],
                returnEligible: returnEligible,
                acting: acting,
                onReturn: () => onReturnItem(items[i]),
              ),
              if (i < items.length - 1)
                Divider(height: 22, color: AppColors.borderLight),
            ],
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.returnEligible,
    required this.acting,
    required this.onReturn,
  });

  final OrderItemModel item;
  final bool returnEligible;
  final bool acting;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(item.image?.best);
    final reg = item.regularPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.chipBg,
                child: url.isEmpty
                    ? Icon(Icons.image_outlined,
                        color: AppColors.textMuted)
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
                    style: AppFonts.style(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  if ((item.variationLabel ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.variationLabel!,
                      style: AppFonts.style(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Qty: ${item.quantity}',
                    style: AppFonts.style(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatRs(item.price),
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.checkoutConfirm,
                        ),
                      ),
                      if (reg != null && reg > item.price)
                        Text(
                          formatRs(reg),
                          style: AppFonts.style(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              formatRs(item.lineTotal),
              style: AppFonts.style(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        if (returnEligible) ...[
          const SizedBox(height: 8),
          if (item.isReturned)
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Returned'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                minimumSize: const Size.fromHeight(36),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: acting ? null : onReturn,
              icon: const Icon(Icons.assignment_return_outlined, size: 16),
              label: const Text('Return Item'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(36),
              ),
            ),
        ],
      ],
    );
  }
}

class _OrderSummarySection extends StatelessWidget {
  const _OrderSummarySection({
    required this.order,
    required this.returnEligible,
    required this.acting,
    this.onReturnEntireOrder,
  });

  final OrderModel order;
  final bool returnEligible;
  final bool acting;
  final VoidCallback? onReturnEntireOrder;

  @override
  Widget build(BuildContext context) {
    final subtotal = order.subtotal ??
        order.items.fold<double>(0, (s, e) => s + e.lineTotal);
    final discount = order.discount ?? 0;
    final coupon = order.couponDiscount ?? 0;
    final delivery = order.deliveryFee;
    final tax = order.salesTax ?? 0;
    final wallet = order.walletAmountUsed ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order Summary',
            style: AppFonts.style(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _sumRow('Subtotal', formatRs(subtotal)),
          if (discount > 0)
            _sumRow(
              'Discount',
              '-${formatRs(discount)}',
              valueColor: AppColors.successText,
            ),
          if (coupon > 0)
            _sumRow(
              'Coupon Discount',
              '-${formatRs(coupon)}',
              valueColor: AppColors.successText,
            ),
          _sumRow(
            'Fulfillment Fee',
            delivery == null
                ? '—'
                : (delivery <= 0 ? 'COMPLIMENTARY' : formatRs(delivery)),
            valueColor:
                delivery != null && delivery <= 0 ? AppColors.successText : null,
          ),
          if (tax > 0) _sumRow('Tax', formatRs(tax)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.borderLight),
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
                formatRs(order.displayTotal),
                style: AppFonts.style(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.checkoutConfirm,
                ),
              ),
            ],
          ),
          if (wallet > 0) ...[
            const SizedBox(height: 8),
            _sumRow('Paid via wallet', formatRs(wallet)),
            _sumRow(
              'Paid total',
              formatRs(order.paidTotal ?? order.displayTotal),
            ),
          ],
          if (onReturnEntireOrder != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: acting ? null : onReturnEntireOrder,
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Return Entire Order'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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
            style: AppFonts.style(
              fontSize: AppFonts.body,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.style(
              fontWeight: FontWeight.w700,
              fontSize: AppFonts.body,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

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
        style: AppFonts.style(
          fontSize: 13,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _FulfillmentOfficerCard extends StatelessWidget {
  const _FulfillmentOfficerCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final avatar = resolveMediaUrl(order.fulfillmentAvatarUrl);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.chipBg,
            backgroundImage:
                avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
            child: avatar.isEmpty
                ? Icon(Icons.person_outline, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.fulfillmentName ?? '',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if ((order.fulfillmentEmail ?? '').isNotEmpty)
                  Text(
                    order.fulfillmentEmail!,
                    style: AppFonts.style(
                      fontSize: 12,
                      color: AppColors.textMuted,
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

class _SimpleInvoiceCard extends StatefulWidget {
  const _SimpleInvoiceCard({required this.order});

  final OrderModel order;

  @override
  State<_SimpleInvoiceCard> createState() => _SimpleInvoiceCardState();
}

class _SimpleInvoiceCardState extends State<_SimpleInvoiceCard> {
  bool _downloading = false;

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await shareOrderInvoicePdf(widget.order);
      if (mounted) {
        showAppToast(context, 'Invoice ready to share', isError: false);
      }
    } catch (_) {
      if (mounted) {
        showAppToast(context, 'Could not create invoice PDF');
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final subtotal = order.subtotal ??
        order.items.fold<double>(0, (s, e) => s + e.lineTotal);
    final bill = order.addressLine(order.billingAddress);
    final ship = order.addressLine(order.shippingAddress);
    final date = formatOrderDateTime(order.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Invoice #${order.displayId}',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _downloading ? null : _downloadPdf,
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(
                  _downloading ? 'Preparing…' : 'Download PDF',
                  style: AppFonts.style(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Date: $date',
              style: AppFonts.style(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (bill != null) ...[
            const SizedBox(height: 12),
            Text(
              'Bill to',
              style: AppFonts.style(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bill,
              style: AppFonts.style(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (ship != null) ...[
            const SizedBox(height: 10),
            Text(
              'Ship to',
              style: AppFonts.style(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ship,
              style: AppFonts.style(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: AppColors.borderLight),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} × ${item.quantity}',
                      style: AppFonts.style(fontSize: 12),
                    ),
                  ),
                  Text(
                    formatRs(item.lineTotal),
                    style: AppFonts.style(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Divider(color: AppColors.borderLight),
          _invoiceTotalRow('Subtotal', formatRs(subtotal)),
          _invoiceTotalRow('Total', formatRs(order.displayTotal), bold: true),
        ],
      ),
    );
  }

  Widget _invoiceTotalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppFonts.style(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.style(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              fontSize: 13,
              color: bold ? AppColors.checkoutConfirm : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Return dialog ───────────────────────────────────────────────────────────

class _ReturnRequestDialog extends StatefulWidget {
  const _ReturnRequestDialog({
    required this.order,
    required this.uploadFile,
    this.item,
  });

  final OrderModel order;
  final OrderItemModel? item;
  final Future<Map<String, dynamic>> Function(String path) uploadFile;

  @override
  State<_ReturnRequestDialog> createState() => _ReturnRequestDialogState();
}

class _ReturnRequestDialogState extends State<_ReturnRequestDialog> {
  final _reasonCtrl = TextEditingController();
  final _photos = <Map<String, dynamic>>[];
  bool _submitting = false;
  bool _uploading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final media = await widget.uploadFile(file.path);
      if (mounted) {
        setState(() {
          _photos.add(_photoPayload(media));
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        showAppToast(context, e.toString());
      }
    }
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      showAppToast(context, 'Return reason is required');
      return;
    }
    final orderId = int.tryParse(widget.order.id);
    if (orderId == null) {
      showAppToast(context, 'Invalid order id');
      return;
    }
    setState(() => _submitting = true);
    try {
      final item = widget.item;
      if (item != null) {
        final itemId = item.id;
        if (itemId == null) {
          throw ApiException('Missing order item id');
        }
        await ProviderScope.containerOf(context)
            .read(orderRepositoryProvider)
            .requestReturn(
              orderId: orderId,
              reason: reason,
              returnType: 'single_product',
              photos: _photos,
              items: [
                {
                  'order_item_id': itemId,
                  'quantity': item.quantity,
                  'reason': reason,
                },
              ],
            );
      } else {
        await ProviderScope.containerOf(context)
            .read(orderRepositoryProvider)
            .requestReturn(
              orderId: orderId,
              reason: reason,
              returnType: 'full_order',
              photos: _photos,
            );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (mounted) showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isItem = widget.item != null;
    return AlertDialog(
      title: Text(isItem ? 'Return item' : 'Return entire order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isItem)
              Text(
                widget.item!.name,
                style: AppFonts.style(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason for return *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Photos (optional)',
              style: AppFonts.style(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _photos)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resolveMediaUrl(p['thumbnail']?.toString()),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: AppColors.chipBg,
                      ),
                    ),
                  ),
                if (_photos.length < 5)
                  InkWell(
                    onTap: _uploading ? null : _addPhoto,
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _uploading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_a_photo_outlined),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.checkoutConfirm,
          ),
          child: Text(_submitting ? 'Submitting…' : 'Submit return'),
        ),
      ],
    );
  }
}

// ─── Review dialog ───────────────────────────────────────────────────────────

class _OrderReviewDialog extends StatefulWidget {
  const _OrderReviewDialog({
    required this.order,
    required this.uploadFile,
    required this.onSubmitted,
  });

  final OrderModel order;
  final Future<Map<String, dynamic>> Function(String path) uploadFile;
  final VoidCallback onSubmitted;

  @override
  State<_OrderReviewDialog> createState() => _OrderReviewDialogState();
}

class _OrderReviewDialogState extends State<_OrderReviewDialog> {
  Map<String, dynamic>? _existing;
  bool _loading = true;
  int _overall = 0;
  int _delivery = 0;
  int _packaging = 0;
  int _quality = 0;
  int _fulfillment = 0;
  final _commentCtrl = TextEditingController();
  final _fulfillmentCommentCtrl = TextEditingController();
  final _photos = <Map<String, dynamic>>[];
  bool _submitting = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.order.hasOrderReview) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await ProviderScope.containerOf(context)
          .read(orderRepositoryProvider)
          .getOrderReview(widget.order.id);
      if (mounted) {
        setState(() {
          _existing = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _fulfillmentCommentCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final media = await widget.uploadFile(file.path);
      if (mounted) {
        setState(() {
          _photos.add(_photoPayload(media));
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        showAppToast(context, e.toString());
      }
    }
  }

  Future<void> _submit() async {
    if (_overall < 1) {
      showAppToast(context, 'Overall rating is required');
      return;
    }
    final orderId = int.tryParse(widget.order.id);
    if (orderId == null) {
      showAppToast(context, 'Invalid order id');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ProviderScope.containerOf(context)
          .read(orderRepositoryProvider)
          .createOrderReview(
            orderId: orderId,
            rating: _overall,
            deliveryRating: _delivery > 0 ? _delivery : null,
            packagingRating: _packaging > 0 ? _packaging : null,
            productQualityRating: _quality > 0 ? _quality : null,
            fulfillmentRating:
                (widget.order.fulfillmentId ?? 0) > 0 && _fulfillment > 0
                    ? _fulfillment
                    : null,
            comment: _commentCtrl.text.trim(),
            fulfillmentComment: _fulfillmentCommentCtrl.text.trim(),
            photos: _photos,
          );
      widget.onSubmitted();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showAppToast(context, 'Thank you for your review', isError: false);
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (mounted) showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_existing != null) {
      return AlertDialog(
        title: const Text('Your review'),
        content: SingleChildScrollView(
          child: _ReadOnlyReviewBody(data: _existing!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    final showFulfillment = (widget.order.fulfillmentId ?? 0) > 0;

    return AlertDialog(
      title: const Text('Rate your order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StarPickerRow(label: 'Overall *', value: _overall, onPick: (v) {
              setState(() => _overall = v);
            }),
            _StarPickerRow(label: 'Delivery', value: _delivery, onPick: (v) {
              setState(() => _delivery = v);
            }),
            _StarPickerRow(label: 'Packaging', value: _packaging, onPick: (v) {
              setState(() => _packaging = v);
            }),
            _StarPickerRow(
              label: 'Product quality',
              value: _quality,
              onPick: (v) => setState(() => _quality = v),
            ),
            if (showFulfillment)
              _StarPickerRow(
                label: 'Fulfillment',
                value: _fulfillment,
                onPick: (v) => setState(() => _fulfillment = v),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (showFulfillment) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _fulfillmentCommentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Fulfillment comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Photos (optional)',
              style: AppFonts.style(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in _photos)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resolveMediaUrl(p['thumbnail']?.toString()),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                InkWell(
                  onTap: _uploading ? null : _addPhoto,
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _uploading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Icon(Icons.add_a_photo_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.checkoutConfirm,
          ),
          child: Text(_submitting ? 'Submitting…' : 'Submit'),
        ),
      ],
    );
  }
}

class _StarPickerRow extends StatelessWidget {
  const _StarPickerRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final int value;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.style(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          for (var i = 1; i <= 5; i++)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => onPick(i),
              icon: Icon(
                i <= value ? Icons.star : Icons.star_border,
                color: AppColors.checkoutConfirm,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyReviewBody extends StatelessWidget {
  const _ReadOnlyReviewBody({required this.data});

  final Map<String, dynamic> data;

  int _rating(String key) {
    final v = data[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _readRow('Overall', _rating('rating')),
        if (_rating('delivery_rating') > 0)
          _readRow('Delivery', _rating('delivery_rating')),
        if (_rating('packaging_rating') > 0)
          _readRow('Packaging', _rating('packaging_rating')),
        if (_rating('product_quality_rating') > 0)
          _readRow('Product quality', _rating('product_quality_rating')),
        if (_rating('fulfillment_rating') > 0)
          _readRow('Fulfillment', _rating('fulfillment_rating')),
        if ((data['comment']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            data['comment'].toString(),
            style: AppFonts.style(fontSize: 13, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _readRow(String label, int stars) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppFonts.style(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= stars ? Icons.star : Icons.star_border,
              size: 18,
              color: AppColors.checkoutConfirm,
            ),
        ],
      ),
    );
  }
}
