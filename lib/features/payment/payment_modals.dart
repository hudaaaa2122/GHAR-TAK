import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../shared/widgets.dart';
import 'payment_gateway_api.dart';

Future<bool> showJazzCashPendingDialog(
  BuildContext context, {
  required String mobile,
  required PaymentGatewayApi api,
  required String? transactionId,
  required String? txnRefNo,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _JazzCashPendingDialog(
          mobile: mobile,
          api: api,
          transactionId: transactionId,
          txnRefNo: txnRefNo,
        ),
      ) ??
      false;
}

class _JazzCashPendingDialog extends StatefulWidget {
  const _JazzCashPendingDialog({
    required this.mobile,
    required this.api,
    required this.transactionId,
    required this.txnRefNo,
  });

  final String mobile;
  final PaymentGatewayApi api;
  final String? transactionId;
  final String? txnRefNo;

  @override
  State<_JazzCashPendingDialog> createState() => _JazzCashPendingDialogState();
}

class _JazzCashPendingDialogState extends State<_JazzCashPendingDialog> {
  bool _checking = false;
  bool _timedOut = false;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _poll();
    Future<void>.delayed(const Duration(seconds: 180), () {
      if (mounted && !_done) setState(() => _timedOut = true);
    });
  }

  Future<void> _poll() async {
    if (!mounted || _done) return;
    setState(() => _checking = true);
    try {
      final result = await widget.api.jazzCashStatus(
        transactionId: widget.transactionId,
        txnRefNo: widget.txnRefNo,
      );
      if (!mounted) return;
      if (result.success && result.paymentComplete) {
        _done = true;
        Navigator.pop(context, true);
        return;
      }
      if (result.error != null && !result.pendingApproval) {
        setState(() => _error = result.error);
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyUserMessage(e));
    } finally {
      if (mounted && !_done) setState(() => _checking = false);
    }
    if (!_done && mounted) {
      await Future<void>.delayed(const Duration(seconds: 4));
      if (mounted && !_done) _poll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = widget.mobile.length >= 7
        ? '${widget.mobile.substring(0, 4)}****${widget.mobile.substring(widget.mobile.length - 3)}'
        : widget.mobile;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: Color(0xFFC41E3A)),
          const SizedBox(width: 8),
          Text(
            'JazzCash Approval',
            style: AppFonts.style(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Approve this payment in your JazzCash app ($masked). Do not close this window.',
            style: AppFonts.style(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'JazzCash will debit your wallet after you confirm on your phone. We place the order once payment is approved.',
              style: AppFonts.style(fontSize: 12.5, height: 1.4),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: AppFonts.style(color: AppColors.error, fontSize: 12)),
          ],
          if (_timedOut) ...[
            const SizedBox(height: 10),
            Text(
              'Still waiting for JazzCash approval. Open the JazzCash app and try again, or cancel and retry.',
              style: AppFonts.style(color: AppColors.warning, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (_checking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (_checking) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _checking
                      ? 'Checking payment status…'
                      : 'Waiting for JazzCash app approval…',
                  style: AppFonts.style(
                      fontSize: 12.5, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

Future<String?> showEasyPaisaOtpDialog(
  BuildContext context, {
  required String mobile,
  required PaymentGatewayApi api,
  required String transactionId,
  required String orderId,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _EasyPaisaOtpDialog(
      mobile: mobile,
      api: api,
      transactionId: transactionId,
      orderId: orderId,
    ),
  );
}

class _EasyPaisaOtpDialog extends StatefulWidget {
  const _EasyPaisaOtpDialog({
    required this.mobile,
    required this.api,
    required this.transactionId,
    required this.orderId,
  });

  final String mobile;
  final PaymentGatewayApi api;
  final String transactionId;
  final String orderId;

  @override
  State<_EasyPaisaOtpDialog> createState() => _EasyPaisaOtpDialogState();
}

class _EasyPaisaOtpDialogState extends State<_EasyPaisaOtpDialog> {
  final _otp = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otp.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the OTP sent to your EasyPaisa number');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.api.verifyEasyPaisaOtp(
      transactionId: widget.transactionId,
      orderId: widget.orderId,
      otp: code,
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, widget.transactionId);
      return;
    }
    setState(() {
      _busy = false;
      _error = result.error ?? 'OTP verification failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final masked = widget.mobile.length >= 7
        ? '${widget.mobile.substring(0, 4)}****${widget.mobile.substring(widget.mobile.length - 3)}'
        : widget.mobile;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'EasyPaisa OTP',
        style: AppFonts.style(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the OTP sent to $masked to confirm your EasyPaisa payment.',
            style: AppFonts.style(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'OTP',
              hintText: 'Enter OTP',
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: AppFonts.style(color: AppColors.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _verify,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}

Future<
    ({
      List<Map<String, dynamic>> proofs,
      String reference,
    })?> showUploadReceiptSheet(
  BuildContext context, {
  required Future<Map<String, dynamic>> Function(String path) uploadFile,
}) async {
  final reference = TextEditingController();
  final proofs = <Map<String, dynamic>>[];
  final result = await showModalBottomSheet<
      ({
        List<Map<String, dynamic>> proofs,
        String reference,
      })>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      var uploading = false;
      return StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pay & Upload Receipt',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transfer the order amount to our bank / JazzCash / EasyPaisa account, then upload a clear screenshot of your payment receipt (max 3).',
                    style: AppFonts.style(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reference,
                    maxLength: 64,
                    decoration: const InputDecoration(
                      labelText: 'Transaction / reference ID (optional)',
                      hintText: 'e.g. TXN123456',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Payment screenshot *',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < proofs.length; i++)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                (proofs[i]['thumbnail'] ??
                                        proofs[i]['original'] ??
                                        '')
                                    .toString(),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 84,
                                  height: 84,
                                  color: AppColors.chipBg,
                                  child: const Icon(Icons.image),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: InkWell(
                                onTap: () => setModal(() => proofs.removeAt(i)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (proofs.length < 3)
                        InkWell(
                          onTap: uploading
                              ? null
                              : () async {
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (file == null) return;
                                  setModal(() => uploading = true);
                                  try {
                                    final media = await uploadFile(file.path);
                                    setModal(() {
                                      proofs.add(media);
                                      uploading = false;
                                    });
                                  } catch (e) {
                                    setModal(() => uploading = false);
                                    if (ctx.mounted) showAppToast(ctx, e);
                                  }
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary),
                              color: Colors.white,
                            ),
                            child: uploading
                                ? const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.upload_file_outlined,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Upload',
                                        style: AppFonts.style(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  BrandGradientButton(
                    label: 'Save screenshots',
                    onPressed: () {
                      if (proofs.isEmpty) {
                        showAppToast(
                          ctx,
                          'Please upload your payment screenshot.',
                        );
                        return;
                      }
                      Navigator.pop(
                        ctx,
                        (
                          proofs: List<Map<String, dynamic>>.from(proofs),
                          reference: reference.text.trim(),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  reference.dispose();
  return result;
}
