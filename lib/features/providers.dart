import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../core/config/app_config.dart';
import '../data/models/models.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/settings_repository.dart';

export '../data/repositories/account_repository.dart'
    show accountRepositoryProvider, AccountRepository;
export '../data/repositories/order_repository.dart'
    show orderRepositoryProvider, OrderRepository;
export '../data/repositories/settings_repository.dart'
    show settingsRepositoryProvider, SettingsRepository;

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
    try {
      final user = await _repo.login(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

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

final settingsProvider = FutureProvider<SiteSettingsModel>((ref) async {
  return ref.watch(settingsRepositoryProvider).fetch();
});

/// Live shipping class amount from `/shipping/read/{id}` (same as website).
final shippingClassProvider =
    FutureProvider<ShippingClassModel?>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return ref
      .watch(settingsRepositoryProvider)
      .fetchShippingClass(settings.shippingClassId);
});

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listCategories(vertical: vertical);
});

/// Website `useGetBrowseTilesQuery` — home Shop-by-category tiles with images.
final browseTilesProvider =
    FutureProvider.autoDispose<List<BrowseCategoryTile>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listBrowseTiles(vertical: vertical);
});

/// Website-style search placeholder total (`Search N items`).
final catalogProductCountProvider =
    FutureProvider.autoDispose<int>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).countProducts(vertical: vertical);
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
      ).catchError((_) => <ProductModel>[]);
});

final bestSellersProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final vertical = ref.watch(verticalProvider);
  final repo = ref.watch(catalogRepositoryProvider);
  try {
    final best = await repo.listProducts(
      vertical: vertical,
      endpoint: ApiEndpoints.productBestSellers,
      limit: 12,
    );
    if (best.isNotEmpty) return best;
    // Production often has no sales-order history yet — fall back to catalogue.
    return repo.listProducts(vertical: vertical, limit: 12);
  } catch (_) {
    try {
      return await repo.listProducts(vertical: vertical, limit: 12);
    } catch (_) {
      return <ProductModel>[];
    }
  }
});

final limitedStockProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listProducts(
        vertical: vertical,
        endpoint: ApiEndpoints.productLimited,
        limit: 12,
      ).catchError((_) => <ProductModel>[]);
});

final trendingProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listProducts(
        vertical: vertical,
        endpoint: ApiEndpoints.productTrending,
        limit: 12,
      ).catchError((_) => <ProductModel>[]);
});

final newArrivalsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref.watch(catalogRepositoryProvider).listProducts(
        vertical: vertical,
        endpoint: ApiEndpoints.productNewArrivals,
        limit: 12,
      ).catchError((_) => <ProductModel>[]);
});

final bannersProvider =
    FutureProvider.autoDispose<List<BannerModel>>((ref) {
  final vertical = ref.watch(verticalProvider);
  return ref
      .watch(catalogRepositoryProvider)
      .listBanners(vertical: vertical)
      .catchError((_) => <BannerModel>[]);
});

final recentOrdersHomeProvider =
    FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  try {
    final all = await ref.watch(orderRepositoryProvider).listAllMine();
    return all.take(3).toList();
  } catch (_) {
    return [];
  }
});

/// Applied cart/checkout coupon (website CartPage parity).
final appliedCouponProvider = StateProvider<CouponModel?>((_) => null);

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

  /// Instant UI clear (badge → 0) after a successful place-order.
  void clearLocal() {
    state = const AsyncValue.data([]);
  }

  Future<void> clear() async {
    await _repo.clear();
    clearLocal();
  }

  Future<void> add(
    ProductModel product, {
    int qty = 1,
    int? variationOptionId,
  }) async {
    final shopId = product.shopId ?? 0;
    await _repo.add(
      productId: product.id,
      shopId: shopId,
      quantity: qty,
      variationOptionId: variationOptionId,
      product: product,
    );
    await refresh();
  }

  /// Website EditOrderDialog: clear cart then bulk-create session items.
  Future<void> bulkReplaceFromEdit(
    List<Map<String, dynamic>> items,
  ) async {
    await _repo.clear();
    await _repo.bulkCreate(items);
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

final ordersProvider =
    FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(orderRepositoryProvider).listAllMine();
});

final returnsProvider =
    FutureProvider.autoDispose<List<ReturnRequestModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(orderRepositoryProvider).listMyReturns();
});

final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderModel, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).read(id);
});

final addressesProvider =
    FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  // Guests have no saved addresses — avoid "Not authenticated" under checkout.
  if (user == null) return <AddressModel>[];
  return ref.watch(accountRepositoryProvider).listAddresses();
});

final walletProvider = FutureProvider.autoDispose<WalletModel>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return const WalletModel(balance: 0);
  }
  return ref.watch(accountRepositoryProvider).walletBalance();
});

final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransactionModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(accountRepositoryProvider).walletTransactions();
});

final wishlistProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(accountRepositoryProvider).wishlist();
});

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotificationModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(accountRepositoryProvider).notifications();
});

/// Holds checkout draft (address + notes + slot) between Checkout → Payment.
final checkoutDraftProvider = StateProvider<CheckoutDraft?>((_) => null);

class CheckoutDraft {
  const CheckoutDraft({
    required this.shippingAddress,
    this.deliveryTime,
    this.orderNotes,
    this.addressTitle,
    this.addressId,
  });

  final Map<String, dynamic> shippingAddress;
  final String? deliveryTime;
  final String? orderNotes;
  final String? addressTitle;
  final int? addressId;
}

/// Selected address id on checkout (before draft is finalized).
final selectedCheckoutAddressIdProvider = StateProvider<int?>((_) => null);
