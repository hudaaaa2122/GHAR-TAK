import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/figma_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';

enum GherTakLogoVariant {
  /// Full color logo.
  color,

  /// White mark + wordmark for teal/dark headers (Figma Intro/Login/Register).
  onDark,
}

TextStyle _manrope({
  required FontWeight fontWeight,
  required double fontSize,
  Color? color,
  double height = 1.0,
  double letterSpacing = 0,
}) {
  return AppFonts.style(
    fontWeight: fontWeight,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Brand lockup — website MainLogo by default (roof + "Gher Tak" + tagline).
class GherTakLogo extends StatelessWidget {
  const GherTakLogo({
    super.key,
    this.compact = false,
    this.showTagline = true,
    this.variant = GherTakLogoVariant.color,
    this.markHeight,
    this.height,
    this.stacked = true,
  });

  final bool compact;
  final bool showTagline;
  final GherTakLogoVariant variant;
  final double? markHeight;
  final double? height;

  /// Unused visually (lockup is always splash-style); kept for call sites.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final onDark = variant == GherTakLogoVariant.onDark;
    // Auth headers use ~52; home compact strip stays smaller via height:.
    final logoH = height ?? markHeight ?? (compact ? 40.0 : 56.0);
    // Prefer dedicated white asset; ColorFilter guarantees pure white on teal headers
    // (website white PNG still has teal in the house mark).
    final asset =
        onDark ? FigmaAssets.websiteLogoWhite : FigmaAssets.websiteLogo;

    Widget logo = Image.asset(
      asset,
      height: logoH,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        if (!onDark) {
          return SvgPicture.asset(
            FigmaAssets.websiteLogoSvg,
            height: logoH,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            placeholderBuilder: (_) => _LockupSvgFallback(
              onDark: false,
              height: logoH,
            ),
          );
        }
        return _LockupSvgFallback(onDark: true, height: logoH);
      },
    );

    if (onDark) {
      logo = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: logo,
      );
    }

    return logo;
  }
}

class _LockupSvgFallback extends StatelessWidget {
  const _LockupSvgFallback({required this.onDark, required this.height});

  final bool onDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : const Color(0xFF328FB8);
    final textColor = onDark ? Colors.white : Colors.black;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          FigmaAssets.logoMark,
          height: height,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        SizedBox(width: height * 0.1),
        Text(
          'Gher Tak',
          style: _manrope(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: height * 0.58,
            height: 1.0,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

/// Splash: corner blobs (Figma) + current website MainLogo centered.
class SplashBrandCanvas extends StatelessWidget {
  const SplashBrandCanvas({super.key});

  static const _designW = 440.0;
  static const _designH = 956.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sx = constraints.maxWidth / _designW;
        final sy = constraints.maxHeight / _designH;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [Color(0xFFFFFFFF), Color(0xFFDEDEDE)],
                  stops: [0.2788, 1.0],
                ),
              ),
            ),
            // Top-left blob (overflows off-screen like Figma)
            Positioned(
              left: -311 * sx,
              top: -433 * sy,
              width: 667.514 * sx,
              height: 686.15 * sy,
              child: SvgPicture.asset(
                FigmaAssets.blobTopLeft,
                fit: BoxFit.fill,
                allowDrawingOutsideViewBox: true,
              ),
            ),
            // Bottom-right blob
            Positioned(
              left: -39.32 * sx,
              top: 602.53 * sy,
              width: 904.738 * sx,
              height: 912.115 * sy,
              child: SvgPicture.asset(
                FigmaAssets.blobBottomRight,
                fit: BoxFit.fill,
                allowDrawingOutsideViewBox: true,
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40 * sx),
                child: GherTakLogo(
                  height: (52 * sx).clamp(44.0, 64.0),
                  compact: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Teal gradient header with Figma-style soft bottom blob (Intro / Login / Register / Home).
///
/// Same silhouette as Profile: large equal radii on **both** bottom corners.
/// Height and curve radius scale with screen width.
class BrandCurveHeader extends StatelessWidget {
  const BrandCurveHeader({
    super.key,
    required this.child,
    this.height,
    /// Bottom corner radius (null = responsive from width).
    this.curveDepth,
    this.gradient = AppColors.brandGradient,
    /// Shorter header for Intro (logo + skip only).
    this.compact = false,
  });

  final Widget child;
  final double? height;
  final double? curveDepth;
  final Gradient gradient;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;
    final ratio = compact ? 0.36 : 0.46;
    final resolvedHeight = height ??
        ((w * ratio).clamp(compact ? 148.0 : 168.0, compact ? 196.0 : 220.0) +
            topInset * 0.35);
    final radius = curveDepth ?? BrandHeaderShapeClipper.radiusForWidth(w);

    return SizedBox(
      height: resolvedHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 16, radius * 0.35),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Shared bottom-corner radius used by [BrandCurveHeader] and the home header.
/// Matches Profile (`BorderRadius.vertical(bottom: Radius.circular(40))`) but scales.
class BrandHeaderShapeClipper {
  BrandHeaderShapeClipper._();

  static double radiusForWidth(double width) =>
      (width * 0.105).clamp(32.0, 48.0);
}

/// Figma Login “Google” outlined button (official multicolor G + label).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1F1F1F),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF747775)),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/google_g.svg',
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Google',
                  style: _manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Primary CTA with brand gradient (intro Next / login Sign In).
class BrandGradientButton extends StatelessWidget {
  const BrandGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.buttonGradient,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14677D).withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: _manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
