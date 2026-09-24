import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/api_endpoints.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/storage/token_storage.dart';
import '../mock/mock_data.dart';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  static const _activeFilters = {
    'is_active': true,
    'category_is_active': true,
    'manufacturer_is_active': true,
    'shop_s_active': true,
  };

  Future<List<ProductModel>> listProducts({
    String? vertical,
    String? search,
    int page = 1,
    int limit = 20,
    String? endpoint,
    List<List<dynamic>>? columnFilters,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      var list = search != null && search.isNotEmpty
          ? MockData.search(search)
          : MockData.byEndpoint(endpoint, vertical: vertical);
      if (page > 1) {
        final start = (page - 1) * limit;
        if (start >= list.length) return [];
        list = list.skip(start).take(limit).toList();
      } else {
        list = list.take(limit).toList();
      }
      return list;
    }

    final query = <String, dynamic>{
      ..._activeFilters,
      'page': page,
      'limit': limit,
      'vertical': vertical ?? AppConfig.defaultVertical,
      if (search != null && search.isNotEmpty) 'searchTerm': search,
      if (columnFilters != null) 'columnFilters': jsonEncode(columnFilters),
    };
    final path = endpoint ?? ApiEndpoints.productList;
    final res = await _api.get<List<ProductModel>>(
      path,
      query: query,
      mapData: _mapProductList,
    );
    return res.data ?? [];
  }

  /// Resolve products for a scanned barcode (tries API filters + search fallback).
  Future<List<ProductModel>> findByBarcode({
    required String code,
    String? vertical,
  }) async {
    final cleaned = code.trim();
    if (cleaned.isEmpty) return const [];
    final needle = _normalizeBarcode(cleaned);
    if (needle.isEmpty) return const [];

    bool matches(ProductModel p) {
      final code = _normalizeBarcode(p.barCode ?? '');
      if (code.isEmpty) return false;
      return code == needle || code.endsWith(needle) || needle.endsWith(code);
    }

    List<ProductModel> exactOnly(List<ProductModel> list) =>
        list.where(matches).toList();

    Future<List<ProductModel>> byFilter(String field, String value) async {
      try {
        final list = await listProducts(
          vertical: vertical,
          columnFilters: [
            [field, value],
          ],
          limit: 40,
        );
        final exact = exactOnly(list);
        if (exact.isNotEmpty) return exact;
        // Trust a small filtered payload; reject large unfiltered dumps.
        if (list.isNotEmpty && list.length <= 5) return list;
        return const [];
      } catch (_) {
        return const [];
      }
    }

    // Catalog stores some codes with a leading "*" (e.g. *855434009699).
    final variants = <String>{
      cleaned,
      needle,
      if (!cleaned.startsWith('*')) '*$cleaned',
      if (!needle.startsWith('*')) '*$needle',
    };

    for (final field in ['bar_code', 'barcode', 'sku', 'product_code']) {
      for (final value in variants) {
        final hits = await byFilter(field, value);
        if (hits.isNotEmpty) return hits;
      }
    }

    // Keyword search, then prefer exact barcode/sku matches client-side.
    try {
      for (final value in variants) {
        final searched = await listProducts(
          vertical: vertical,
          search: value,
          limit: 40,
        );
        if (searched.isEmpty) continue;
        final exact = exactOnly(searched);
        if (exact.isNotEmpty) return exact;
        if (searched.length <= 5) return searched;
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  static String _normalizeBarcode(String raw) {
    var t = raw.trim().toLowerCase();
    while (t.startsWith('*')) {
      t = t.substring(1);
    }
    return t.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<ProductModel> getProduct(String idOrSlug) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final p = MockData.productByIdOrSlug(idOrSlug);
      if (p == null) throw Exception('Product not found');
      return p;
    }

    final res = await _api.get<ProductModel>(
      ApiEndpoints.productRead(idOrSlug),
      mapData: (raw) {
        if (raw is Map) {
          return ProductModel.fromJson(Map<String, dynamic>.from(raw));
        }
        throw Exception('Invalid product');
      },
    );
    if (res.data == null) throw Exception(res.detail ?? 'Product not found');
    return res.data!;
  }

  Future<List<CategoryModel>> listCategories({String? vertical}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return MockData.categoriesForVertical(
        vertical ?? AppConfig.defaultVertical,
      );
    }

    final res = await _api.get<List<CategoryModel>>(
      ApiEndpoints.categoryList,
      query: {
        'is_active': true,
        'vertical': vertical ?? AppConfig.defaultVertical,
      },
      mapData: (raw) {
        final list = raw is List ? raw : (raw is Map ? raw['items'] : null);
        if (list is! List) return <CategoryModel>[];
        return list
            .whereType<Map>()
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return res.data ?? [];
  }

  /// Website home “Shop by category” — `GET /category/browse-tiles`.
  /// Backend may fill `image` from the first product (`is_fallback`) or a default.
  /// Note: API currently returns the same tiles for every vertical (empty
  /// `vertical_ids`), so we also apply a client-side vertical filter.
  Future<List<BrowseCategoryTile>> listBrowseTiles({String? vertical}) async {
    final slug = (vertical ?? AppConfig.defaultVertical).toLowerCase();
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final cats = MockData.categoriesForVertical(slug);
      return cats
          .map(
            (c) => BrowseCategoryTile(
              id: c.id,
              name: c.name,
              slug: c.slug,
              image: c.image,
            ),
          )
          .toList();
    }

    final res = await _api.get<List<BrowseCategoryTile>>(
      ApiEndpoints.categoryBrowseTiles,
      query: {
        'vertical': slug,
      },
      mapData: (raw) {
        final list = raw is List
            ? raw
            : (raw is Map ? (raw['data'] ?? raw['items']) : null);
        if (list is! List) return <BrowseCategoryTile>[];
        return list
            .whereType<Map>()
            .map(
              (e) => BrowseCategoryTile.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
    return _filterBrowseTilesForVertical(res.data ?? [], slug);
  }

  /// Client filter — mirrors intended storefront per vertical while API
  /// `vertical_ids` stay empty for all browse tiles.
  static List<BrowseCategoryTile> _filterBrowseTilesForVertical(
    List<BrowseCategoryTile> tiles,
    String vertical,
  ) {
    final active = tiles
        .where((t) => (t.productCount == null || t.productCount! > 0))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final keywords = _browseKeywordsForVertical(vertical);
    if (keywords == null || keywords.isEmpty) {
      return active;
    }

    final filtered = active.where((t) {
      final hay = '${t.slug ?? ''} ${t.name}'.toLowerCase();
      return keywords.any(hay.contains);
    }).toList();

    // Never leave the rail empty if the API payload is odd.
    return filtered.isNotEmpty ? filtered : active.take(8).toList();
  }

  static List<String>? _browseKeywordsForVertical(String vertical) {
    switch (vertical) {
      case 'pharmacy':
        return const [
          'beauty',
          'personal',
          'health',
          'household',
          'baby',
          'toddler',
          'medicine',
          'vitamin',
          'pharmacy',
        ];
      case 'bakery':
        return const [
          'food',
          'grocery',
          'beverage',
          'bakery',
          'bread',
          'cake',
          'pastry',
          'snack',
        ];
      case 'business':
      case 'shop':
      case 'b2b':
        return const [
          'food',
          'grocery',
          'office',
          'school',
          'business',
          'industrial',
          'electronic',
          'hardware',
          'tool',
          'home',
          'kitchen',
        ];
      case 'grocery':
      default:
        // Grocery keeps the full catalog (minus empty tiles).
        return null;
    }
  }

  Future<List<BannerModel>> listBanners({String? vertical}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      return MockData.banners;
    }

    final res = await _api.get<List<BannerModel>>(
      ApiEndpoints.bannerList,
      query: {
        'is_active': true,
        'vertical': vertical ?? AppConfig.defaultVertical,
      },
      mapData: (raw) {
        final list = raw is List ? raw : null;
        if (list == null) return <BannerModel>[];
        return list
            .whereType<Map>()
            .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return res.data ?? [];
  }

  Future<List<ManufacturerModel>> listManufacturers({String? vertical}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      return MockData.manufacturers;
    }

    final res = await _api.get<List<ManufacturerModel>>(
      ApiEndpoints.manufacturerList,
      query: {
        'is_active': true,
        'vertical': vertical ?? AppConfig.defaultVertical,
        'limit': 20,
      },
      mapData: (raw) {
        final list = raw is List ? raw : null;
        if (list == null) return <ManufacturerModel>[];
        return list
            .whereType<Map>()
            .map(
              (e) => ManufacturerModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
    return res.data ?? [];
  }

  /// Total catalog size for search placeholder (`Search N items`).
  Future<int> countProducts({String? vertical}) async {
    if (AppConfig.useMockData) {
      return MockData.byEndpoint(null, vertical: vertical).length;
    }
    final res = await _api.get<List<ProductModel>>(
      ApiEndpoints.productList,
      query: {
        ..._activeFilters,
        'page': 1,
        'limit': 1,
        'vertical': vertical ?? AppConfig.defaultVertical,
      },
      mapData: _mapProductList,
    );
    return res.totalCount ??
        res.total ??
        (res.data?.isNotEmpty == true ? 1 : 0);
  }

  List<ProductModel> _mapProductList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class CartRepository {
  CartRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;
  static const _guestKey = 'myapp_cart';

  Future<bool> _isGuest() async {
    final token = await _tokens.accessToken;
    return token == null || token.isEmpty;
  }

  Future<List<CartItemModel>> _loadGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_guestKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveGuest(List<CartItemModel> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _guestKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<CartItemModel>> list() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      return MockData.cartItems;
    }

    if (await _isGuest()) {
      return _loadGuest();
    }

    try {
      final res = await _api.get<List<CartItemModel>>(
        ApiEndpoints.cartMy,
        mapData: (raw) {
          if (raw is! List) return <CartItemModel>[];
          return raw
              .whereType<Map>()
              .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        },
      );
      res.ensureSuccess('Could not load cart');
      return res.data ?? [];
    } catch (_) {
      // Auth expired / network — fall back to local guest cart.
      return _loadGuest();
    }
  }

  Future<void> add({
    required int productId,
    required int shopId,
    int quantity = 1,
    int? variationOptionId,
    ProductModel? product,
  }) async {
    if (AppConfig.useMockData) {
      MockData.cartAdd(
        productId: productId,
        shopId: shopId,
        quantity: quantity,
        variationOptionId: variationOptionId,
        product: product,
      );
      return;
    }

    var resolvedShop = shopId;
    if (resolvedShop <= 0) {
      resolvedShop = product?.shopId ?? 0;
    }
    if (resolvedShop <= 0) {
      try {
        final fetched = await CatalogRepository(_api).getProduct('$productId');
        resolvedShop = fetched.shopId ?? 0;
        product ??= fetched;
      } catch (_) {}
    }

    if (await _isGuest()) {
      if (product == null) {
        throw ApiException('Could not add to cart');
      }
      final items = await _loadGuest();
      final idx = items.indexWhere(
        (i) =>
            i.product.id == productId &&
            i.variationOptionId == variationOptionId,
      );
      if (idx >= 0) {
        final cur = items[idx];
        items[idx] = CartItemModel(
          id: cur.id,
          quantity: cur.quantity + quantity,
          product: cur.product,
          variationOptionId: cur.variationOptionId,
          shopId: cur.shopId ?? resolvedShop,
        );
      } else {
        items.add(
          CartItemModel(
            id: productId,
            quantity: quantity,
            product: product,
            variationOptionId: variationOptionId,
            shopId: resolvedShop > 0 ? resolvedShop : product.shopId,
          ),
        );
      }
      await _saveGuest(items);
      return;
    }

    if (resolvedShop <= 0) {
      throw ApiException(
        'This product has no shop assigned. Please try another product.',
      );
    }

    final res = await _api.post(
      ApiEndpoints.cartAdd,
      body: {
        'product_id': productId,
        'shop_id': resolvedShop,
        'quantity': quantity,
        if (variationOptionId != null) 'variation_option_id': variationOptionId,
      },
    );
    res.ensureSuccess('Could not add to cart');
  }

  /// Website EditOrderDialog: `POST /cart/bulk-create` with `{ items: [...] }`.
  Future<void> bulkCreate(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return;
    if (AppConfig.useMockData) {
      for (final raw in items) {
        MockData.cartAdd(
          productId: (raw['product_id'] as num?)?.toInt() ?? 0,
          shopId: (raw['shop_id'] as num?)?.toInt() ?? 0,
          quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
          variationOptionId: (raw['variation_option_id'] as num?)?.toInt(),
        );
      }
      return;
    }

    if (await _isGuest()) {
      throw ApiException('Please sign in to edit an order.');
    }

    final resolved = <Map<String, dynamic>>[];
    for (final raw in items) {
      final productId = (raw['product_id'] as num?)?.toInt() ?? 0;
      var shopId = (raw['shop_id'] as num?)?.toInt() ?? 0;
      final qty = (raw['quantity'] as num?)?.toInt() ?? 1;
      final variation = (raw['variation_option_id'] as num?)?.toInt();
      if (productId <= 0 || qty <= 0) continue;
      if (shopId <= 0) {
        try {
          final p = await CatalogRepository(_api).getProduct('$productId');
          shopId = p.shopId ?? 0;
        } catch (_) {}
      }
      if (shopId <= 0) {
        throw ApiException(
          'This product has no shop assigned. Please try another product.',
        );
      }
      resolved.add({
        'product_id': productId,
        'shop_id': shopId,
        'quantity': qty,
        'variation_option_id': variation,
      });
    }

    final res = await _api.post(
      ApiEndpoints.cartBulkCreate,
      body: {'items': resolved},
    );
    res.ensureSuccess('Failed to load order items into cart');
  }

  Future<void> updateQuantity(
    int productId,
    int quantity, {
    int? variationOptionId,
  }) async {
    if (AppConfig.useMockData) {
      MockData.cartUpdateQty(
        productId,
        quantity,
        variationOptionId: variationOptionId,
      );
      return;
    }

    if (await _isGuest()) {
      final items = await _loadGuest();
      final next = <CartItemModel>[];
      for (final i in items) {
        final match = i.product.id == productId &&
            i.variationOptionId == variationOptionId;
        if (!match) {
          next.add(i);
          continue;
        }
        if (quantity > 0) {
          next.add(
            CartItemModel(
              id: i.id,
              quantity: quantity,
              product: i.product,
              variationOptionId: i.variationOptionId,
              shopId: i.shopId,
            ),
          );
        }
      }
      await _saveGuest(next);
      return;
    }

    final res = await _api.put(
      ApiEndpoints.cartUpdate(productId),
      body: {
        'quantity': quantity,
        if (variationOptionId != null) 'variation_option_id': variationOptionId,
      },
    );
    res.ensureSuccess('Could not update cart');
  }

  Future<void> remove(int productId, {int? variationOptionId}) async {
    if (AppConfig.useMockData) {
      MockData.cartRemove(productId, variationOptionId: variationOptionId);
      return;
    }

    if (await _isGuest()) {
      final items = await _loadGuest();
      items.removeWhere(
        (i) =>
            i.product.id == productId &&
            i.variationOptionId == variationOptionId,
      );
      await _saveGuest(items);
      return;
    }

    final res = await _api.delete(
      ApiEndpoints.cartRemove(productId),
      body: {
        if (variationOptionId != null) 'variation_option_id': variationOptionId,
      },
    );
    res.ensureSuccess('Could not remove item');
  }

  Future<void> clear() async {
    if (AppConfig.useMockData) {
      for (final item in List<CartItemModel>.from(MockData.cartItems)) {
        MockData.cartRemove(item.product.id);
      }
      return;
    }
    if (await _isGuest()) {
      await _saveGuest([]);
      return;
    }
    final res = await _api.delete(ApiEndpoints.cartDeleteAll);
    res.ensureSuccess('Could not clear cart');
  }
}
