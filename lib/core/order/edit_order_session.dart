import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/models.dart';

const _editOrderSessionKey = 'ghertak_edit_order_session';
const _allowSubstitutionKey = 'ghertak_allow_grocery_substitutions';

class EditOrderDraftItem {
  const EditOrderDraftItem({
    required this.key,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.name,
    this.orderProductId,
    this.variationOptionId,
    this.regularPrice,
    this.image = '',
    this.shopId,
    this.maxQuantity = 99,
  });

  final String key;
  final int? orderProductId;
  final int productId;
  final int? variationOptionId;
  final int quantity;
  final double unitPrice;
  final double? regularPrice;
  final String name;
  final String image;
  final int? shopId;
  final int maxQuantity;

  EditOrderDraftItem copyWith({int? quantity}) => EditOrderDraftItem(
        key: key,
        orderProductId: orderProductId,
        productId: productId,
        variationOptionId: variationOptionId,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        regularPrice: regularPrice,
        name: name,
        image: image,
        shopId: shopId,
        maxQuantity: maxQuantity,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'orderProductId': orderProductId,
        'productId': productId,
        'variationOptionId': variationOptionId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'regularPrice': regularPrice,
        'name': name,
        'image': image,
        'shopId': shopId,
        'maxQuantity': maxQuantity,
      };

  factory EditOrderDraftItem.fromJson(Map<String, dynamic> json) {
    return EditOrderDraftItem(
      key: json['key']?.toString() ??
          itemKey(
            (json['productId'] as num?)?.toInt() ?? 0,
            (json['variationOptionId'] as num?)?.toInt(),
          ),
      orderProductId: (json['orderProductId'] as num?)?.toInt(),
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      variationOptionId: (json['variationOptionId'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      regularPrice: (json['regularPrice'] as num?)?.toDouble(),
      name: json['name']?.toString() ?? 'Item',
      image: json['image']?.toString() ?? '',
      shopId: (json['shopId'] as num?)?.toInt(),
      maxQuantity: (json['maxQuantity'] as num?)?.toInt() ?? 99,
    );
  }
}

class EditOrderOriginalItem {
  const EditOrderOriginalItem({
    required this.productId,
    required this.quantity,
    this.variationOptionId,
  });

  final int productId;
  final int? variationOptionId;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variationOptionId': variationOptionId,
        'quantity': quantity,
      };

  factory EditOrderOriginalItem.fromJson(Map<String, dynamic> json) {
    return EditOrderOriginalItem(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      variationOptionId: (json['variationOptionId'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class EditOrderSession {
  const EditOrderSession({
    required this.orderId,
    required this.trackingNumber,
    required this.originalTotal,
    required this.items,
    required this.originalItems,
    required this.orderProductMap,
    this.deliveryTime,
    this.orderNotes,
    this.detailsOnly = false,
    this.shippingAddress,
    this.paymentStatus,
    this.paymentGateway,
  });

  final int orderId;
  final String trackingNumber;
  final String? deliveryTime;
  final String? orderNotes;
  final double originalTotal;
  final bool detailsOnly;
  final Map<String, dynamic>? shippingAddress;
  final String? paymentStatus;
  final String? paymentGateway;
  final Map<String, int> orderProductMap;
  final List<EditOrderDraftItem> items;
  final List<EditOrderOriginalItem> originalItems;

  EditOrderSession copyWith({
    List<EditOrderDraftItem>? items,
    bool? detailsOnly,
    Map<String, int>? orderProductMap,
    String? deliveryTime,
    String? orderNotes,
    Map<String, dynamic>? shippingAddress,
  }) {
    return EditOrderSession(
      orderId: orderId,
      trackingNumber: trackingNumber,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      orderNotes: orderNotes ?? this.orderNotes,
      originalTotal: originalTotal,
      detailsOnly: detailsOnly ?? this.detailsOnly,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentStatus: paymentStatus,
      paymentGateway: paymentGateway,
      orderProductMap: orderProductMap ?? this.orderProductMap,
      items: items ?? this.items,
      originalItems: originalItems,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'trackingNumber': trackingNumber,
        'deliveryTime': deliveryTime,
        'orderNotes': orderNotes,
        'originalTotal': originalTotal,
        'detailsOnly': detailsOnly,
        'shippingAddress': shippingAddress,
        'paymentStatus': paymentStatus,
        'paymentGateway': paymentGateway,
        'orderProductMap': orderProductMap,
        'items': items.map((e) => e.toJson()).toList(),
        'originalItems': originalItems.map((e) => e.toJson()).toList(),
      };

  factory EditOrderSession.fromJson(Map<String, dynamic> json) {
    final mapRaw = json['orderProductMap'];
    final orderProductMap = <String, int>{};
    if (mapRaw is Map) {
      for (final e in mapRaw.entries) {
        final v = e.value;
        if (v is num) orderProductMap['${e.key}'] = v.toInt();
      }
    }
    return EditOrderSession(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      trackingNumber: json['trackingNumber']?.toString() ?? '',
      deliveryTime: json['deliveryTime']?.toString(),
      orderNotes: json['orderNotes']?.toString(),
      originalTotal: (json['originalTotal'] as num?)?.toDouble() ?? 0,
      detailsOnly: json['detailsOnly'] == true,
      shippingAddress: json['shippingAddress'] is Map
          ? Map<String, dynamic>.from(json['shippingAddress'] as Map)
          : null,
      paymentStatus: json['paymentStatus']?.toString(),
      paymentGateway: json['paymentGateway']?.toString(),
      orderProductMap: orderProductMap,
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => EditOrderDraftItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      originalItems: (json['originalItems'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) =>
                EditOrderOriginalItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

String itemKey(int productId, int? variationOptionId) =>
    '$productId:${variationOptionId ?? 'base'}';

String _fingerprintDraft(List<EditOrderDraftItem> items) {
  final sorted = [...items]..sort((a, b) => a.key.compareTo(b.key));
  return sorted.map((e) => '${e.key}:${e.quantity}').join('|');
}

String _fingerprintOriginal(List<EditOrderOriginalItem> items) {
  final sorted = [...items]
    ..sort(
      (a, b) => itemKey(a.productId, a.variationOptionId)
          .compareTo(itemKey(b.productId, b.variationOptionId)),
    );
  return sorted
      .map((e) => '${itemKey(e.productId, e.variationOptionId)}:${e.quantity}')
      .join('|');
}

bool hasEditItemsChanged(EditOrderSession? session) {
  if (session == null) return false;
  return _fingerprintDraft(session.items) !=
      _fingerprintOriginal(session.originalItems);
}

EditOrderSession createSessionFromOrder(OrderModel order) {
  final orderId = int.tryParse(order.id) ?? 0;
  final draft = <EditOrderDraftItem>[];
  final original = <EditOrderOriginalItem>[];
  final map = <String, int>{};

  for (final item in order.items) {
    final pid = item.productId;
    if (pid == null) continue;
    final key = itemKey(pid, item.variationOptionId);
    final d = EditOrderDraftItem(
      key: key,
      orderProductId: item.id,
      productId: pid,
      variationOptionId: item.variationOptionId,
      quantity: item.quantity,
      unitPrice: item.price,
      regularPrice: item.regularPrice,
      name: item.name,
      image: item.image?.best ?? '',
      shopId: item.shopId,
      maxQuantity: 99,
    );
    draft.add(d);
    original.add(
      EditOrderOriginalItem(
        productId: pid,
        variationOptionId: item.variationOptionId,
        quantity: item.quantity,
      ),
    );
    if (item.id != null) map[key] = item.id!;
  }

  return EditOrderSession(
    orderId: orderId,
    trackingNumber: order.trackingNumber ?? order.displayId,
    deliveryTime: order.deliveryTime,
    orderNotes: order.orderNotes,
    originalTotal: order.total ?? 0,
    shippingAddress: order.shippingAddress,
    paymentStatus: order.paymentStatus,
    paymentGateway: order.paymentGateway,
    orderProductMap: map,
    items: draft,
    originalItems: original,
  );
}

Future<EditOrderSession?> readEditOrderSession() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_editOrderSessionKey);
  if (raw == null || raw.isEmpty) return null;
  try {
    return EditOrderSession.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  } catch (_) {
    return null;
  }
}

Future<void> writeEditOrderSession(EditOrderSession? session) async {
  final prefs = await SharedPreferences.getInstance();
  if (session == null) {
    await prefs.remove(_editOrderSessionKey);
  } else {
    await prefs.setString(_editOrderSessionKey, jsonEncode(session.toJson()));
  }
}

Future<void> clearEditOrderSession() => writeEditOrderSession(null);

Future<void> setAllowSubstitution(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_allowSubstitutionKey, value);
}

Future<bool> getAllowSubstitution() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_allowSubstitutionKey) ?? true;
}

class EditOrderSessionNotifier extends StateNotifier<EditOrderSession?> {
  EditOrderSessionNotifier() : super(null) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    state = await readEditOrderSession();
  }

  Future<void> setSession(EditOrderSession? session) async {
    state = session;
    await writeEditOrderSession(session);
  }

  Future<void> clear() async {
    state = null;
    await clearEditOrderSession();
  }
}

final editOrderSessionProvider =
    StateNotifierProvider<EditOrderSessionNotifier, EditOrderSession?>((ref) {
  return EditOrderSessionNotifier();
});
