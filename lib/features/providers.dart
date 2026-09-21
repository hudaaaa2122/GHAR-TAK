import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../core/config/app_config.dart';
import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/catalog_repository.dart';

final authStateProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  AuthController(this._repo) : super(const AsyncValue.loading()) {
    restore();
  }

  final AuthRepository _repo;

  Future<void> restore() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.restoreSession);
  }

  Future<void> login(String email, String password) async {
    // Keep previous user visible — avoid full-tree loading rebuild on sign-in.
    try {
      final user = await _repo.login(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Mock Google Sign-In — same session path as email login until backend is wired.
  Future<void> loginWithGoogle() async {
    try {
      final user = await _repo.loginWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  void setUser(UserModel user) {
    state = AsyncValue.data(user);
  }
}

final verticalProvider = StateProvider<String>((_) => AppConfig.defaultVertical);

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listCategories(vertical: vertical);
});

final manufacturersProvider =
    FutureProvider.autoDispose<List<ManufacturerModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref
      .watch(catalogRepositoryProvider)
      .listManufacturers(vertical: vertical);
});

final offersProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listProducts(
        vertical: vertical,
        endpoint: ApiEndpoints.productSales,
        limit: 12,
      );
});

final bestSellersProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listProducts(
        vertical: vertical,
        endpoint: ApiEndpoints.productBestSellers,
        limit: 12,
      );
});

final limitedStockProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listProducts(
        vertical: vertical,
        endpoint: ApiEndpoints.productLimited,
        limit: 12,
      );
});

final cartProvider =
    StateNotifierProvider<CartController, AsyncValue<List<CartItemModel>>>((ref) {
  return CartController(ref.watch(cartRepositoryProvider));
});

class CartController extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  CartController(this._repo) : super(const AsyncValue.data([]));

  final CartRepository _repo;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.list);
  }

  Future<void> add(ProductModel product, {int qty = 1}) async {
    final shopId = product.shopId ?? 0;
    await _repo.add(
      productId: product.id,
      shopId: shopId,
      quantity: qty,
      product: product,
    );
    await refresh();
  }

  Future<void> setQty(CartItemModel item, int qty) async {
    if (qty <= 0) {
      await _repo.remove(item.product.id, variationOptionId: item.variationOptionId);
    } else {
      await _repo.updateQuantity(
        item.product.id,
        qty,
        variationOptionId: item.variationOptionId,
      );
    }
    await refresh();
  }

  int get count {
    final items = state.valueOrNull ?? [];
    return items.fold<int>(0, (s, e) => s + e.quantity);
  }
}

final productDetailProvider =
    FutureProvider.autoDispose.family<ProductModel, String>((ref, id) {
  return ref.watch(catalogRepositoryProvider).getProduct(id);
});

final productSearchProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>((ref, q) {
  final vertical = ref.watch(verticalProvider);
  if (q.trim().isEmpty) return Future.value([]);
  return ref.watch(catalogRepositoryProvider).listProducts(
        vertical: vertical,
        search: q.trim(),
        limit: 40,
      );
});
