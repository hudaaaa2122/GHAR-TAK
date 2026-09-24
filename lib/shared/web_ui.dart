import 'package:flutter/material.dart';
import '../core/theme/app_fonts.dart';

import '../core/theme/app_colors.dart';

/// Soft white card matching website product/profile cards.
class WebCard extends StatelessWidget {
  const WebCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = AppColors.radiusXl,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: box,
      ),
    );
  }
}

/// Primary CTA — website commerce button (teal fill, 12px radius).
class WebPrimaryButton extends StatelessWidget {
  const WebPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );
    final btn = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        minimumSize: Size(expand ? double.infinity : 64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
        ),
        textStyle: AppFonts.style(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Outline / secondary CTA matching website `#11788c` on `#eef7f8`.
class WebSecondaryButton extends StatelessWidget {
  const WebSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.tealMid,
        backgroundColor: AppColors.primarySoftAlt,
        side: const BorderSide(color: AppColors.tealMid),
        minimumSize: Size(expand ? double.infinity : 64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
        ),
        textStyle: AppFonts.style(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      child: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Gradient CTA used on profile / checkout (website profileUi).
class WebGradientButton extends StatelessWidget {
  const WebGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.buttonGradient : null,
            color: enabled ? null : AppColors.gray200,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF14677D).withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppFonts.style(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WebStatusPill extends StatelessWidget {
  const WebStatusPill({
    super.key,
    required this.label,
    this.foreground = AppColors.primary,
    this.background = AppColors.primarySoft,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.style(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: foreground,
        ),
      ),
    );
  }
}

class WebSectionTitle extends StatelessWidget {
  const WebSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppFonts.style(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
