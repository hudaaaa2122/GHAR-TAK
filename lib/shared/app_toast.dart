import 'package:flutter/material.dart';

import '../core/theme/app_fonts.dart';

enum AppToastKind { error, success, info }

/// Strip technical/API noise into a short message customers can understand.
String friendlyUserMessage(Object? raw, {String fallback = 'Something went wrong. Please try again.'}) {
  if (raw == null) return fallback;
  var text = raw.toString().trim();
  if (text.isEmpty) return fallback;

  text = text
      .replaceFirst(RegExp(r'^ApiException:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^DioException\[[^\]]*\]:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^Error:\s*', caseSensitive: false), '')
      .trim();

  final lower = text.toLowerCase();
  if (lower.contains('not authenticated') ||
      lower.contains('not authenticated') ||
      lower.contains('unauthorized') ||
      lower.contains('401') ||
      lower == 'null') {
    return 'Please login first if you want to continue.';
  }
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection timed out') ||
      lower.contains('timeout')) {
    return 'Unable to connect. Check your internet and try again.';
  }
  if (lower.contains('invalid') ||
      lower.contains('incorrect') ||
      lower.contains('wrong password') ||
      lower.contains('credentials')) {
    return 'Invalid email or password';
  }
  if (lower.contains('email') && lower.contains('required')) {
    return 'Please enter your email';
  }
  if (lower.contains('password') && lower.contains('required')) {
    return 'Please enter your password';
  }
  if (lower.contains('already') && lower.contains('exist')) {
    return 'An account with this email already exists';
  }
  if (lower.contains('verification') || lower.contains('invalid code')) {
    return 'Invalid verification code. Please try again.';
  }
  if (lower.contains('formatException') ||
      lower.contains('type \'') ||
      lower.contains('null check operator') ||
      lower.contains('nosuchmethod') ||
      lower.contains('stack trace') ||
      lower.contains('validation error') ||
      lower.startsWith('{') ||
      lower.startsWith('[')) {
    return fallback;
  }

  // Truncate very long backend dumps.
  if (text.length > 160) {
    text = '${text.substring(0, 157)}…';
  }
  return text;
}

Color _toastColor(AppToastKind kind) {
  switch (kind) {
    case AppToastKind.success:
      return const Color(0xFF15824B);
    case AppToastKind.info:
      return const Color(0xFF2A6FDB);
    case AppToastKind.error:
      return const Color(0xFFC0341F);
  }
}

IconData _toastIcon(AppToastKind kind) {
  switch (kind) {
    case AppToastKind.success:
      return Icons.check_circle_outline;
    case AppToastKind.info:
      return Icons.info_outline;
    case AppToastKind.error:
      return Icons.error_outline;
  }
}

/// Top-right toast — red error / green success / blue info.
void showAppToast(
  BuildContext context,
  Object? message, {
  Duration duration = const Duration(seconds: 3),
  bool isError = true,
  AppToastKind? kind,
}) {
  final resolved = kind ?? (isError ? AppToastKind.error : AppToastKind.success);
  final text = friendlyUserMessage(
    message,
    fallback: resolved == AppToastKind.success
        ? 'Done'
        : resolved == AppToastKind.info
            ? 'Heads up'
            : 'Something went wrong. Please try again.',
  );
  if (text.isEmpty) return;

  final overlay = Overlay.maybeOf(context);
  if (overlay == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: _toastColor(resolved),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      final top = MediaQuery.paddingOf(ctx).top + 12;
      return Positioned(
        top: top,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(16 * (1 - v), 0),
                child: child,
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(ctx).width * 0.82,
                minWidth: 180,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                decoration: BoxDecoration(
                  color: _toastColor(resolved),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_toastIcon(resolved), color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        text,
                        style: AppFonts.style(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Future<void>.delayed(duration, () {
    try {
      entry.remove();
    } catch (_) {}
  });
}
