import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../constants/app_routes.dart';
import '../../constants/figma_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../shared/brand_widgets.dart';

/// Splash — Figma node 318:6167. Hold 4s so splash is readable (no white flash).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2800), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    try {
      context.go(AppRoutes.intro);
    } catch (e, st) {
      debugPrint('Splash→Intro failed: $e\n$st');
      try {
        context.go(AppRoutes.login);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      body: SplashBrandCanvas(),
    );
  }
}

class _IntroPage {
  const _IntroPage({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
}

/// Welcome / onboarding — Figma Intro (273:846).
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _IntroPage(
      title: 'Shop Your Way',
      subtitle:
          'Take a snap, scan a QR code, or just say it,\nfind any product in seconds.',
      imageAsset: FigmaAssets.onboarding1,
    ),
    _IntroPage(
      title: 'Delivered Fast',
      subtitle:
          'Groceries, pharmacy, bakery and more —\nto your door in under an hour.',
      imageAsset: FigmaAssets.onboarding2,
    ),
    _IntroPage(
      title: 'We Make It Easy',
      subtitle:
          'Track live, pay your way, and reorder\nessentials in a tap.',
      imageAsset: FigmaAssets.onboarding3,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _skip() => context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          BrandCurveHeader(
            compact: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GherTakLogo(
                  variant: GherTakLogoVariant.onDark,
                  compact: true,
                  height: 52,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'SKIP',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final page = _pages[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                page.imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.primarySoft,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        page.subtitle,
                        textAlign: TextAlign.center,
                        style: AppFonts.style(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SmoothPageIndicator(
                        controller: _controller,
                        count: _pages.length,
                        effect: const ExpandingDotsEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 3.2,
                          spacing: 6,
                          activeDotColor: AppColors.primary,
                          dotColor: Color(0xFFD5DBE3),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: BrandGradientButton(
              label: _index == _pages.length - 1 ? 'Start shopping' : 'Next',
              onPressed: _next,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              top: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: AppFonts.style(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: Text(
                    'Sign In',
                    style: AppFonts.style(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
