import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/api_endpoints.dart';
import '../../constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../shared/widgets.dart';
import '../providers.dart';

final productListProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, ProductListArgs>((ref, args) {
  return ref.watch(catalogRepositoryProvider).listProducts(
        vertical: ref.watch(verticalProvider),
        search: args.search,
        endpoint: args.endpoint,
        columnFilters: args.columnFilters,
        limit: 40,
      );
});

class ProductListArgs {
  const ProductListArgs({
    this.search,
    this.endpoint,
    this.categoryId,
    this.manufacturerId,
  });

  final String? search;
  final String? endpoint;
  final int? categoryId;
  final int? manufacturerId;

  List<List<dynamic>>? get columnFilters {
    final filters = <List<dynamic>>[];
    if (categoryId != null) filters.add(['category.id', categoryId]);
    if (manufacturerId != null) filters.add(['manufacturer.id', manufacturerId]);
    return filters.isEmpty ? null : filters;
  }

  @override
  bool operator ==(Object other) =>
      other is ProductListArgs &&
      other.search == search &&
      other.endpoint == endpoint &&
      other.categoryId == categoryId &&
      other.manufacturerId == manufacturerId;

  @override
  int get hashCode => Object.hash(search, endpoint, categoryId, manufacturerId);
}

enum _LocalSort { relevance, priceLow, priceHigh, rating }

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    super.key,
    this.search,
    this.endpoint,
    this.categoryId,
    this.manufacturerId,
  });

  final String? search;
  final String? endpoint;
  final int? categoryId;
  final int? manufacturerId;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  bool _onSaleOnly = false;
  bool _inStockOnly = false;
  double _minRating = 0;
  _LocalSort _sort = _LocalSort.relevance;

  List<ProductModel> _applyLocalFilters(List<ProductModel> items) {
    var list = items.where((p) {
      if (_onSaleOnly && !p.hasDiscount) return false;
      if (_inStockOnly && (p.quantity ?? 0) <= 0) return false;
      if (_minRating > 0 && (p.rating ?? 0) < _minRating) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _LocalSort.relevance:
        break;
      case _LocalSort.priceLow:
        list.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
        break;
      case _LocalSort.priceHigh:
        list.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
        break;
      case _LocalSort.rating:
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
    }
    return list;
  }

  Future<void> _openFilterSheet() async {
    var onSale = _onSaleOnly;
    var inStock = _inStockOnly;
    var minRating = _minRating;
    var sort = _sort;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.paddingOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filter & sort',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'On sale only',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                    value: onSale,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setModal(() => onSale = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'In stock only',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                    value: inStock,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setModal(() => inStock = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Minimum rating',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Slider(
                    value: minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: minRating == 0 ? 'Any' : minRating.toStringAsFixed(1),
                    activeColor: AppColors.primary,
                    onChanged: (v) => setModal(() => minRating = v),
                  ),
                  Text(
                    'Sort by',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in const [
                        (_LocalSort.relevance, 'Relevance'),
                        (_LocalSort.priceLow, 'Price ↑'),
                        (_LocalSort.priceHigh, 'Price ↓'),
                        (_LocalSort.rating, 'Top rated'),
                      ])
                        ChoiceChip(
                          label: Text(entry.$2),
                          selected: sort == entry.$1,
                          selectedColor: AppColors.primarySoft,
                          labelStyle: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: sort == entry.$1
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          onSelected: (_) => setModal(() => sort = entry.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModal(() {
                              onSale = false;
                              inStock = false;
                              minRating = 0;
                              sort = _LocalSort.relevance;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: Text(
                            'Apply',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (applied == true && mounted) {
      setState(() {
        _onSaleOnly = onSale;
        _inStockOnly = inStock;
        _minRating = minRating;
        _sort = sort;
      });
    }
  }

  bool get _hasActiveFilters =>
      _onSaleOnly || _inStockOnly || _minRating > 0 || _sort != _LocalSort.relevance;

  @override
  Widget build(BuildContext context) {
    final mappedEndpoint = switch (widget.endpoint) {
      'sales' => ApiEndpoints.productSales,
      'best-sellers' => ApiEndpoints.productBestSellers,
      'limited-edition' => ApiEndpoints.productLimited,
      'trending' => '/product/trending',
      _ => null,
    };
    final args = ProductListArgs(
      search: widget.search,
      endpoint: mappedEndpoint,
      categoryId: widget.categoryId,
      manufacturerId: widget.manufacturerId,
    );
    final async = ref.watch(productListProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.search?.isNotEmpty == true ? 'Search' : 'Products',
        ),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              smallSize: 8,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: async.when(
        data: (items) {
          final filtered = _applyLocalFilters(items);
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No products found', style: GoogleFonts.manrope()),
                  if (_hasActiveFilters) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        _onSaleOnly = false;
                        _inStockOnly = false;
                        _minRating = 0;
                        _sort = _LocalSort.relevance;
                      }),
                      child: Text(
                        'Clear filters',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return Column(
            children: [
              if (_hasActiveFilters)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    children: [
                      if (_onSaleOnly)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: const Text('On sale'),
                            onDeleted: () => setState(() => _onSaleOnly = false),
                          ),
                        ),
                      if (_inStockOnly)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: const Text('In stock'),
                            onDeleted: () => setState(() => _inStockOnly = false),
                          ),
                        ),
                      if (_minRating > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text('${_minRating.toStringAsFixed(1)}+ ★'),
                            onDeleted: () => setState(() => _minRating = 0),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 300,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return ProductCard(
                      product: p,
                      onTap: () =>
                          context.push(AppRoutes.product('${p.slug ?? p.id}')),
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
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productSearchProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: SearchField(
              controller: _controller,
              onSubmitted: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Text(
                      'Search products & brands',
                      style: GoogleFonts.manrope(color: AppColors.textMuted),
                    ),
                  )
                : async.when(
                    data: (items) => ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = items[i];
                        return ListTile(
                          title: Text(p.name),
                          subtitle: Text(formatRs(p.displayPrice)),
                          onTap: () =>
                              context.push(AppRoutes.product('${p.slug ?? p.id}')),
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                  ),
          ),
        ],
      ),
    );
  }
}
