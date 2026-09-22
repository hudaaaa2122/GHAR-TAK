import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/api_endpoints.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(apiClientProvider));
});

class SettingsRepository {
  SettingsRepository(this._api);

  final ApiClient _api;

  Future<SiteSettingsModel> fetch({String language = 'en'}) async {
    if (AppConfig.useMockData) {
      return const SiteSettingsModel(
        freeShipping: true,
        freeShippingAmount: AppConfig.defaultFreeShippingAmount,
        minimumOrderAmount: 500,
        maximumShippingAmountOff: 500,
        shippingClassId: 1,
        taxClassId: 1,
      );
    }

    final res = await _api.get<SiteSettingsModel>(
      ApiEndpoints.settings,
      query: {'language': language},
      mapData: (raw) {
        final map =
            raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        var options = map['options'];
        if (options is String && options.isNotEmpty) {
          try {
            final decoded = jsonDecode(options);
            if (decoded is Map) {
              options = decoded;
            }
          } catch (_) {}
        }
        return SiteSettingsModel.fromOptions(
          options is Map
              ? Map<String, dynamic>.from(options)
              : map,
        );
      },
    );
    res.ensureSuccess('Could not load settings');
    return res.data ??
        const SiteSettingsModel(
          freeShippingAmount: AppConfig.defaultFreeShippingAmount,
        );
  }

  /// Website: `GET /shipping/read/{shippingClassId}` from settings.
  Future<ShippingClassModel?> fetchShippingClass(int? id) async {
    if (id == null || id <= 0) return null;
    if (AppConfig.useMockData) {
      return const ShippingClassModel(
        id: 1,
        name: 'Shipping Charges',
        amount: 500,
        type: 'fixed',
      );
    }
    try {
      final res = await _api.get<ShippingClassModel>(
        ApiEndpoints.shippingRead(id),
        mapData: (raw) {
          if (raw is Map) {
            return ShippingClassModel.fromJson(
              Map<String, dynamic>.from(raw),
            );
          }
          return const ShippingClassModel(id: 0);
        },
      );
      if (!res.success) return null;
      final data = res.data;
      if (data == null || data.id <= 0) return null;
      return data;
    } catch (_) {
      return null;
    }
  }
}
