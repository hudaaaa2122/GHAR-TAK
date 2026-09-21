import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/vertical_theme.dart';

/// Category strip from screen recording:
/// frosted track · vertical ovals · caret slides + bounces · icon pinch.
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
    with TickerProviderStateMixin {
  late final AnimationController _slide;
  late final AnimationController _pinch;
  late final AnimationController _bounce;
  late final CurvedAnimation _slideCurve;

  String? _pinchSlug;
  int _fromIndex = 0;
  int _toIndex = 0;

  static const _hPad = 8.0;
  static const _gap = 8.0;
  static const _pillH = 82.0;
  static const _trackPadV = 6.0;
  static const _caretH = 10.0;
  static const _caretW = 18.0;

  @override
  void initState() {
    super.initState();
    _toIndex = _indexOf(widget.selected);
    _fromIndex = _toIndex;
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      value: 1,
    );
    _slideCurve = CurvedAnimation(
      parent: _slide,
      // Overshoot bounce like the screen recording.
      curve: Curves.elasticOut,
    );
    _pinch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant VerticalCategoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if parent changed selection without our tap (e.g. deep link).
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
    _pinch.dispose();
    _bounce.dispose();
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
      _pinchSlug = item.slug;
    });
    _slide
      ..reset()
      ..forward();
    _pinch
      ..reset()
      ..forward();
    _bounce
      ..reset()
      ..forward();
    if (notify && item.slug != widget.selected) {
      widget.onChanged(item.slug);
    }
  }

  void _onTap(_VertItem item) {
    final next = _indexOf(item.slug);
    // Re-tap active → replay pinch/bounce only.
    if (next == _toIndex) {
      setState(() => _pinchSlug = item.slug);
      _pinch
        ..reset()
        ..forward();
      _bounce
        ..reset()
        ..forward();
      return;
    }
    // Start animation immediately on tap (don't wait for parent rebuild).
    _animateTo(next, notify: true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = VerticalCategoryBar.items.length;
        final trackH = _pillH + _trackPadV * 2;
        final innerW = constraints.maxWidth - _hPad * 2;
        final pillW = (innerW - _gap * (count - 1)) / count;

        return AnimatedBuilder(
          animation: Listenable.merge([_slideCurve, _pinch, _bounce]),
          builder: (context, _) {
            final t = _slideCurve.value;
            final caretIndex = _fromIndex + (_toIndex - _fromIndex) * t;
            final caretCenter =
                _hPad + caretIndex * (pillW + _gap) + pillW / 2;

            return SizedBox(
              height: trackH + _caretH + 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Frosted track (rounded capsule)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: trackH,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(trackH / 2),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.45),
                            const Color(0xFFB8DCEF).withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.28),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sliding caret under active pill
                  Positioned(
                    left: caretCenter - _caretW / 2,
                    top: trackH - 1,
                    width: _caretW,
                    height: _caretH,
                    child: CustomPaint(
                      painter: _CaretPainter(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                  // Vertical oval pills
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
                            child: _OvalPill(
                              item: VerticalCategoryBar.items[i],
                              selected: i == _toIndex,
                              height: _pillH,
                              pinch: _pinchSlug ==
                                      VerticalCategoryBar.items[i].slug
                                  ? _pinch
                                  : null,
                              bounce: i == _toIndex ? _bounce : null,
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

class _OvalPill extends StatelessWidget {
  const _OvalPill({
    required this.item,
    required this.selected,
    required this.height,
    required this.onTap,
    this.pinch,
    this.bounce,
  });

  final _VertItem item;
  final bool selected;
  final double height;
  final VoidCallback onTap;
  final Animation<double>? pinch;
  final Animation<double>? bounce;

  @override
  Widget build(BuildContext context) {
    final theme = VerticalTheme.of(item.slug);

    Widget icon = SizedBox(
      width: 32,
      height: 32,
      child: item.isPng
          ? Image.asset(
              item.asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 18,
              ),
            )
          : SvgPicture.asset(
              item.asset,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
    );

    if (pinch != null) {
      icon = AnimatedBuilder(
        animation: pinch!,
        builder: (context, child) {
          final t = pinch!.value;
          late final double scale;
          late final double glow;
          if (t < 0.30) {
            final p = Curves.easeIn.transform(t / 0.30);
            scale = 1.0 - 0.28 * p;
            glow = 0.55 * p;
          } else {
            final p = Curves.elasticOut.transform((t - 0.30) / 0.70);
            scale = 0.72 + 0.40 * p;
            glow = 0.55 * (1 - ((t - 0.30) / 0.70)).clamp(0.0, 1.0);
          }
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (glow > 0.04)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: glow * 0.5),
                  ),
                ),
              Transform.scale(scale: scale, child: child),
            ],
          );
        },
        child: icon,
      );
    }

    Widget pill = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: height,
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.95 : 0.2),
              width: selected ? 2.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? theme.primaryDark.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.18),
                offset: Offset(0, selected ? 5 : 2),
                blurRadius: selected ? 0 : 4,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 5),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
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

    if (bounce != null) {
      pill = AnimatedBuilder(
        animation: bounce!,
        builder: (context, child) {
          final t = bounce!.value;
          final scale = t < 0.32
              ? 1.0 - 0.12 * (t / 0.32)
              : 0.88 +
                  0.18 * Curves.elasticOut.transform((t - 0.32) / 0.68);
          return Transform.scale(scale: scale, child: child);
        },
        child: pill,
      );
    }

    return pill;
  }
}

class _CaretPainter extends CustomPainter {
  _CaretPainter({required this.color});

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
