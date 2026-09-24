import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../core/network/api_response.dart';
import '../../core/order/edit_order_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../data/models/models.dart';
import '../../shared/widgets.dart';
import '../providers.dart';

Future<void> showEditOrderDialog(
  BuildContext context,
  WidgetRef ref,
  OrderModel order,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditOrderSheet(order: order),
  );
}

class _EditOrderSheet extends ConsumerStatefulWidget {
  const _EditOrderSheet({required this.order});

  final OrderModel order;

  @override
  ConsumerState<_EditOrderSheet> createState() => _EditOrderSheetState();
}

class _EditOrderSheetState extends ConsumerState<_EditOrderSheet> {
  late EditOrderSession _session;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _session = createSessionFromOrder(widget.order);
    setAllowSubstitution(true);
  }

  bool get _hasChanges => hasEditItemsChanged(_session);

  void _updateQty(String key, int qty) {
    if (qty < 1) return;
    setState(() {
      _session = _session.copyWith(
        items: _session.items
            .map(
              (e) => e.key == key
                  ? e.copyWith(quantity: qty.clamp(1, e.maxQuantity))
                  : e,
            )
            .toList(),
      );
    });
  }

  void _remove(String key) {
    if (_session.items.length <= 1) {
      showAppToast(
        context,
        'Order must keep at least one product. Cancel the order instead.',
      );
      return;
    }
    setState(() {
      _session = _session.copyWith(
        items: _session.items.where((e) => e.key != key).toList(),
      );
    });
  }

  Future<bool> _loadIntoCart({required bool detailsOnly}) async {
    if (_session.items.isEmpty) {
      showAppToast(context, 'Add at least one product before continuing.');
      return false;
    }
    final next = _session.copyWith(detailsOnly: detailsOnly);
    await ref.read(editOrderSessionProvider.notifier).setSession(next);

    // Match website EditOrderDialog → POST /cart/bulk-create
    final payload = next.items
        .map(
          (item) => <String, dynamic>{
            'product_id': item.productId,
            'shop_id': item.shopId ?? 0,
            'quantity': item.quantity,
            'variation_option_id': item.variationOptionId,
          },
        )
        .toList();

    await ref.read(cartProvider.notifier).bulkReplaceFromEdit(payload);
    return true;
  }

  Future<void> _continueShopping() async {
    setState(() => _busy = 'continue');
    try {
      final ok = await _loadIntoCart(detailsOnly: false);
      if (!ok || !mounted) return;
      showAppToast(
        context,
        'Order items moved to your cart. Add more products anytime.',
        isError: false,
      );
      Navigator.pop(context);
      context.go(AppRoutes.home);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (mounted) showAppToast(context, 'Failed to load order items into cart');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _editDetails() async {
    setState(() => _busy = 'details');
    try {
      final ok = await _loadIntoCart(detailsOnly: true);
      if (!ok || !mounted) return;
      Navigator.pop(context);
      context.push(AppRoutes.checkout);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (_) {
      if (mounted) showAppToast(context, 'Failed to open order details');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _proceedCheckout() async {
    if (!_hasChanges) {
      showAppToast(context, 'Change items in this order before continuing.');
      return;
    }
    setState(() => _busy = 'proceed');
    try {
      final ok = await _loadIntoCart(detailsOnly: false);
      if (!ok || !mounted) return;
      Navigator.pop(context);
      context.go(AppRoutes.cart);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (_) {
      if (mounted) showAppToast(context, 'Failed to load order items into cart');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final busy = _busy != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14677D), Color(0xFF1B8A6E), Color(0xFF2E9E54)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Edit Your Order',
                    style: AppFonts.style(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _session.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No products in this edit. Continue shopping to add products.',
                        textAlign: TextAlign.center,
                        style: AppFonts.style(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    itemCount: _session.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = _session.items[i];
                      return _EditItemCard(
                        item: item,
                        onInc: () => _updateQty(item.key, item.quantity + 1),
                        onDec: () => _updateQty(item.key, item.quantity - 1),
                        onRemove: () => _remove(item.key),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : _continueShopping,
                  icon: _busy == 'continue'
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Continue shopping'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF11788C),
                    side: const BorderSide(color: Color(0xFF11788C)),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy || _session.items.isEmpty
                            ? null
                            : _editDetails,
                        icon: _busy == 'details'
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit details'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ||
                                _session.items.isEmpty ||
                                !_hasChanges
                            ? null
                            : _proceedCheckout,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF11788C),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _busy == 'proceed'
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Proceed to checkout',
                                style: AppFonts.style(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
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
}

class _EditItemCard extends StatelessWidget {
  const _EditItemCard({
    required this.item,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  });

  final EditOrderDraftItem item;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(item.image);
    final subtotal = item.unitPrice * item.quantity;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: AppColors.chipBg,
              child: url.isEmpty
                  ? const Icon(Icons.image_outlined)
                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRs(item.unitPrice),
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyBtn(label: '−', onTap: onDec, enabled: item.quantity > 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: AppFonts.style(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _QtyBtn(
                      label: '+',
                      onTap: onInc,
                      enabled: item.quantity < item.maxQuantity,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ],
                ),
                Text(
                  'Subtotal ${formatRs(subtotal)}',
                  style: AppFonts.style(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
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

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray75,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              label,
              style: AppFonts.style(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: enabled ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
