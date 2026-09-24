import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/app_palette.dart';

/// Circular back button matching Figma checkout/cart headers.
class FigmaBackButton extends StatelessWidget {
  const FigmaBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: p.surface,
      shape: CircleBorder(
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed ?? () => Navigator.maybePop(context),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left, size: 24, color: p.textPrimary),
        ),
      ),
    );
  }
}

/// Sticky header used across cart / checkout / orders screens.
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
    final p = AppPalette.of(context);
    return Material(
      color: p.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              FigmaBackButton(onPressed: onBack),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: p.textPrimary,
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

/// Icon + label tile used in Figma account / menu grids.
class FigmaMenuTile extends StatelessWidget {
  const FigmaMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final c = color ?? AppColors.primary;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: c, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: p.textPrimary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FigmaListRow extends StatelessWidget {
  const FigmaListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      children: [
        Material(
          color: p.surface,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFonts.style(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: p.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppFonts.style(
                              fontSize: 12,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: p.textMuted,
                      ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: p.border,
            indent: 16,
            endIndent: 16,
          ),
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
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: p.surface,
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
              style: AppFonts.style(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.8,
                color: p.textMuted,
              ),
            ),
          ),
          Divider(height: 1, color: p.border),
          ...children,
        ],
      ),
    );
  }
}

class CheckoutStepper extends StatelessWidget {
  const CheckoutStepper({super.key, required this.activeStep});

  /// 1-based index: 1=Cart, 2=Checkout, 3=Payment, 4=Confirm.
  final int activeStep;

  static const _labels = ['Cart', 'Checkout', 'Payment', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      color: p.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i < activeStep ? AppColors.success : p.border,
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
    final p = AppPalette.of(context);
    final highlight = done || active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight ? AppColors.success : p.inputFill,
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text(
                  '$index',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: highlight ? Colors.white : p.textMuted,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppFonts.style(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: highlight ? AppColors.success : p.textMuted,
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
    final p = AppPalette.of(context);
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
                    style: AppFonts.style(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                trailing ??
                    Icon(Icons.chevron_right, size: 18, color: p.textMuted),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: p.border, indent: 16, endIndent: 16),
      ],
    );
  }
}
