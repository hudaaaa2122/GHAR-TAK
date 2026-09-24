import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../data/models/models.dart';
import '../../shared/widgets.dart';

/// Same list as website `CancelOrderDialog`.
const cancelReasons = [
  'Changed mind or no longer needed',
  'Long delivery or pickup time vs expectations',
  'Missed delivery/pickup window',
  'Duplicate orders placed accidentally',
  'Pricing & Cost Concerns',
  'Quality & Freshness Concerns (Pre-Delivery)',
  'Address or Availability Mistakes',
  'Others',
];

Future<String?> showCancelOrderDialog(
  BuildContext context,
  OrderModel order,
) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _CancelOrderDialogContent(order: order),
  );
}

Future<void> showOrderCancelledSuccessDialog(
  BuildContext context, {
  required String tracking,
  VoidCallback? onGoToCancelled,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Order cancelled',
        style: AppFonts.style(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: Text(
        'Your order $tracking has been cancelled successfully.',
        style: AppFonts.style(height: 1.45, color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Close',
            style: AppFonts.style(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onGoToCancelled?.call();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.checkoutConfirm,
          ),
          child: Text(
            'Go to Cancelled',
            style: AppFonts.style(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CancelOrderDialogContent extends StatefulWidget {
  const _CancelOrderDialogContent({required this.order});

  final OrderModel order;

  @override
  State<_CancelOrderDialogContent> createState() =>
      _CancelOrderDialogContentState();
}

class _CancelOrderDialogContentState extends State<_CancelOrderDialogContent> {
  String? _selected;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  String? _resolvedReason() {
    if (_selected == null) return null;
    if (_selected == 'Others') {
      final t = _otherCtrl.text.trim();
      return t.isEmpty ? null : t;
    }
    return _selected;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final subtotal = order.subtotal ??
        order.items.fold<double>(0, (s, e) => s + e.lineTotal);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Cancel order',
        style: AppFonts.style(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reason for Cancellation *',
              style: AppFonts.style(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selected,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select a reason for cancellation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: cancelReasons
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: AppFonts.style(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
            ),
            if (_selected == 'Others') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otherCtrl,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'Please provide a detailed reason for cancelling this order.',
                  hintStyle: AppFonts.style(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${order.displayId}',
                    style: AppFonts.style(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.resolvedItemsCount} items · ${formatRs(order.displayTotal)}',
                    style: AppFonts.style(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (subtotal > 0)
                    Text(
                      'Subtotal ${formatRs(subtotal)}',
                      style: AppFonts.style(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Important: Cancelling cannot be undone. If payment was already made, refund timing depends on your payment method.',
                      style: AppFonts.style(
                        fontSize: 11,
                        color: AppColors.warning,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Keep Order',
            style: AppFonts.style(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () {
            final reason = _resolvedReason();
            if (reason == null) {
              showAppToast(context, 'Please select a cancellation reason');
              return;
            }
            Navigator.pop(context, reason);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: Text(
            'Confirm Cancellation',
            style: AppFonts.style(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
