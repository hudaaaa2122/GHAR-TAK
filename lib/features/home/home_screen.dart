import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/vertical_theme.dart';
import '../../data/models/models.dart';
import '../../shared/vertical_category_bar.dart';
import '../../shared/widgets.dart';
import '../account/figma_screens.dart';
import '../providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialVertical});

  final String? initialVertical;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    final slug = widget.initialVertical;
    if (slug != null && slug.isNotEmpty) {
      Future.microtask(() {
        ref.read(verticalProvider.notifier).state = slug;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vertical = ref.watch(verticalProvider);
    final theme = ref.watch(verticalThemeProvider);
    final brands = ref.watch(manufacturersProvider);
    final offers = ref.watch(offersProvider);
    final best = ref.watch(bestSellersProvider);
    final limited = ref.watch(limitedStockProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final name = (user?.name ?? 'Guest').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: theme.primary,
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(manufacturersProvider);
          ref.invalidate(offersProvider);
          ref.invalidate(bestSellersProvider);
          ref.invalidate(limitedStockProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _FigmaHomeHeader(
                greeting: '${_greeting()}, $name!',
                vertical: vertical,
                onVerticalChanged: (v) =>
                    ref.read(verticalProvider.notifier).state = v,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Shop by Category',
                actionLabel: 'See All',
                onAction: () => context.go(AppRoutes.categories),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: brands.when(
                  data: (list) => ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final url = resolveMediaUrl(m.image?.best);
                      return InkWell(
                        onTap: () => context.push(
                          AppRoutes.productsQuery(manufacturerId: m.id),
                        ),
                        child: SizedBox(
                          width: 68,
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: theme.primarySoft,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: url.isEmpty
                                    ? Center(
                                        child: Text(
                                          m.name.length >= 2
                                              ? m.name.substring(0, 2).toUpperCase()
                                              : m.name,
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w800,
                                            color: theme.primary,
                                          ),
                                        ),
                                      )
                                    : Image.network(url, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                m.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: PromoBannerTeal(
                  onExplore: () =>
                      context.push(AppRoutes.productsQuery(endpoint: 'sales')),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            // Offers → Best sellers → Breakfast & Spreads (shared) → Limited stock
            SliverToBoxAdapter(
              child: _ProductRail(
                title: 'Offers',
                subtitle: 'Best prices on weekly basics',
                asyncProducts: offers,
                onViewAll: () =>
                    context.push(AppRoutes.productsQuery(endpoint: 'sales')),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRail(
                title: 'Best sellers',
                subtitle: 'Customer favourites this week',
                asyncProducts: best,
                onViewAll: () =>
                    context.push(AppRoutes.productsQuery(endpoint: 'best-sellers')),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                child: PromoBannerOrange(
                  onShop: () => context.push(
                    AppRoutes.productsQuery(endpoint: 'sales'),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRail(
                title: 'Limited stock',
                subtitle: 'Going fast — grab them soon',
                asyncProducts: limited,
                sellingFast: true,
                onViewAll: () =>
                    context.push(AppRoutes.productsQuery(endpoint: 'limited-edition')),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _FigmaHomeHeader extends StatelessWidget {
  const _FigmaHomeHeader({
    required this.greeting,
    required this.vertical,
    required this.onVerticalChanged,
  });

  final String greeting;
  final String vertical;
  final ValueChanged<String> onVerticalChanged;

  @override
  Widget build(BuildContext context) {
    final theme = VerticalTheme.of(vertical);
    final w = MediaQuery.sizeOf(context).width;
    final radius = BrandHeaderShapeClipper.radiusForWidth(w);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      child: Stack(
        children: [
          // Soft overlapping circles + diagonal bands (recording décor)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HeaderBandsPainter(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            right: -56,
            top: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 18,
            child: IgnorePointer(
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -40,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            left: 40,
            top: 90,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  width: 120,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, radius * 0.55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                VerticalCategoryBar(
                  selected: vertical,
                  onChanged: onVerticalChanged,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Gulberg III, Lahore',
                                style: GoogleFonts.manrope(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            greeting,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderCircleIcon(
                      icon: Icons.favorite_border,
                      onTap: () => context.push(AppRoutes.wishlist),
                    ),
                    const SizedBox(width: 8),
                    _HeaderCircleIcon(
                      icon: Icons.notifications_none,
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.search),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search for products, brands & categories',
                              style: GoogleFonts.manrope(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Search by photo',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                context.push(AppRoutes.scanMode('camera')),
                            icon: Icon(Icons.photo_camera_outlined, size: 20, color: theme.primary),
                          ),
                          IconButton(
                            tooltip: 'Scan barcode',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                context.push(AppRoutes.scanMode('qr')),
                            icon: Icon(Icons.qr_code_scanner, size: 20, color: theme.primary),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => showVoiceSearchDialog(context),
                            icon: Icon(Icons.mic_none, size: 20, color: theme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _HeaderCircleIcon extends StatelessWidget {
  const _HeaderCircleIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Diagonal translucent bands behind the category strip (recording background).
class _HeaderBandsPainter extends CustomPainter {
  _HeaderBandsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final band = Path()
      ..moveTo(size.width * 0.35, -20)
      ..lineTo(size.width * 0.72, -20)
      ..lineTo(size.width * 0.45, size.height + 20)
      ..lineTo(size.width * 0.08, size.height + 20)
      ..close();
    canvas.drawPath(band, paint);

    final band2 = Path()
      ..moveTo(size.width * 0.62, -20)
      ..lineTo(size.width * 1.05, -20)
      ..lineTo(size.width * 0.78, size.height + 20)
      ..lineTo(size.width * 0.38, size.height + 20)
      ..close();
    canvas.drawPath(band2, paint..color = color.withValues(alpha: color.a * 0.7));
  }

  @override
  bool shouldRepaint(covariant _HeaderBandsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ProductRail extends ConsumerWidget {
  const _ProductRail({
    required this.title,
    required this.subtitle,
    required this.asyncProducts,
    required this.onViewAll,
    this.sellingFast = false,
  });

  final String title;
  final String subtitle;
  final AsyncValue<List<ProductModel>> asyncProducts;
  final VoidCallback onViewAll;
  final bool sellingFast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          onAction: onViewAll,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: asyncProducts.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No products yet',
                    style: GoogleFonts.manrope(color: AppColors.textMuted),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return ProductCard(
                    product: p,
                    sellingFast: sellingFast,
                    onTap: () => context.push(AppRoutes.product('${p.slug ?? p.id}')),
                    onAdd: () async {
                      try {
                        await ref.read(cartProvider.notifier).add(p);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(14),
              child: Text('$e', style: const TextStyle(color: AppColors.error)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

