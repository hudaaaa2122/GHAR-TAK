import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../core/network/api_response.dart';
import '../../core/order/edit_order_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../data/models/models.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../providers.dart';
import 'payment_gateway_api.dart';
import 'payment_modals.dart';
import 'payment_webview_screen.dart';

/// Full checkout payment step — methods from settings + website gateway flows.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _api = PaymentGatewayApi();
  final _walletCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();

  String? _selectedId;
  bool _useWallet = false;
  bool _placing = false;
  List<Map<String, dynamic>>? _paymentProof;
  String? _paymentReference;

  @override
  void dispose() {
    _walletCtrl.dispose();
    _cnicCtrl.dispose();
    super.dispose();
  }

  List<PaymentMethodConfig> _methods(SiteSettingsModel? settings) {
    return PaymentMethodConfig.activeSorted(
      settings?.paymentGateway ?? PaymentMethodConfig.fallbackPaymentMethods,
    );
  }

  PaymentMethodConfig? _selected(List<PaymentMethodConfig> methods) {
    if (methods.isEmpty) return null;
    final id = _selectedId ?? PaymentMethodConfig.defaultId(methods);
    for (final m in methods) {
      if (m.id == id) return m;
    }
    return methods.first;
  }

  IconData _iconFor(PaymentMethodConfig m) {
    if (m.isCashOnDelivery) return Icons.payments_outlined;
    if (m.isJazzCash || m.isJazzCashCard) {
      return Icons.account_balance_wallet_outlined;
    }
    if (m.isEasyPaisa) return Icons.phone_android_outlined;
    if (m.isPayFast) return Icons.credit_card_outlined;
    if (m.isBankTransfer) return Icons.upload_file_outlined;
    return Icons.payment_outlined;
  }

  double _cartTotal() {
    final cart = ref.read(cartProvider).valueOrNull ?? [];
    return cart.fold<double>(
      0,
      (s, e) => s + e.product.displayPrice * e.quantity,
    );
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    final editSession = ref.read(editOrderSessionProvider);
    final draft = ref.read(checkoutDraftProvider);
    if (draft == null || draft.shippingAddress.isEmpty) {
      showAppToast(context, 'Please select a drop-off address');
      context.go(AppRoutes.checkout);
      return;
    }

    final settings = ref.read(settingsProvider).valueOrNull;
    final methods = _methods(settings);
    final method = _selected(methods);
    if (method == null || !method.enabled) {
      showAppToast(context, 'Please select a payment method');
      return;
    }

    final total = _cartTotal();
    final name = draft.shippingAddress['name']?.toString() ?? 'Customer';
    final email = draft.shippingAddress['email']?.toString() ??
        ref.read(authStateProvider).valueOrNull?.email ??
        'customer@ghertak.com';
    final phone = draft.shippingAddress['phone']?.toString() ?? '';

    String? paymentId;
    Map<String, dynamic>? paymentResponse;
    List<Map<String, dynamic>>? paymentProof = _paymentProof;
    var gateway = method.id;

    // —— Cash on delivery ——
    if (method.isCashOnDelivery) {
      // place directly
    }
    // —— Bank transfer / receipt ——
    else if (method.isBankTransfer) {
      if (paymentProof == null || paymentProof.isEmpty) {
        final uploaded = await showUploadReceiptSheet(
          context,
          uploadFile: (path) =>
              ref.read(accountRepositoryProvider).uploadMedia(path),
        );
        if (uploaded == null) return;
        paymentProof = uploaded.proofs;
        _paymentReference = uploaded.reference;
        setState(() => _paymentProof = paymentProof);
      }
      paymentResponse = {
        'gateway': gateway,
        'reference': _paymentReference,
        'uploadedAt': DateTime.now().toIso8601String(),
      };
    }
    // —— EasyPaisa OTP ——
    else if (method.isEasyPaisa) {
      final wallet = _walletCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (!RegExp(r'^03[0-9]{9}$').hasMatch(wallet)) {
        showAppToast(context, 'Enter a valid EasyPaisa number (03XXXXXXXXX)');
        return;
      }
      final orderId = 'EP${DateTime.now().millisecondsSinceEpoch}';
      final init = await _api.initiateEasyPaisa(
        orderId: orderId,
        amount: total,
        mobileNumber: wallet,
        customerEmail: email,
        customerName: name,
      );
      if (!init.success || init.transactionId == null) {
        showAppToast(context, init.error ?? 'EasyPaisa initiation failed');
        return;
      }
      if (!mounted) return;
      final txn = await showEasyPaisaOtpDialog(
        context,
        mobile: wallet,
        api: _api,
        transactionId: init.transactionId!,
        orderId: init.orderId ?? orderId,
      );
      if (txn == null) return;
      paymentId = txn;
      paymentResponse = {
        'gateway': 'easypaisa',
        'transactionId': txn,
        'transactionStatus': 'SUCCESS',
        'verifiedAt': DateTime.now().toIso8601String(),
      };
    }
    // —— JazzCash wallet ——
    else if (method.isJazzCash) {
      final wallet = _walletCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      final cnic = _cnicCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (!RegExp(r'^03[0-9]{9}$').hasMatch(wallet)) {
        showAppToast(context, 'Enter a valid JazzCash number (03XXXXXXXXX)');
        return;
      }
      if (cnic.length != 6) {
        showAppToast(context, 'Enter the last 6 digits of your CNIC');
        return;
      }
      final init = await _api.initiateJazzCash(
        orderId: 'JC${DateTime.now().millisecondsSinceEpoch}',
        amount: total,
        mobileNumber: wallet,
        customerEmail: email,
        customerName: name,
        description: 'GherTak order payment',
        cnic: cnic,
      );
      if (!init.success) {
        showAppToast(context, init.error ?? 'JazzCash payment failed');
        return;
      }
      var txnId = init.transactionId ?? init.txnRefNo;
      if (init.pendingApproval && !init.paymentComplete) {
        if (!mounted) return;
        final ok = await showJazzCashPendingDialog(
          context,
          mobile: wallet,
          api: _api,
          transactionId: init.transactionId,
          txnRefNo: init.txnRefNo,
        );
        if (!ok) return;
        final status = await _api.jazzCashStatus(
          transactionId: init.transactionId,
          txnRefNo: init.txnRefNo,
        );
        txnId = status.txnRefNo ?? status.transactionId ?? txnId;
      }
      paymentId = txnId;
      paymentResponse = {
        'gateway': 'jazzcash',
        'transactionId': txnId,
        'txnRefNo': init.txnRefNo ?? txnId,
        'pp_TxnRefNo': init.txnRefNo ?? txnId,
        'transactionStatus': 'SUCCESS',
        'responseCode': init.responseCode ?? '000',
        'verifiedAt': DateTime.now().toIso8601String(),
      };
    }
    // —— JazzCash Card redirect ——
    else if (method.isJazzCashCard) {
      final card = await _api.initiateJazzCashCard(
        amount: total,
        description: 'GherTak order payment',
      );
      if (!card.success) {
        showAppToast(context, card.error ?? 'JazzCash card failed');
        return;
      }
      if (card.mocked && card.paymentComplete) {
        paymentId = card.txnRefNo;
        paymentResponse = {
          'gateway': 'jazzcash_card',
          'method': 'card_page_redirection_v1.1',
          'txnType': 'MPAY',
          'transactionId': card.txnRefNo,
          'txnRefNo': card.txnRefNo,
          'pp_TxnRefNo': card.txnRefNo,
          'transactionStatus': 'SUCCESS',
          'responseCode': '000',
          'mocked': true,
          'verifiedAt': DateTime.now().toIso8601String(),
        };
      } else {
        if (card.postUrl == null || card.formFields == null) {
          showAppToast(context, 'JazzCash card redirect form was not returned');
          return;
        }
        if (!mounted) return;
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              title: 'JazzCash Card',
              postUrl: card.postUrl!,
              formFields: card.formFields!,
            ),
          ),
        );
        if (paid != true) {
          showAppToast(context, 'JazzCash card payment was cancelled');
          return;
        }
        paymentId = card.txnRefNo ?? 'jazzcash_card';
        paymentResponse = {
          'gateway': 'jazzcash_card',
          'method': 'card_page_redirection_v1.1',
          'txnType': 'MPAY',
          'transactionId': paymentId,
          'txnRefNo': paymentId,
          'pp_TxnRefNo': paymentId,
          'transactionStatus': 'SUCCESS',
          'verifiedAt': DateTime.now().toIso8601String(),
        };
      }
    }
    // —— PayFast ——
    else if (method.isPayFast) {
      final pf = await _api.initiatePayFastPk(
        amount: total,
        email: email,
        phone: phone,
      );
      if (!pf.success || pf.postUrl == null || pf.formFields == null) {
        showAppToast(context, pf.error ?? 'PayFast initiation failed');
        return;
      }
      if (!mounted) return;
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            title: 'PayFast',
            postUrl: pf.postUrl!,
            formFields: pf.formFields!,
            successUrlHints: const [
              'payfast-success',
              'order-success',
              'payment-success',
            ],
            failureUrlHints: const [
              'payfast-failed',
              'payment-failed',
              'payment-cancel',
            ],
          ),
        ),
      );
      if (paid != true) {
        showAppToast(context, 'PayFast payment was cancelled');
        return;
      }
      paymentId = pf.basketId;
      paymentResponse = {
        'gateway': 'payfast',
        'basketId': pf.basketId,
        'transactionStatus': 'SUCCESS',
        'verifiedAt': DateTime.now().toIso8601String(),
      };
    } else {
      showAppToast(context, 'Unsupported payment method');
      return;
    }

    setState(() => _placing = true);
    final placedAt = DateTime.now();
    try {
      if (editSession != null) {
        await _updateExistingOrder(editSession, draft);
        return;
      }

      final wallet = ref.read(walletProvider).valueOrNull;
      final shipping = ref.read(shippingClassProvider).valueOrNull;
      final user = ref.read(authStateProvider).valueOrNull;
      final cartItems = ref.read(cartProvider).valueOrNull ?? [];
      if (cartItems.isEmpty) {
        showAppToast(context, 'Your cart is empty');
        return;
      }
      final cartPayload = cartItems
          .map(
            (item) => {
              'id': item.id,
              'quantity': item.quantity,
              'product_id': item.product.id,
              'variation_option_id': item.variationOptionId,
            },
          )
          .toList();
      final allowSub = await getAllowSubstitution();
      final order = await ref.read(orderRepositoryProvider).createFromCart(
            shippingAddress: draft.shippingAddress,
            billingAddress: draft.shippingAddress,
            paymentGateway: gateway,
            deliveryTime: draft.deliveryTime,
            orderNotes: draft.orderNotes,
            useWallet: _useWallet,
            walletAmount: _useWallet ? wallet?.balance : null,
            allowSubstitution: allowSub,
            shippingId: shipping?.id ?? settings?.shippingClassId,
            taxId: settings?.taxClassId,
            couponId: ref.read(appliedCouponProvider)?.id,
            paymentProof: method.isBankTransfer ? paymentProof : null,
            paymentResponse: paymentResponse,
            paymentId: paymentId,
            paymentStatus: paymentId != null ? 'success' : 'cash-on-delivery',
            customerContact: phone,
            cart: cartPayload,
            customerId: user?.id,
          );
      ref.read(appliedCouponProvider.notifier).state = null;
      await _goToOrderSuccess(order);
    } on ApiException catch (e) {
      if (editSession == null && e.isTimeout) {
        final recovered = await _recoverOrderAfterSlowResponse(placedAt);
        if (recovered != null) {
          await _goToOrderSuccess(recovered);
          return;
        }
      }
      if (mounted) showAppToast(context, e.message);
    } catch (e) {
      if (editSession == null) {
        final recovered = await _recoverOrderAfterSlowResponse(placedAt);
        if (recovered != null) {
          await _goToOrderSuccess(recovered);
          return;
        }
      }
      if (mounted) showAppToast(context, e);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _updateExistingOrder(
    EditOrderSession session,
    CheckoutDraft draft,
  ) async {
    final cart = ref.read(cartProvider).valueOrNull ?? [];
    final allowSub = await getAllowSubstitution();
    final List<Map<String, dynamic>> items;
    if (session.detailsOnly) {
      items = session.items
          .map(
            (e) => {
              if (e.orderProductId != null) 'order_product_id': e.orderProductId,
              'product_id': e.productId,
              if (e.variationOptionId != null)
                'variation_option_id': e.variationOptionId,
              'quantity': e.quantity,
            },
          )
          .toList();
    } else {
      items = cart.map((c) {
        final key = itemKey(c.product.id, c.variationOptionId);
        return {
          if (session.orderProductMap[key] != null)
            'order_product_id': session.orderProductMap[key],
          'product_id': c.product.id,
          if (c.variationOptionId != null)
            'variation_option_id': c.variationOptionId,
          'quantity': c.quantity,
        };
      }).toList();
    }

    if (items.isEmpty) {
      throw ApiException('Add at least one product before updating the order.');
    }

    final order = await ref.read(orderRepositoryProvider).customerEdit(
          orderId: '${session.orderId}',
          items: items,
          deliveryTime: draft.deliveryTime ?? session.deliveryTime,
          orderNotes: draft.orderNotes ?? session.orderNotes,
          shippingAddress: draft.shippingAddress,
          allowSubstitution: allowSub,
        );

    await ref.read(editOrderSessionProvider.notifier).clear();
    ref.read(appliedCouponProvider.notifier).state = null;
    await ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    showAppToast(
      context,
      session.detailsOnly
          ? 'Address and schedule details updated'
          : 'Order updated successfully',
      isError: false,
    );
    await _goToOrderSuccess(order);
  }

  Future<void> _goToOrderSuccess(OrderModel order) async {
    ref.read(checkoutDraftProvider.notifier).state = null;
    ref.read(selectedCheckoutAddressIdProvider.notifier).state = null;
    // Persist clear for guests (SharedPreferences) and logged-in users.
    await ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    context.go(
      AppRoutes.orderSuccessWith(
        orderId: order.id,
        trackingId: order.trackingNumber,
      ),
    );
    ref.invalidate(ordersProvider);
    ref.invalidate(walletProvider);
  }

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
    final settingsAsync = ref.watch(settingsProvider);
    final loggedIn = ref.watch(authStateProvider).valueOrNull != null;
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
            child: settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(friendlyUserMessage(e))),
              data: (settings) {
                final methods = _methods(settings);
                final selected = _selected(methods);
                if (_selectedId == null && selected != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedId = selected.id);
                  });
                }

                return ListView(
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
                              style: AppFonts.style(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Divider(height: 1, color: AppColors.borderLight),
                          for (var i = 0; i < methods.length; i++) ...[
                            _methodTile(methods[i], selected?.id),
                            if (i < methods.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: AppColors.borderLight,
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (selected != null &&
                        selected.requiresWalletNumber) ...[
                      const SizedBox(height: 12),
                      _walletFields(selected),
                    ],
                    if (selected != null && selected.isBankTransfer) ...[
                      const SizedBox(height: 12),
                      _proofCard(),
                    ],
                    if (loggedIn) ...[
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
                            style: AppFonts.style(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            walletLabel,
                            style: AppFonts.style(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          value: _useWallet,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => setState(() => _useWallet = v),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    BrandGradientButton(
                      label: _placing
                          ? (ref.watch(editOrderSessionProvider) != null
                              ? 'Updating order…'
                              : 'Placing order…')
                          : (ref.watch(editOrderSessionProvider) != null
                              ? 'Update order'
                              : 'Place Order'),
                      onPressed: _placing ? null : _placeOrder,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(PaymentMethodConfig method, String? selectedId) {
    final selected = method.id == selectedId;
    final enabled = method.enabled;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: !enabled
            ? null
            : () async {
                setState(() => _selectedId = method.id);
                if (method.isBankTransfer &&
                    (_paymentProof == null || _paymentProof!.isEmpty)) {
                  final uploaded = await showUploadReceiptSheet(
                    context,
                    uploadFile: (path) =>
                        ref.read(accountRepositoryProvider).uploadMedia(path),
                  );
                  if (uploaded != null && mounted) {
                    setState(() {
                      _paymentProof = uploaded.proofs;
                      _paymentReference = uploaded.reference;
                    });
                  }
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primarySoft
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconFor(method),
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
                            method.name,
                            style: AppFonts.style(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (method.isCashOnDelivery) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Most popular',
                              style: AppFonts.style(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((method.description ?? '').isNotEmpty)
                      Text(
                        method.description!,
                        style: AppFonts.style(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletFields(PaymentMethodConfig method) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _walletCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: method.walletNumberLabel ?? 'Mobile wallet number',
              hintText: '03XXXXXXXXX',
              counterText: '',
            ),
          ),
          if (method.isJazzCash) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _cnicCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'CNIC (last six digits)',
                hintText: '345671',
                counterText: '',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _proofCard() {
    final count = _paymentProof?.length ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Transfer payment, then upload screenshot',
            style: AppFonts.style(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            count > 0
                ? '$count screenshot(s) attached'
                    '${(_paymentReference ?? '').isNotEmpty ? ' · Ref: $_paymentReference' : ''}'
                : 'Upload a clear payment receipt before placing the order.',
            style: AppFonts.style(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final uploaded = await showUploadReceiptSheet(
                context,
                uploadFile: (path) =>
                    ref.read(accountRepositoryProvider).uploadMedia(path),
              );
              if (uploaded != null && mounted) {
                setState(() {
                  _paymentProof = uploaded.proofs;
                  _paymentReference = uploaded.reference;
                });
              }
            },
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(count > 0 ? 'Change screenshots' : 'Upload screenshots'),
          ),
        ],
      ),
    );
  }
}
