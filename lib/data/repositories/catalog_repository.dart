import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/api_endpoints.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../mock/mock_data.dart';
import '../models/models.dart';

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
  return CartRepository(ref.watch(apiClientProvider));
});

class CartRepository {
  CartRepository(this._api);

  final ApiClient _api;

  Future<List<CartItemModel>> list() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      return MockData.cartItems;
    }

    final res = await _api.get<List<CartItemModel>>(
      ApiEndpoints.cartList,
      mapData: (raw) {
        if (raw is! List) return <CartItemModel>[];
        return raw
            .whereType<Map>()
            .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return res.data ?? [];
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

    await _api.post(
      ApiEndpoints.cartCreate,
      body: {
        'product_id': productId,
        'shop_id': shopId,
        'quantity': quantity,
        if (variationOptionId != null) 'variation_option_id': variationOptionId,
      },
    );
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

    await _api.put(
      ApiEndpoints.cartUpdate(productId),
      body: {'quantity': quantity},
      query: {
        if (variationOptionId != null) 'variation_option_id': variationOptionId,
      },
    );
  }

  Future<void> remove(int productId, {int? variationOptionId}) async {
    if (AppConfig.useMockData) {
      MockData.cartRemove(productId, variationOptionId: variationOptionId);
      return;
    }

    await _api.delete(
      ApiEndpoints.cartDelete(productId),
      body: {
        if (variationOptionId != null) 'variation_option_id': variationOptionId,
      },
    );
  }
}
