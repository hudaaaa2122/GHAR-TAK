import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

/// Circular back button matching Figma checkout/cart headers.
class FigmaBackButton extends StatelessWidget {
  const FigmaBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed ?? () => Navigator.maybePop(context),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left, size: 24, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Sticky white header used across cart / checkout / orders screens.
class FigmaScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const FigmaScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              FigmaBackButton(onPressed: onBack),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Cart → Checkout → Payment → Confirm stepper from Figma.
class CheckoutStepper extends StatelessWidget {
  const CheckoutStepper({super.key, required this.activeStep});

  /// 1-based index: 1=Cart, 2=Checkout, 3=Payment, 4=Confirm.
  final int activeStep;

  static const _labels = ['Cart', 'Checkout', 'Payment', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i < activeStep ? AppColors.success : AppColors.border,
                ),
              ),
            _StepChip(
              index: i + 1,
              label: _labels[i],
              done: i + 1 < activeStep,
              active: i + 1 == activeStep,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
  });

  final int index;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final highlight = done || active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight ? AppColors.success : const Color(0xFFEEF1F4),
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text(
                  '$index',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: highlight ? Colors.white : const Color(0xFF8A93A3),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: highlight ? AppColors.success : const Color(0xFF8A93A3),
          ),
        ),
      ],
    );
  }
}

/// Profile / settings row matching Figma list tiles.
class FigmaSettingsTile extends StatelessWidget {
  const FigmaSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.borderLight, indent: 16, endIndent: 16),
      ],
    );
  }
}

class FigmaSectionCard extends StatelessWidget {
  const FigmaSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          ...children,
        ],
      ),
    );
  }
}
