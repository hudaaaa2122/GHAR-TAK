import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../shared/figma_chrome.dart';

/// Auto-submits an HTML POST form (JazzCash card / PayFast) inside a WebView.
/// Pops with `true` when a success URL is hit, `false` on failure/cancel.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.title,
    required this.postUrl,
    required this.formFields,
    this.successUrlHints = const [
      'payfast-success',
      'jazzcash-card-return',
      'order-success',
      'payment-success',
      'pp_ResponseCode=000',
    ],
    this.failureUrlHints = const [
      'payfast-failed',
      'payment-failed',
      'payment-cancel',
      'pp_ResponseCode=',
    ],
  });

  final String title;
  final String postUrl;
  final Map<String, String> formFields;
  final List<String> successUrlHints;
  final List<String> failureUrlHints;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  var _loading = true;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (req) {
            _handleUrl(req.url);
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) _handleUrl(url);
          },
        ),
      )
      ..loadHtmlString(_buildHtml(), baseUrl: widget.postUrl);
  }

  String _buildHtml() {
    final inputs = widget.formFields.entries.map((e) {
      final name = const HtmlEscape().convert(e.key);
      final value = const HtmlEscape().convert(e.value);
      return '<input type="hidden" name="$name" value="$value" />';
    }).join('\n');
    final action = const HtmlEscape().convert(widget.postUrl);
    return '''
<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Redirecting…</title></head>
<body style="font-family:sans-serif;padding:24px;text-align:center;color:#334">
<p>Redirecting to secure payment…</p>
<form id="pay" method="POST" action="$action">
$inputs
</form>
<script>document.getElementById('pay').submit();</script>
</body></html>
''';
  }

  void _handleUrl(String url) {
    if (_finished) return;
    final lower = url.toLowerCase();
    for (final hint in widget.successUrlHints) {
      if (lower.contains(hint.toLowerCase())) {
        // JazzCash may include response code in query — only treat 000 as success
        // when hint is response code style.
        if (hint.startsWith('pp_ResponseCode=') &&
            !lower.contains('pp_responsecode=000')) {
          continue;
        }
        _finish(true);
        return;
      }
    }
    for (final hint in widget.failureUrlHints) {
      if (hint.startsWith('pp_ResponseCode=')) {
        if (lower.contains('pp_responsecode=') &&
            !lower.contains('pp_responsecode=000') &&
            !lower.contains('pp_responsecode=157') &&
            !lower.contains('pp_responsecode=210')) {
          _finish(false);
          return;
        }
        continue;
      }
      if (lower.contains(hint.toLowerCase())) {
        _finish(false);
        return;
      }
    }
  }

  void _finish(bool success) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: widget.title,
            onBack: () => Navigator.of(context).pop(false),
          ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
          Expanded(child: WebViewWidget(controller: _controller)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Complete payment in this window. Do not close until you see a confirmation.',
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
