import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/api_endpoints.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/storage/token_storage.dart';
import '../mock/mock_data.dart';
import '../models/models.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AccountRepository {
  AccountRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  // —— Profile ——

  Future<UserModel> updateProfile({
    String? name,
    String? phoneNo,
    dynamic image,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final cached = await _storage.userJson;
      final base = cached != null
          ? UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>)
          : const UserModel(id: 1, name: 'Customer');
      String? avatar = base.avatar;
      if (image is Map) {
        avatar = MediaImage.fromJson(image).best ?? avatar;
      } else if (image is String) {
        avatar = image;
      }
      final updated = UserModel(
        id: base.id,
        name: name ?? base.name,
        email: base.email,
        phoneNo: phoneNo ?? base.phoneNo,
        avatar: avatar,
      );
      await _storage.saveUserJson(jsonEncode(updated.toJson()));
      return updated;
    }

    final res = await _api.put<Map<String, dynamic>>(
      ApiEndpoints.userProfile,
      body: {
        if (name != null) 'name': name,
        if (phoneNo != null) 'phone_no': phoneNo,
        if (image != null) 'image': image,
      },
      mapData: (raw) =>
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
    );
    res.ensureSuccess('Could not update profile');
    final user = UserModel.fromJson(res.data ?? {});
    await _storage.saveUserJson(jsonEncode(user.toJson()));
    return user;
  }

  /// Upload profile/product image → `POST /media/create` (same as website).
  Future<Map<String, dynamic>> uploadMedia(String filePath) async {
    if (AppConfig.useMockData) {
      return {
        'original': filePath,
        'thumbnail': filePath,
      };
    }
    final form = FormData.fromMap({
      'files': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split(RegExp(r'[\\/]')).last,
      ),
    });
    final res = await _api.postMultipart<List<dynamic>>(
      ApiEndpoints.mediaCreate,
      formData: form,
      query: {'thumbnail': true},
      mapData: (raw) {
        if (raw is List) return raw;
        return <dynamic>[];
      },
    );
    res.ensureSuccess('Could not upload image');
    final list = res.data ?? [];
    if (list.isEmpty) throw ApiException('Upload returned no media');
    final first = list.first;
    if (first is Map) return Map<String, dynamic>.from(first);
    throw ApiException('Invalid media response');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (newPassword != confirmPassword) {
        throw ApiException('Passwords do not match');
      }
      if (newPassword.length < 8) {
        throw ApiException('Password must be at least 8 characters');
      }
      return;
    }

    final res = await _api.post(
      ApiEndpoints.changePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
    res.ensureSuccess('Could not change password');
  }

  Future<void> forgotPassword(String email) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }
    final res = await _api.post(
      ApiEndpoints.forgotPassword,
      body: {'email': email},
    );
    res.ensureSuccess('Could not send reset code');
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (code.trim() != '123456') {
        throw ApiException('Invalid code. Use 123456 in mock mode.');
      }
      return;
    }
    final res = await _api.post(
      ApiEndpoints.resetPassword,
      body: {
        'email': email,
        'verification_code': code,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
    res.ensureSuccess('Could not reset password');
  }

  // —— Addresses ——

  Future<List<AddressModel>> listAddresses() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return const [
        AddressModel(
          id: 1,
          title: 'Home',
          type: 'home',
          street: '23-B, Model Town Extension, Block B',
          city: 'Lahore',
          state: 'Punjab',
          postalCode: '54700',
          country: 'Pakistan',
          isDefault: true,
          lat: 31.4697,
          lng: 74.2728,
        ),
      ];
    }

    final res = await _api.get<List<AddressModel>>(
      ApiEndpoints.addressList,
      mapData: (raw) {
        final list = raw is List
            ? raw
            : (raw is Map ? (raw['items'] as List? ?? raw['data']) : null);
        if (list is! List) return <AddressModel>[];
        return list
            .whereType<Map>()
            .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    res.ensureSuccess('Could not load addresses');
    return res.data ?? [];
  }

  Future<AddressModel> createAddress({
    required String title,
    required String type,
    required String street,
    required String city,
    String? state,
    String? postalCode,
    String country = 'Pakistan',
    required double lat,
    required double lng,
    bool isDefault = false,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return AddressModel(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        type: type,
        street: street,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault,
        lat: lat,
        lng: lng,
      );
    }

    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.addressCreate,
      body: {
        'title': title,
        'type': type,
        'address': {
          'street': street,
          'city': city,
          if (state != null) 'state': state,
          if (postalCode != null) 'postal_code': postalCode,
          'country': country,
        },
        'location': {'lat': lat, 'lng': lng},
        'is_default': isDefault,
      },
      mapData: (raw) =>
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
    );
    res.ensureSuccess('Could not save address');
    return AddressModel.fromJson(res.data ?? {});
  }

  Future<void> deleteAddress(int id) async {
    if (AppConfig.useMockData) return;
    final res = await _api.delete(ApiEndpoints.addressDelete(id));
    res.ensureSuccess('Could not delete address');
  }

  // —— Wallet ——

  Future<WalletModel> walletBalance() async {
    if (AppConfig.useMockData) {
      return const WalletModel(balance: 2500, totalCredited: 5000, totalDebited: 2500);
    }
    final res = await _api.get<WalletModel>(
      ApiEndpoints.walletBalance,
      mapData: (raw) => WalletModel.fromJson(
        raw is Map ? Map<String, dynamic>.from(raw) : {},
      ),
    );
    res.ensureSuccess('Could not load wallet');
    return res.data ?? const WalletModel();
  }

  Future<List<WalletTransactionModel>> walletTransactions() async {
    if (AppConfig.useMockData) {
      return MockData.walletTx
          .map(
            (e) => WalletTransactionModel(
              id: e['id'] as int,
              amount: (e['amount'] as num).abs().toDouble(),
              transactionType: e['type']?.toString() ?? 'credit',
              description: e['title']?.toString(),
              createdAt: DateTime.now().toIso8601String(),
            ),
          )
          .toList();
    }

    final res = await _api.get<List<WalletTransactionModel>>(
      ApiEndpoints.walletTransactions,
      mapData: (raw) {
        final list = raw is List
            ? raw
            : (raw is Map
                ? (raw['items'] as List? ??
                    raw['data'] as List? ??
                    raw['records'] as List?)
                : null);
        if (list is! List) return <WalletTransactionModel>[];
        return list
            .whereType<Map>()
            .map(
              (e) => WalletTransactionModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      },
    );
    res.ensureSuccess('Could not load transactions');
    return res.data ?? [];
  }

  /// True when [lat]/[lng] falls inside an active delivery zone.
  Future<bool> isDeliverable({required double lat, required double lng}) async {
    if (AppConfig.useMockData) return true;
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.deliveryZoneCheck,
        body: {'lat': lat, 'lng': lng},
        mapData: (raw) =>
            raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
      );
      if (!res.success) return false;
      return res.data?['deliverable'] == true;
    } catch (_) {
      return false;
    }
  }

  // —— Wishlist ——

  Future<List<ProductModel>> wishlist() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return MockData.products.take(4).toList();
    }
    final res = await _api.get<List<ProductModel>>(
      ApiEndpoints.wishlistMine,
      mapData: (raw) {
        if (raw is! List) return <ProductModel>[];
        return raw
            .whereType<Map>()
            .map((e) {
              final map = Map<String, dynamic>.from(e);
              final product = map['product'];
              if (product is Map) {
                return ProductModel.fromJson(Map<String, dynamic>.from(product));
              }
              return ProductModel.fromJson(map);
            })
            .toList();
      },
    );
    res.ensureSuccess('Could not load wishlist');
    return res.data ?? [];
  }

  Future<void> addToWishlist(int productId) async {
    if (AppConfig.useMockData) return;
    final res = await _api.post(
      ApiEndpoints.wishlistAdd,
      body: {'product_id': productId},
    );
    res.ensureSuccess('Could not add to wishlist');
  }

  Future<void> removeFromWishlist(int productId) async {
    if (AppConfig.useMockData) return;
    final res = await _api.delete(ApiEndpoints.wishlistRemove(productId));
    res.ensureSuccess('Could not remove from wishlist');
  }

  // —— Notifications ——

  Future<List<AppNotificationModel>> notifications() async {
    if (AppConfig.useMockData) {
      return const [
        AppNotificationModel(
          id: 1,
          title: 'Order on the way',
          body: 'Your order is out for delivery.',
          isRead: false,
        ),
        AppNotificationModel(
          id: 2,
          title: 'Welcome to Gher Tak',
          body: 'Thanks for joining us.',
          isRead: true,
        ),
      ];
    }
    final res = await _api.get<List<AppNotificationModel>>(
      ApiEndpoints.notificationList,
      mapData: (raw) {
        final list = raw is List
            ? raw
            : (raw is Map ? raw['items'] as List? : null);
        if (list is! List) return <AppNotificationModel>[];
        return list
            .whereType<Map>()
            .map(
              (e) =>
                  AppNotificationModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
    res.ensureSuccess('Could not load notifications');
    return res.data ?? [];
  }
}
