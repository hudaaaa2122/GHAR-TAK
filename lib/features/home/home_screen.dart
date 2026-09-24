import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_fonts.dart';

import '../../constants/app_routes.dart';
import '../../constants/figma_assets.dart';
import '../../core/location/delivery_location.dart';
import '../../core/location/delivery_location_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/vertical_theme.dart';
import '../../data/models/models.dart';
import '../../shared/vertical_category_bar.dart';
import '../../shared/widgets.dart';
import '../account/figma_screens.dart' show showVoiceSearchDialog;
import '../location/delivery_location_gate.dart';
import '../providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialVertical});

  final String? initialVertical;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static bool _gatePrompted = false;

  @override
  void initState() {
    super.initState();
    final slug = widget.initialVertical;
    if (slug != null && slug.isNotEmpty) {
      Future.microtask(() {
        ref.read(verticalProvider.notifier).state = slug;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowDeliveryGate();
    });
  }

  Future<void> _maybeShowDeliveryGate() async {
    if (_gatePrompted || !mounted) return;
    // Wait for location provider so persisted pin can clear the gate flag.
    await ref.read(deliveryLocationProvider.future);
    if (!mounted) return;
    if (!ref.read(needsDeliveryGateProvider)) return;
    _gatePrompted = true;
    await showDeliveryLocationGate(context, barrierDismissible: true);
  }

  @override
  Widget build(BuildContext context) {
    final vertical = ref.watch(verticalProvider);
    final theme = ref.watch(verticalThemeProvider);
    final browseTiles = ref.watch(browseTilesProvider);
    final banners = ref.watch(bannersProvider);
    final offers = ref.watch(offersProvider);
    final best = ref.watch(bestSellersProvider);
    final limited = ref.watch(limitedStockProvider);
    final trending = ref.watch(trendingProvider);
    final newArrivals = ref.watch(newArrivalsProvider);
    final isB2B =
        vertical == 'business' || vertical == 'shop' || vertical == 'b2b';

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: RefreshIndicator(
        color: theme.primary,
        onRefresh: () async {
          ref.invalidate(browseTilesProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(manufacturersProvider);
          ref.invalidate(bannersProvider);
          ref.invalidate(offersProvider);
          ref.invalidate(bestSellersProvider);
          ref.invalidate(limitedStockProvider);
          ref.invalidate(trendingProvider);
          ref.invalidate(newArrivalsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _WebHomeHeader(
                vertical: vertical,
                onVerticalChanged: (v) =>
                    ref.read(verticalProvider.notifier).state = v,
              ),
            ),
            SliverToBoxAdapter(
              child: _HomeBannerCarousel(asyncBanners: banners),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Shop by Category',
                actionLabel: 'See All',
                onAction: () => context.go(AppRoutes.categories),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 118,
                child: browseTiles.when(
                  data: (tiles) {
                    if (tiles.isEmpty) {
                      return Center(
                        child: Text(
                          'No categories for this vertical',
                          style: AppFonts.style(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      itemCount: tiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final c = tiles[i];
                        final url = resolveMediaUrl(c.imageUrl);
                        return InkWell(
                          onTap: () => context.push(
                            AppRoutes.productsQuery(
                              categoryId: c.id,
                              categoryIdKey: true,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 84,
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: AppColors.cardShadow,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: url.isEmpty
                                      ? Center(
                                          child: Text(
                                            c.name.length >= 2
                                                ? c.name
                                                    .substring(0, 2)
                                                    .toUpperCase()
                                                : c.name,
                                            style: AppFonts.style(
                                              fontWeight: FontWeight.w800,
                                              color: theme.primary,
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: CachedNetworkImage(
                                            imageUrl: url,
                                            fit: BoxFit.contain,
                                            width: 56,
                                            height: 56,
                                            httpHeaders: const {
                                              'Accept': 'image/*,*/*',
                                            },
                                            errorWidget: (_, __, ___) =>
                                                Center(
                                              child: Text(
                                                c.name.length >= 2
                                                    ? c.name
                                                        .substring(0, 2)
                                                        .toUpperCase()
                                                    : c.name,
                                                style: AppFonts.style(
                                                  fontWeight: FontWeight.w800,
                                                  color: theme.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.style(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      e.toString(),
                      style: AppFonts.style(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Website HomeSaleBanner ("sale") — shown for grocery/pharmacy/bakery/business.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: PromoBannerTeal(
                  onExplore: () => context.push(
                    AppRoutes.productsQuery(endpoint: 'sales'),
                  ),
                ),
              ),
            ),
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
                title: isB2B ? 'B2B products' : 'Best sellers',
                subtitle: isB2B
                    ? 'Bulk packs available for business orders'
                    : 'What Pakistan is buying this week',
                asyncProducts: best,
                onViewAll: () => context.push(
                  AppRoutes.productsQuery(endpoint: 'best-sellers'),
                ),
              ),
            ),
            // Website HomeSaleBanner ("limited").
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: PromoBannerOrange(
                  onShop: () => context.push(
                    AppRoutes.productsQuery(endpoint: 'limited-edition'),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRail(
                title: 'Limited stock',
                subtitle: 'Selling fast – grab them before they\'re gone',
                asyncProducts: limited,
                sellingFast: true,
                onViewAll: () => context.push(
                  AppRoutes.productsQuery(endpoint: 'limited-edition'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRail(
                title: 'Trending now',
                subtitle: 'Popular picks right now',
                asyncProducts: trending,
                onViewAll: () => context.push(
                  AppRoutes.productsQuery(endpoint: 'trending'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRail(
                title: 'New arrivals',
                subtitle: 'Fresh finds this month',
                asyncProducts: newArrivals,
                onViewAll: () => context.push(
                  AppRoutes.productsQuery(endpoint: 'new-arrivals'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _WebHomeHeader extends ConsumerWidget {
  const _WebHomeHeader({
    required this.vertical,
    required this.onVerticalChanged,
  });

  final String vertical;
  final ValueChanged<String> onVerticalChanged;

  Future<void> _openLocation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDeliveryLocationGate(context, barrierDismissible: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(deliveryLocationProvider);
    final locationLabel = locationAsync.when(
      data: (loc) => loc.label,
      loading: () => 'Set your location',
      error: (_, __) => DeliveryLocation.fallback.label,
    );
    final itemCount = ref.watch(catalogProductCountProvider).valueOrNull;
    final countLabel = itemCount == null
        ? 'Search items…'
        : 'Search ${NumberFormat('#,###').format(itemCount)} items';

    return ColoredBox(
      color: AppPalette.of(context).surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: VerticalCategoryBar(
                selected: vertical,
                onChanged: onVerticalChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Material(
                color: AppPalette.of(context).surface,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.only(left: 8, right: 6),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SvgPicture.asset(
                          FigmaAssets.logoMark,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push(AppRoutes.search),
                          borderRadius: BorderRadius.circular(8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              countLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.style(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _SearchFieldIcon(
                        icon: Icons.mic_none_rounded,
                        tooltip: 'Voice search',
                        onTap: () => showVoiceSearchDialog(context),
                      ),
                      _SearchFieldIcon(
                        icon: Icons.photo_camera_outlined,
                        tooltip: 'Search by photo',
                        onTap: () =>
                            context.push(AppRoutes.scanMode('camera')),
                      ),
                      _SearchFieldIcon(
                        icon: Icons.qr_code_scanner_rounded,
                        tooltip: 'Scan barcode',
                        onTap: () => context.push(AppRoutes.scanMode('qr')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: InkWell(
                onTap: () => _openLocation(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      'Change',
                      style: AppFonts.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

class _SearchFieldIcon extends StatelessWidget {
  const _SearchFieldIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBannerCarousel extends ConsumerWidget {
  const _HomeBannerCarousel({required this.asyncBanners});

  final AsyncValue<List<BannerModel>> asyncBanners;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(verticalThemeProvider);

    return asyncBanners.when(
      data: (banners) {
        final slides = banners.isEmpty
            ? [
                BannerModel(
                  id: -1,
                  title: theme.heroHeadline,
                  description: theme.heroSubtitle,
                ),
              ]
            : banners;
        return _VerticalHeroPager(slides: slides, theme: theme);
      },
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: _VerticalHeroCard(
          theme: theme,
          headline: theme.heroHeadline,
          subtitle: theme.heroSubtitle,
          onExplore: () => context.push(
            AppRoutes.productsQuery(endpoint: 'sales'),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: _VerticalHeroCard(
          theme: theme,
          headline: theme.heroHeadline,
          subtitle: theme.heroSubtitle,
          onExplore: () => context.push(
            AppRoutes.productsQuery(endpoint: 'sales'),
          ),
        ),
      ),
    );
  }
}

class _VerticalHeroPager extends StatefulWidget {
  const _VerticalHeroPager({required this.slides, required this.theme});

  final List<BannerModel> slides;
  final VerticalTheme theme;

  @override
  State<_VerticalHeroPager> createState() => _VerticalHeroPagerState();
}

class _VerticalHeroPagerState extends State<_VerticalHeroPager> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    final theme = widget.theme;
    final multi = slides.length > 1;

    return Column(
      children: [
        SizedBox(
          height: 236,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final b = slides[i];
              final url = resolveMediaUrl(b.image?.best);
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: _VerticalHeroCard(
                  theme: theme,
                  headline: b.displayHeadline(theme.heroHeadline),
                  subtitle: (b.description?.trim().isNotEmpty == true)
                      ? b.description!.trim()
                      : theme.heroSubtitle,
                  eyebrow: b.subtitle?.trim().isNotEmpty == true
                      ? b.subtitle!.trim().toUpperCase()
                      : "TODAY'S DEAL",
                  cta: b.buttonText?.trim().isNotEmpty == true
                      ? b.buttonText!.trim()
                      : 'Explore more',
                  imageUrl: url.isEmpty ? null : url,
                  onExplore: () {
                    context.push(
                      AppRoutes.productsQuery(endpoint: 'sales'),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (multi)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: active ? 16 : 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: active ? theme.primary : const Color(0xFFD5DBE3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _VerticalHeroCard extends StatelessWidget {
  const _VerticalHeroCard({
    required this.theme,
    required this.headline,
    required this.subtitle,
    required this.onExplore,
    this.eyebrow = "TODAY'S DEAL",
    this.cta = 'Explore more',
    this.imageUrl,
  });

  final VerticalTheme theme;
  final String headline;
  final String subtitle;
  final String eyebrow;
  final String cta;
  final String? imageUrl;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onExplore,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: theme.gradient,
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                if (imageUrl != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    top: 40,
                    width: 110,
                    child: Opacity(
                      opacity: 0.92,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    imageUrl != null ? 118 : 16,
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.heroAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          eyebrow,
                          style: AppFonts.style(
                            color: theme.heroAccentText,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          color: theme.heroBody,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onExplore,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cta,
                                  style: AppFonts.style(
                                    fontWeight: FontWeight.w800,
                                    color: theme.heroAccentText,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: theme.heroAccentText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
          height: 248,
          child: asyncProducts.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No products yet',
                    style: AppFonts.style(color: AppColors.textMuted),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = items[i];
                  final screenW = MediaQuery.sizeOf(context).width;
                  // Fit exactly 3 cards in the viewport (padding 14+14, gaps 8+8).
                  final cardW = (screenW - 28 - 16) / 3;
                  return ProductCard(
                    product: p,
                    width: cardW,
                    sellingFast: sellingFast,
                    onTap: () => context.push(AppRoutes.product('${p.slug ?? p.id}')),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                _friendlyError(e),
                style: AppFonts.style(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

String _friendlyError(Object e) {
  final raw = e.toString();
  if (raw.contains('DISTINCT ON') || raw.contains('psycopg2')) {
    return 'Offers are temporarily unavailable. Please try again later.';
  }
  if (raw.length > 120) {
    return 'Could not load products. Pull to refresh.';
  }
  return raw.replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
}

