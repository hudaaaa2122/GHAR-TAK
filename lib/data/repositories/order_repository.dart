import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/api_endpoints.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../mock/mock_data.dart';
import '../models/models.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  Future<OrderModel> createFromCart({
    required Map<String, dynamic> shippingAddress,
    Map<String, dynamic>? billingAddress,
    String paymentGateway = 'cash_on_delivery',
    String? deliveryTime,
    String? orderNotes,
    bool useWallet = false,
    double? walletAmount,
    bool allowSubstitution = true,
    int? shippingId,
    int? taxId,
    int? couponId,
    List<Map<String, dynamic>>? paymentProof,
    Map<String, dynamic>? paymentResponse,
    String? customerContact,
    String? paymentId,
    String? paymentStatus,
    /// Website `order/cartcreate` cart lines — required for guest checkout.
    List<Map<String, dynamic>>? cart,
    int? customerId,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return OrderModel(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        trackingNumber: 'GT-${DateTime.now().millisecondsSinceEpoch % 100000}',
        status: 'pending',
        total: MockData.cartItems.fold<double>(
          0,
          (s, e) => s + e.product.displayPrice * e.quantity,
        ),
        createdAt: DateTime.now().toIso8601String(),
        itemsCount: MockData.cartItems.length,
      );
    }

    // Mirror website CheckoutPaymentPage → POST order/cartcreate with cart body
    // so guests can place orders without a server-side cart / auth.
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.orderCartCreate,
      body: {
        'shipping_address': shippingAddress,
        if (billingAddress != null) 'billing_address': billingAddress,
        'payment_gateway': paymentGateway,
        if (shippingId != null) 'shipping_id': shippingId,
        if (taxId != null) 'tax_id': taxId,
        if (couponId != null) 'coupon_id': couponId,
        if (deliveryTime != null) 'delivery_time': deliveryTime,
        if (orderNotes != null && orderNotes.isNotEmpty)
          'order_notes': orderNotes,
        'use_wallet': useWallet,
        if (walletAmount != null) 'wallet_amount': walletAmount,
        'allow_substitution': allowSubstitution,
        if (customerContact != null && customerContact.isNotEmpty)
          'customer_contact': customerContact,
        if (paymentProof != null && paymentProof.isNotEmpty)
          'payment_proof': paymentProof,
        if (paymentResponse != null) 'payment_response': paymentResponse,
        if (paymentId != null) 'payment_id': paymentId,
        'payment_status': paymentStatus ??
            (paymentId != null ? 'success' : 'cash-on-delivery'),
        if (cart != null) 'cart': cart,
        'customer_id': customerId,
      },
      // Backend sends email/notifications before responding — can exceed 25s.
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 30),
      mapData: (raw) =>
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
    );
    res.ensureSuccess('Could not place order');
    final data = res.data ?? res.raw ?? {};
    // cartcreate returns flat { order_id, tracking_number, ... }
    // (not nested under `order`).
    final orderRaw = data['order'] is Map ? data['order'] : data;
    final map = Map<String, dynamic>.from(orderRaw as Map);
    if (map['id'] == null && map['order_id'] != null) {
      map['id'] = map['order_id'];
    }
    return OrderModel.fromJson(map);
  }

  Future<CouponModel?> redeemCoupon(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    if (AppConfig.useMockData) {
      return CouponModel(
        id: 1,
        code: trimmed,
        type: 'fixed',
        amount: 100,
        minimumCartAmount: 0,
      );
    }
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.couponRedeem(trimmed),
      mapData: (raw) =>
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
    );
    res.ensureSuccess('Invalid coupon code');
    final data = res.data ?? {};
    if (data.isEmpty) return null;
    return CouponModel.fromJson(data);
  }

  Future<List<OrderModel>> listMine({bool completed = false}) async {
    // Prefer customer endpoint; keep param for callers that filter locally.
    final all = await listAllMine();
    if (!completed) {
      return all
          .where((o) {
            final s = (o.status ?? '').toLowerCase();
            return !s.contains('completed') &&
                !s.contains('delivered') &&
                !s.contains('cancelled') &&
                !s.contains('canceled');
          })
          .toList();
    }
    return all
        .where((o) {
          final s = (o.status ?? '').toLowerCase();
          return s.contains('completed') || s.contains('delivered');
        })
        .toList();
  }

  Future<List<OrderModel>> listAllMine() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return _mockOrders;
    }

    // Website uses /order/list (auto-filters by customer_id). Prefer /order/my-orders.
    try {
      final res = await _api.get<List<OrderModel>>(
        ApiEndpoints.orderMyOrders,
        query: {'limit': 100, 'page': 1},
        mapData: _mapOrderList,
      );
      if (res.success) return res.data ?? [];
    } catch (_) {}

    final res = await _api.get<List<OrderModel>>(
      ApiEndpoints.orderList,
      query: {'limit': 100, 'page': 1},
      mapData: _mapOrderList,
    );
    res.ensureSuccess('Could not load orders');
    return res.data ?? [];
  }

  Future<OrderModel> read(String idOrTracking) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _mockOrders.firstWhere(
        (o) => o.id == idOrTracking || o.trackingNumber == idOrTracking,
        orElse: () => _mockOrders.first,
      );
    }

    // Prefer numeric id → /order/read/{id}, else tracking.
    final isNumeric = int.tryParse(idOrTracking) != null;
    final path = isNumeric
        ? ApiEndpoints.orderRead(idOrTracking)
        : ApiEndpoints.orderTracking(idOrTracking);

    try {
      final res = await _api.get<OrderModel>(
        path,
        mapData: (raw) {
          if (raw is Map) {
            return OrderModel.fromJson(Map<String, dynamic>.from(raw));
          }
          throw ApiException('Invalid order');
        },
      );
      res.ensureSuccess('Order not found');
      if (res.data == null) throw ApiException('Order not found');
      return res.data!;
    } on ApiException {
      // Fallback: try the other endpoint.
      final alt = isNumeric
          ? ApiEndpoints.orderTracking(idOrTracking)
          : ApiEndpoints.orderRead(idOrTracking);
      final res = await _api.get<OrderModel>(
        alt,
        mapData: (raw) {
          if (raw is Map) {
            return OrderModel.fromJson(Map<String, dynamic>.from(raw));
          }
          throw ApiException('Invalid order');
        },
      );
      res.ensureSuccess('Order not found');
      if (res.data == null) throw ApiException('Order not found');
      return res.data!;
    }
  }

  Future<void> cancel(
    String orderId, {
    String? reason,
    bool notifyCustomer = true,
  }) async {
    if (AppConfig.useMockData) return;
    final res = await _api.post(
      ApiEndpoints.orderCancel(orderId),
      body: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        'notify_customer': notifyCustomer,
      },
    );
    res.ensureSuccess('Could not cancel order');
  }

  /// Website `POST /returns/request` — full_order or single_product + photos.
  Future<void> requestReturn({
    required int orderId,
    required String reason,
    String returnType = 'full_order',
    List<Map<String, dynamic>> photos = const [],
    List<Map<String, dynamic>> items = const [],
  }) async {
    if (AppConfig.useMockData) return;
    final body = <String, dynamic>{
      'order_id': orderId,
      'return_type': returnType,
      'reason': reason.isEmpty ? 'Customer requested return' : reason,
      'photos': photos,
    };
    if (returnType == 'single_product' && items.isNotEmpty) {
      body['items'] = items;
    }
    final res = await _api.post(
      ApiEndpoints.returnsRequest,
      body: body,
    );
    res.ensureSuccess('Could not submit return request');
  }

  Future<Map<String, dynamic>?> getOrderReview(String orderId) async {
    if (AppConfig.useMockData) return null;
    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.orderReviewByOrder(orderId),
        mapData: (raw) {
          if (raw is Map) return Map<String, dynamic>.from(raw);
          return <String, dynamic>{};
        },
      );
      if (!res.success) return null;
      final data = res.data;
      if (data == null || data.isEmpty) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> createOrderReview({
    required int orderId,
    required int rating,
    int? deliveryRating,
    int? packagingRating,
    int? productQualityRating,
    int? fulfillmentRating,
    String? comment,
    String? fulfillmentComment,
    List<Map<String, dynamic>> photos = const [],
  }) async {
    if (AppConfig.useMockData) return;
    final res = await _api.post(
      ApiEndpoints.orderReviewCreate,
      body: {
        'order_id': orderId,
        'rating': rating,
        if (deliveryRating != null) 'delivery_rating': deliveryRating,
        if (packagingRating != null) 'packaging_rating': packagingRating,
        if (productQualityRating != null)
          'product_quality_rating': productQualityRating,
        if (fulfillmentRating != null) 'fulfillment_rating': fulfillmentRating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (fulfillmentComment != null && fulfillmentComment.isNotEmpty)
          'fulfillment_comment': fulfillmentComment,
        'photos': photos,
      },
    );
    res.ensureSuccess('Could not submit order review');
  }

  Future<List<ReturnRequestModel>> listMyReturns() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return const [];
    }
    final res = await _api.get<List<ReturnRequestModel>>(
      ApiEndpoints.returnsMine,
      mapData: (raw) {
        List? list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          list = raw['items'] as List? ??
              raw['results'] as List? ??
              raw['data'] as List?;
        }
        if (list == null) return <ReturnRequestModel>[];
        return list
            .whereType<Map>()
            .map(
              (e) =>
                  ReturnRequestModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
    res.ensureSuccess('Could not load returns');
    final list = res.data ?? [];
    list.sort((a, b) {
      final aa = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
      final bb = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
      return bb.compareTo(aa);
    });
    return list;
  }

  /// In-place customer edit (pending/processing, before delivery cutoff).
  Future<OrderModel> customerEdit({
    required String orderId,
    required List<Map<String, dynamic>> items,
    String? deliveryTime,
    String? orderNotes,
    Map<String, dynamic>? shippingAddress,
    bool? allowSubstitution,
  }) async {
    if (AppConfig.useMockData) {
      return _mockOrders.first;
    }
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.orderCustomerEdit(orderId),
      body: {
        'items': items,
        if (deliveryTime != null) 'delivery_time': deliveryTime,
        if (orderNotes != null) 'order_notes': orderNotes,
        if (shippingAddress != null) 'shipping_address': shippingAddress,
        if (allowSubstitution != null) 'allow_substitution': allowSubstitution,
      },
      mapData: (raw) =>
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
    );
    res.ensureSuccess('Could not update order');
    final data = res.data ?? {};
    final orderRaw = data['order'] is Map ? data['order'] : data;
    return OrderModel.fromJson(Map<String, dynamic>.from(orderRaw as Map));
  }

  List<OrderModel> _mapOrderList(dynamic raw) {
    List? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      list = raw['items'] as List? ??
          raw['results'] as List? ??
          raw['orders'] as List?;
    }
    if (list == null) return [];
    return list
        .whereType<Map>()
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static final _mockOrders = [
    OrderModel(
      id: '1001',
      trackingNumber: 'GT-88421',
      status: 'Out for Delivery',
      total: 4580,
      createdAt: '2026-09-17T09:12:00',
      itemsCount: 4,
      items: const [
        OrderItemModel(name: 'Organic Honey 500g', quantity: 2, price: 890),
        OrderItemModel(name: 'Fresh Milk 1L', quantity: 1, price: 220),
      ],
      timeline: const [
        OrderTimelineStep(
          title: 'Order placed',
          subtitle: '17 Sep · 9:12 AM',
          done: true,
        ),
        OrderTimelineStep(
          title: 'Packed',
          subtitle: '17 Sep · 10:40 AM',
          done: true,
        ),
        OrderTimelineStep(
          title: 'Out for delivery',
          subtitle: '17 Sep · 2:05 PM',
          done: true,
        ),
        OrderTimelineStep(
          title: 'Delivered',
          subtitle: 'Expected by 4:00 PM',
          done: false,
        ),
      ],
    ),
    OrderModel(
      id: '1002',
      trackingNumber: 'GT-87102',
      status: 'Delivered',
      total: 1890,
      createdAt: '2026-09-12T11:00:00',
      itemsCount: 2,
    ),
  ];
}
