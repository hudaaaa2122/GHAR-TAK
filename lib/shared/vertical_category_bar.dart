import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_fonts.dart';
import '../core/theme/vertical_theme.dart';

/// Frosted category strip with looping Wired-style icon motions
/// and a liquid-glass track that tints to the active vertical color.
class VerticalCategoryBar extends StatefulWidget {
  const VerticalCategoryBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const items = [
    _VertItem(
      slug: 'grocery',
      label: 'Grocery',
      asset: 'assets/icons/vertical_grocery.svg',
    ),
    _VertItem(
      slug: 'pharmacy',
      label: 'Pharmacy',
      asset: 'assets/icons/wired-outline-428-syringe-hover-pinch.png',
    ),
    _VertItem(
      slug: 'bakery',
      label: 'Bakery',
      asset: 'assets/icons/wired-outline-1360-grocery-shelf-hover-pinch.png',
    ),
    _VertItem(
      slug: 'business',
      label: 'Business',
      asset: 'assets/icons/wired-outline-business-briefcase.png',
    ),
  ];

  @override
  State<VerticalCategoryBar> createState() => _VerticalCategoryBarState();
}

class _VerticalCategoryBarState extends State<VerticalCategoryBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;
  late final CurvedAnimation _slideCurve;

  int _fromIndex = 0;
  int _toIndex = 0;

  static const _hPad = 10.0;
  static const _gap = 6.0;
  static const _pillH = 64.0;
  static const _trackPadV = 8.0;
  static const _caretH = 10.0;
  static const _caretW = 16.0;
  static const _circle = 42.0;

  @override
  void initState() {
    super.initState();
    _toIndex = _indexOf(widget.selected);
    _fromIndex = _toIndex;
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    );
    _slideCurve = CurvedAnimation(
      parent: _slide,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant VerticalCategoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final next = _indexOf(widget.selected);
      if (next != _toIndex) {
        _animateTo(next, notify: false);
      }
    }
  }

  @override
  void dispose() {
    _slideCurve.dispose();
    _slide.dispose();
    super.dispose();
  }

  int _indexOf(String slug) {
    final i = VerticalCategoryBar.items.indexWhere((e) => e.slug == slug);
    return i < 0 ? 0 : i;
  }

  void _animateTo(int nextIndex, {required bool notify}) {
    final item = VerticalCategoryBar.items[nextIndex];
    setState(() {
      _fromIndex = _toIndex;
      _toIndex = nextIndex;
    });
    _slide
      ..reset()
      ..forward();
    if (notify && item.slug != widget.selected) {
      widget.onChanged(item.slug);
    }
  }

  void _onTap(_VertItem item) {
    final next = _indexOf(item.slug);
    if (next == _toIndex) return;
    _animateTo(next, notify: true);
  }

  Color _glassTint(double t) {
    Color tintFor(String slug) {
      final theme = VerticalTheme.of(slug);
      // Mix soft + primary so grocery (teal) vs business (navy) read clearly.
      return Color.lerp(theme.primarySoft, theme.primary, 0.42) ??
          theme.primarySoft;
    }

    final from = tintFor(VerticalCategoryBar.items[_fromIndex].slug);
    final to = tintFor(VerticalCategoryBar.items[_toIndex].slug);
    return Color.lerp(from, to, t) ?? to;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = VerticalCategoryBar.items.length;
        final trackH = _pillH + _trackPadV * 2;
        final innerW = constraints.maxWidth - _hPad * 2;
        final slotW = (innerW - _gap * (count - 1)) / count;

        return AnimatedBuilder(
          animation: _slideCurve,
          builder: (context, _) {
            final t = _slideCurve.value;
            final caretIndex = _fromIndex + (_toIndex - _fromIndex) * t;
            final slotLeft = _hPad + caretIndex * (slotW + _gap);
            final caretCenter = slotLeft + slotW / 2;
            final highlightLeft = slotLeft + (slotW - _circle - 10) / 2;
            final tint = _glassTint(t);
            final activeTheme = VerticalTheme.of(
              VerticalCategoryBar.items[_toIndex].slug,
            );

            return SizedBox(
              height: trackH + _caretH + 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: trackH,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(trackH / 2),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(trackH / 2),
                            color: tint.withValues(alpha: 0.72),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activeTheme.primary.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: highlightLeft,
                    top: _trackPadV + (_pillH - _circle) / 2 - 5,
                    width: _circle + 10,
                    height: _circle + 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.55),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: caretCenter - _caretW / 2,
                    top: trackH - 1,
                    width: _caretW,
                    height: _caretH,
                    child: const CustomPaint(
                      painter: _CaretPainter(color: Colors.white),
                    ),
                  ),
                  Positioned(
                    left: _hPad,
                    right: _hPad,
                    top: _trackPadV,
                    height: _pillH,
                    child: Row(
                      children: [
                        for (var i = 0;
                            i < VerticalCategoryBar.items.length;
                            i++) ...[
                          if (i > 0) const SizedBox(width: _gap),
                          Expanded(
                            child: _CategorySlot(
                              item: VerticalCategoryBar.items[i],
                              selected: i == _toIndex,
                              height: _pillH,
                              circleSize: _circle,
                              onTap: () =>
                                  _onTap(VerticalCategoryBar.items[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _VertItem {
  const _VertItem({
    required this.slug,
    required this.label,
    required this.asset,
  });

  final String slug;
  final String label;
  final String asset;

  bool get isPng => asset.toLowerCase().endsWith('.png');
}

class _CategorySlot extends StatelessWidget {
  const _CategorySlot({
    required this.item,
    required this.selected,
    required this.height,
    required this.circleSize,
    required this.onTap,
  });

  final _VertItem item;
  final bool selected;
  final double height;
  final double circleSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VerticalTheme.of(item.slug);

    final iconChild = item.isPng
        ? Image.asset(
            item.asset,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            isAntiAlias: true,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 16,
            ),
          )
        : SvgPicture.asset(
            item.asset,
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: circleSize,
                height: circleSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: selected ? 0.95 : 0.22,
                    ),
                    width: selected ? 2.2 : 1,
                  ),
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: _WiredIconMotion(
                      slug: item.slug,
                      child: iconChild,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  color: selected
                      ? theme.primaryDark
                      : const Color(0xFF3A4250),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 11,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Continuous per-vertical Wired-style motion (always looping).
class _WiredIconMotion extends StatefulWidget {
  const _WiredIconMotion({required this.slug, required this.child});

  final String slug;
  final Widget child;

  @override
  State<_WiredIconMotion> createState() => _WiredIconMotionState();
}

class _WiredIconMotionState extends State<_WiredIconMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _durationFor(widget.slug))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _WiredIconMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _ctrl
        ..duration = _durationFor(widget.slug)
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Duration _durationFor(String slug) {
    switch (slug) {
      case 'grocery':
        return const Duration(milliseconds: 900);
      case 'pharmacy':
        return const Duration(milliseconds: 1100);
      case 'bakery':
        return const Duration(milliseconds: 1400);
      case 'business':
        return const Duration(milliseconds: 1200);
      default:
        return const Duration(milliseconds: 1000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        switch (widget.slug) {
          case 'grocery':
            final bounce = Curves.easeOutBack.transform(_ctrl.value);
            return Transform.translate(
              offset: Offset(3.5 * (1 - bounce), 5.5 * (1 - bounce)),
              child: Transform.rotate(
                angle: -0.12 * (1 - bounce),
                child: child,
              ),
            );
          case 'pharmacy':
            final angle = (t * 2 - 1) * 0.28;
            return Transform.rotate(angle: angle, child: child);
          case 'bakery':
            final dx = (t * 2 - 1) * 5.5;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          case 'business':
            final tip = (t * 2 - 1) * 0.18;
            final lift = math.sin(t * math.pi) * -2.2;
            return Transform.translate(
              offset: Offset(0, lift),
              child: Transform.rotate(angle: tip, child: child),
            );
          default:
            return child!;
        }
      },
      child: widget.child,
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CaretPainter oldDelegate) =>
      oldDelegate.color != color;
}
