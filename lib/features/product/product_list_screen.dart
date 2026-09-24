import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_fonts.dart';

import '../../constants/api_endpoints.dart';
import '../../constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../shared/widgets.dart';
import '../providers.dart';

final productListProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, ProductListArgs>((ref, args) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final vertical = ref.watch(verticalProvider);
  if (args.barcode != null && args.barcode!.trim().isNotEmpty) {
    final byCode = await repo.findByBarcode(
      code: args.barcode!,
      vertical: vertical,
    );
    if (byCode.isNotEmpty) return byCode;
    // Fall through to searchTerm if provided.
    if (args.search == null || args.search!.trim().isEmpty) {
      return byCode;
    }
  }
  return repo.listProducts(
    vertical: vertical,
    search: args.search,
    endpoint: args.endpoint,
    columnFilters: args.columnFilters,
    limit: 40,
  );
});

class ProductListArgs {
  const ProductListArgs({
    this.search,
    this.barcode,
    this.endpoint,
    this.categoryId,
    this.categoryIsRoot = false,
    this.categoryIdKey = false,
    this.manufacturerId,
  });

  final String? search;
  final String? barcode;
  final String? endpoint;
  final int? categoryId;
  final bool categoryIsRoot;
  /// Website `getCategoryHref`: `[["category_id", tile.id]]`.
  final bool categoryIdKey;
  final int? manufacturerId;

  List<List<dynamic>>? get columnFilters {
    final filters = <List<dynamic>>[];
    if (categoryId != null) {
      if (categoryIdKey) {
        filters.add(['category_id', categoryId]);
      } else {
        filters.add([
          categoryIsRoot ? 'category.root_id' : 'category.id',
          categoryId,
        ]);
      }
    }
    if (manufacturerId != null) filters.add(['manufacturer.id', manufacturerId]);
    if (barcode != null && barcode!.trim().isNotEmpty) {
      // Prefer bar_code; backend may also expose barcode / sku.
      filters.add(['bar_code', barcode!.trim()]);
    }
    return filters.isEmpty ? null : filters;
  }

  @override
  bool operator ==(Object other) =>
      other is ProductListArgs &&
      other.search == search &&
      other.barcode == barcode &&
      other.endpoint == endpoint &&
      other.categoryId == categoryId &&
      other.categoryIsRoot == categoryIsRoot &&
      other.categoryIdKey == categoryIdKey &&
      other.manufacturerId == manufacturerId;

  @override
  int get hashCode => Object.hash(
        search,
        barcode,
        endpoint,
        categoryId,
        categoryIsRoot,
        categoryIdKey,
        manufacturerId,
      );
}

enum _LocalSort { relevance, priceLow, priceHigh, rating }

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    super.key,
    this.search,
    this.barcode,
    this.endpoint,
    this.categoryId,
    this.categoryIsRoot = false,
    this.categoryIdKey = false,
    this.manufacturerId,
  });

  final String? search;
  final String? barcode;
  final String? endpoint;
  final int? categoryId;
  final bool categoryIsRoot;
  final bool categoryIdKey;
  final int? manufacturerId;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  bool _onSaleOnly = false;
  bool _inStockOnly = false;
  double _minRating = 0;
  double _minPrice = 0;
  double _maxPrice = 20000;
  int? _brandId;
  _LocalSort _sort = _LocalSort.relevance;

  List<ProductModel> _applyLocalFilters(List<ProductModel> items) {
    // Brand is applied via API columnFilters (manufacturer.id) when selected.
    var list = items.where((p) {
      if (_onSaleOnly && !p.hasDiscount) return false;
      if (_inStockOnly && !p.inStock) return false;
      if (_minRating > 0 && (p.rating ?? 0) < _minRating) return false;
      if (p.displayPrice < _minPrice || p.displayPrice > _maxPrice) {
        return false;
      }
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
    var minPrice = _minPrice;
    var maxPrice = _maxPrice;
    var brandId = _brandId;
    var sort = _sort;
    final brands = ref.read(manufacturersProvider).valueOrNull ?? [];

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
              child: SingleChildScrollView(
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
                      style: AppFonts.style(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PRICE',
                      style: AppFonts.style(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    RangeSlider(
                      values: RangeValues(minPrice, maxPrice),
                      min: 0,
                      max: 20000,
                      divisions: 40,
                      labels: RangeLabels(
                        'Rs ${minPrice.round()}',
                        'Rs ${maxPrice.round()}',
                      ),
                      activeColor: AppColors.primary,
                      onChanged: (v) => setModal(() {
                        minPrice = v.start;
                        maxPrice = v.end;
                      }),
                    ),
                    if (brands.isNotEmpty) ...[
                      Text(
                        'BRANDS',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: brandId == null,
                            selectedColor: AppColors.primarySoft,
                            onSelected: (_) =>
                                setModal(() => brandId = null),
                          ),
                          for (final b in brands.take(12))
                            ChoiceChip(
                              label: Text(b.name),
                              selected: brandId == b.id,
                              selectedColor: AppColors.primarySoft,
                              onSelected: (_) =>
                                  setModal(() => brandId = b.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'On sale only',
                        style: AppFonts.style(fontWeight: FontWeight.w600),
                      ),
                      value: onSale,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setModal(() => onSale = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'In stock only',
                        style: AppFonts.style(fontWeight: FontWeight.w600),
                      ),
                      value: inStock,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setModal(() => inStock = v),
                    ),
                    Text(
                      'Minimum rating',
                      style: AppFonts.style(
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
                      label: minRating == 0
                          ? 'Any'
                          : minRating.toStringAsFixed(1),
                      activeColor: AppColors.primary,
                      onChanged: (v) => setModal(() => minRating = v),
                    ),
                    Text(
                      'Sort by',
                      style: AppFonts.style(
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
                            labelStyle: AppFonts.style(
                              fontWeight: FontWeight.w700,
                              color: sort == entry.$1
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            onSelected: (_) =>
                                setModal(() => sort = entry.$1),
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
                                minPrice = 0;
                                maxPrice = 20000;
                                brandId = null;
                                sort = _LocalSort.relevance;
                              });
                            },
                            child: Text(
                              'Reset',
                              style: AppFonts.style(
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
                              style: AppFonts.style(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
        _minPrice = minPrice;
        _maxPrice = maxPrice;
        _brandId = brandId;
        _sort = sort;
      });
    }
  }

  bool get _hasActiveFilters =>
      _onSaleOnly ||
      _inStockOnly ||
      _minRating > 0 ||
      _minPrice > 0 ||
      _maxPrice < 20000 ||
      _brandId != null ||
      _sort != _LocalSort.relevance;

  @override
  Widget build(BuildContext context) {
    final mappedEndpoint = switch (widget.endpoint) {
      'sales' => ApiEndpoints.productSales,
      'best-sellers' => ApiEndpoints.productBestSellers,
      'limited-edition' => ApiEndpoints.productLimited,
      'trending' => ApiEndpoints.productTrending,
      'new-arrivals' => ApiEndpoints.productNewArrivals,
      _ => null,
    };
    final args = ProductListArgs(
      search: widget.search,
      barcode: widget.barcode,
      endpoint: mappedEndpoint,
      categoryId: widget.categoryId,
      categoryIsRoot: widget.categoryIsRoot,
      categoryIdKey: widget.categoryIdKey,
      // Sheet brand selection overrides route manufacturer when set.
      manufacturerId: _brandId ?? widget.manufacturerId,
    );
    // Warm brands for filter sheet (website columnFilters manufacturer_id).
    ref.watch(manufacturersProvider);
    final async = ref.watch(productListProvider(args));
    final title = widget.barcode?.isNotEmpty == true
        ? 'Barcode'
        : (widget.search?.isNotEmpty == true ? 'Search' : 'Products');

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      appBar: AppBar(
        title: Text(title),
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
                  Text('No products found', style: AppFonts.style()),
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
                        style: AppFonts.style(
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    // Clear immediately when empty; debounce live search otherwise.
    if (trimmed.isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = trimmed);
    });
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
              autofocus: true,
              showSearchButton: false,
              onChanged: _onQueryChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                setState(() => _query = v.trim());
              },
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Text(
                      'Start typing to search products & brands',
                      style: AppFonts.style(color: AppColors.textMuted),
                    ),
                  )
                : async.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No results for “$_query”',
                            style: AppFonts.style(color: AppColors.textMuted),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = items[i];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(formatRs(p.displayPrice)),
                            onTap: () => context.push(
                              AppRoutes.product('${p.slug ?? p.id}'),
                            ),
                          );
                        },
                      );
                    },
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
