import 'dart:convert';

class MediaImage {
  const MediaImage({this.original, this.thumbnail});

  final String? original;
  final String? thumbnail;

  String? get best => original?.isNotEmpty == true
      ? original
      : (thumbnail?.isNotEmpty == true ? thumbnail : null);

  bool get hasUrl => (best ?? '').trim().isNotEmpty;

  factory MediaImage.fromJson(dynamic json) {
    if (json == null) return const MediaImage();
    if (json is String) {
      final s = json.trim();
      if (s.isEmpty) return const MediaImage();
      return MediaImage(original: s, thumbnail: s);
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      var original = map['original']?.toString().trim();
      var thumbnail = map['thumbnail']?.toString().trim();
      if (original != null && original.isEmpty) original = null;
      if (thumbnail != null && thumbnail.isEmpty) thumbnail = null;

      // Some payloads only store filename — keep null so UI falls back.
      // Real media always includes original/thumbnail paths from the API.
      return MediaImage(original: original, thumbnail: thumbnail);
    }
    return const MediaImage();
  }
}

class UserModel {
  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.phoneNo,
    this.avatar,
  });

  final int id;
  final String? name;
  final String? email;
  final String? phoneNo;
  final String? avatar;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phoneNo: json['phone_no']?.toString(),
      // Backend `serialize_user_with_avatar` returns avatar as
      // `{ original, thumbnail }` — never call Map.toString() for URLs.
      avatar: _avatarUrl(json['avatar'] ?? json['image']),
    );
  }

  /// Prefer http(s) media URLs; ignore generated SVG data-URLs.
  static String? _avatarUrl(dynamic raw) {
    final url = MediaImage.fromJson(raw).best?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) return null;
    return url;
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNo,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      avatar: avatar ?? this.avatar,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone_no': phoneNo,
        'avatar': avatar,
      };

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    this.slug,
    this.price = 0,
    this.salePrice,
    this.quantity,
    this.isStock,
    this.image,
    this.categoryId,
    this.shopId,
    this.manufacturerId,
    this.rating,
    this.reviewCount,
    this.description,
    this.barCode,
  });

  final int id;
  final String name;
  final String? slug;
  final double price;
  final double? salePrice;
  final int? quantity;
  /// Website `is_stock` — when true, treat as in stock even if qty is 0.
  final bool? isStock;
  final MediaImage? image;
  final int? categoryId;
  final int? shopId;
  final int? manufacturerId;
  final double? rating;
  final int? reviewCount;
  final String? description;
  final String? barCode;

  double get displayPrice => salePrice != null && salePrice! > 0 && salePrice! < price
      ? salePrice!
      : price;

  bool get hasDiscount =>
      salePrice != null && salePrice! > 0 && salePrice! < price;

  /// Matches website ProductCartButton: `quantity > 0 || is_stock === true`.
  bool get inStock => (quantity ?? 0) > 0 || isStock == true;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'price': price,
        'sale_price': salePrice,
        'quantity': quantity,
        'is_stock': isStock,
        'image': image?.best,
        'shop_id': shopId,
        'category_id': categoryId,
        'manufacturer_id': manufacturerId,
        'rating': rating,
        'description': description,
      };

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'];
    final category = json['category'];
    final shopId = UserModel._asInt(json['shop_id']) ??
        (shop is Map ? UserModel._asInt(shop['id']) : null);
    final categoryId = UserModel._asInt(json['category_id']) ??
        (category is Map ? UserModel._asInt(category['id']) : null);

    bool? asStock(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s.isEmpty) return null;
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
      return null;
    }

    return ProductModel(
      id: UserModel._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      price: asDouble(json['price']) ?? 0,
      salePrice: asDouble(json['sale_price']),
      quantity: UserModel._asInt(json['quantity']),
      isStock: asStock(json['is_stock']),
      image: MediaImage.fromJson(json['image'] ?? json['gallery']?[0]),
      categoryId: categoryId,
      shopId: shopId,
      manufacturerId: UserModel._asInt(json['manufacturer_id']),
      rating: asDouble(json['rating']),
      reviewCount: UserModel._asInt(json['review_count']),
      description: json['description']?.toString(),
      barCode: json['bar_code']?.toString() ??
          json['barcode']?.toString() ??
          json['BarCode']?.toString() ??
          json['product_code']?.toString() ??
          json['sku']?.toString(),
    );
  }

  static double? asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) => asDouble(v);
}

/// Website `/category/browse-tiles` tile (may include first-product image fallback).
class BrowseCategoryTile {
  const BrowseCategoryTile({
    required this.id,
    required this.name,
    this.slug,
    this.image,
    this.isFallback = false,
    this.productCount,
    this.sortOrder = 0,
  });

  final int id;
  final String name;
  final String? slug;
  final MediaImage? image;
  final bool isFallback;
  final int? productCount;
  final int sortOrder;

  String? get imageUrl => image?.best;

  factory BrowseCategoryTile.fromJson(Map<String, dynamic> json) {
    MediaImage image = MediaImage.fromJson(json['image']);
    if (!image.hasUrl) {
      image = MediaImage.fromJson(json['icon']);
    }
    // Bare icon slug → category-icons pack on the website.
    if (!image.hasUrl) {
      final icon = json['icon']?.toString().trim();
      if (icon != null &&
          icon.isNotEmpty &&
          !icon.contains('/') &&
          !icon.startsWith('http')) {
        image = MediaImage(
          original: '/category-icons/$icon.png',
          thumbnail: '/category-icons/$icon.png',
        );
      }
    }
    return BrowseCategoryTile(
      id: UserModel._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ??
          json['short_name']?.toString() ??
          '',
      slug: json['slug']?.toString(),
      image: image,
      isFallback: json['is_fallback'] == true,
      productCount: UserModel._asInt(json['product_count']),
      sortOrder: UserModel._asInt(json['sort_order']) ?? 0,
    );
  }
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.parentId,
    this.rootId,
    this.image,
    this.isActive = true,
    this.children = const [],
  });

  final int id;
  final String name;
  final String? slug;
  final int? parentId;
  final int? rootId;
  final MediaImage? image;
  final bool isActive;
  final List<CategoryModel> children;

  /// Website `getCategoryHref`: roots filter by `category.root_id`.
  bool get isRoot => parentId == null;

  int get browseFilterId =>
      isRoot ? (rootId ?? id) : id;

  String get browseFilterKey =>
      isRoot ? 'category.root_id' : 'category.id';

  bool get hasImage => image?.hasUrl == true;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final kids = <CategoryModel>[];
    final raw = json['children'];
    if (raw is List) {
      for (final c in raw) {
        if (c is Map) {
          kids.add(CategoryModel.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    bool asActive(dynamic v) {
      if (v == null) return true;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s == 'false' || s == '0' || s == 'no') return false;
      return true;
    }

    // Prefer image object; fall back to icon string (website parity).
    MediaImage? image = MediaImage.fromJson(json['image']);
    if (!image.hasUrl) {
      image = MediaImage.fromJson(json['icon']);
    }

    return CategoryModel(
      id: UserModel._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      parentId: UserModel._asInt(json['parent_id']),
      rootId: UserModel._asInt(json['root_id']),
      image: image,
      isActive: asActive(json['is_active']),
      children: kids,
    );
  }
}

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.quantity,
    required this.product,
    this.variationOptionId,
    this.shopId,
  });

  final int id;
  final int quantity;
  final ProductModel product;
  final int? variationOptionId;
  final int? shopId;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productRaw = json['product'];
    final productId =
        UserModel._asInt(json['product_id']) ?? UserModel._asInt(json['id']) ?? 0;

    final ProductModel product;
    if (productRaw is Map) {
      product = ProductModel.fromJson(Map<String, dynamic>.from(productRaw));
    } else {
      // FastAPI /cart/my-cart returns a flat CartItemResponse.
      product = ProductModel(
        id: productId,
        name: json['title']?.toString() ??
            json['name']?.toString() ??
            'Product',
        price: ProductModel.asDouble(json['original_price']) ??
            ProductModel.asDouble(json['unit_price']) ??
            0,
        salePrice: ProductModel.asDouble(json['unit_price']),
        image: MediaImage.fromJson(json['imageUrl'] ?? json['image']),
        shopId: UserModel._asInt(json['shop_id']),
        description: json['unit']?.toString(),
      );
    }

    return CartItemModel(
      id: productId,
      quantity: UserModel._asInt(json['quantity']) ?? 1,
      variationOptionId: UserModel._asInt(json['variation_option_id']),
      shopId: UserModel._asInt(json['shop_id']) ?? product.shopId,
      product: product,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quantity': quantity,
        'variation_option_id': variationOptionId,
        'shop_id': shopId,
        'product': product.toJson(),
      };
}

class AddressModel {
  const AddressModel({
    required this.id,
    required this.title,
    this.type,
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.isDefault = false,
    this.lat,
    this.lng,
    this.phone,
    this.name,
  });

  final int id;
  final String title;
  final String? type;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final bool isDefault;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? name;

  String get lineSummary {
    final parts = [
      street,
      city,
      state,
      postalCode,
      country,
    ].where((e) => e != null && e!.trim().isNotEmpty).map((e) => e!.trim());
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final addr = json['address'];
    final Map<String, dynamic> nested =
        addr is Map ? Map<String, dynamic>.from(addr) : json;
    final loc = json['location'];
    return AddressModel(
      id: UserModel._asInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? 'Address',
      type: json['type']?.toString(),
      street: nested['street']?.toString(),
      city: nested['city']?.toString(),
      state: nested['state']?.toString(),
      postalCode: nested['postal_code']?.toString(),
      country: nested['country']?.toString() ?? 'Pakistan',
      isDefault: json['is_default'] == true,
      lat: ProductModel.asDouble(
        loc is Map ? loc['lat'] : json['lat'],
      ),
      lng: ProductModel.asDouble(
        loc is Map ? loc['lng'] : json['lng'],
      ),
      phone: json['phone']?.toString(),
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toShippingPayload({
    required String customerName,
    required String customerPhone,
  }) {
    return {
      'name': name?.isNotEmpty == true ? name : customerName,
      'phone': phone?.isNotEmpty == true ? phone : customerPhone,
      'street': street ?? '',
      'city': city ?? '',
      'state': state,
      'postal_code': postalCode,
      'country': country ?? 'Pakistan',
      if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
    };
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    this.trackingNumber,
    this.status,
    this.paymentStatus,
    this.paymentGateway,
    this.total,
    this.subtotal,
    this.deliveryFee,
    this.discount,
    this.couponDiscount,
    this.salesTax,
    this.paidTotal,
    this.walletAmountUsed,
    this.deliveryTime,
    this.orderNotes,
    this.createdAt,
    this.itemsCount,
    this.items = const [],
    this.timeline = const [],
    this.shippingAddress,
    this.billingAddress,
    this.customerName,
    this.customerContact,
    this.shippingType,
    this.isReturn = false,
    this.orderReviewId,
    this.orderCompletedDate,
    this.orderDeliverDate,
    this.fulfillmentId,
    this.fulfillmentName,
    this.fulfillmentEmail,
    this.fulfillmentAvatarUrl,
    this.paymentProof = const [],
    this.paymentReference,
  });

  final String id;
  final String? trackingNumber;
  final String? status;
  final String? paymentStatus;
  final String? paymentGateway;
  final double? total;
  final double? subtotal;
  final double? deliveryFee;
  final double? discount;
  final double? couponDiscount;
  final double? salesTax;
  final double? paidTotal;
  final double? walletAmountUsed;
  final String? deliveryTime;
  final String? orderNotes;
  final String? createdAt;
  final int? itemsCount;
  final List<OrderItemModel> items;
  final List<OrderTimelineStep> timeline;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;
  final String? customerName;
  final String? customerContact;
  final String? shippingType;
  final bool isReturn;
  final int? orderReviewId;
  final String? orderCompletedDate;
  final String? orderDeliverDate;
  final int? fulfillmentId;
  final String? fulfillmentName;
  final String? fulfillmentEmail;
  final String? fulfillmentAvatarUrl;
  final List<String> paymentProof;
  final String? paymentReference;

  String get displayId => trackingNumber?.isNotEmpty == true
      ? trackingNumber!
      : id;

  String get statusKey => (status ?? '').toLowerCase().replaceAll('_', '-');

  String get paymentStatusKey =>
      (paymentStatus ?? '').toLowerCase().replaceAll('_', '-');

  String get statusLabel {
    final k = statusKey;
    if (k.contains('cancel')) return 'Cancelled';
    if (k.contains('refund')) return 'Refunded';
    if (k.contains('fail')) return 'Failed';
    if (k.contains('deliver') || k.contains('completed')) return 'Completed';
    if (k.contains('out-for-delivery') || k.contains('out for')) {
      return 'On the way';
    }
    if (k.contains('packed') ||
        k.contains('processing') ||
        k.contains('facility') ||
        k.contains('distribution')) {
      return 'Preparing your order';
    }
    if (k.contains('pending') || k.isEmpty) return 'Order placed';
    return (status ?? 'Order placed')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceFirst('order ', '');
  }

  String get paymentLabel {
    final g = (paymentGateway ?? '').toLowerCase();
    final p = (paymentStatus ?? '').toLowerCase();
    if (g.contains('cash') ||
        g == 'cod' ||
        p.contains('cash-on-delivery') ||
        p.contains('cash_on_delivery')) {
      return 'Cash on arrival';
    }
    if (g.contains('jazz')) return 'JazzCash';
    if (g.contains('easy')) return 'EasyPaisa';
    if (g.contains('payfast') || g.contains('card')) return 'Card / PayFast';
    if (g.contains('wallet') || p.contains('wallet')) return 'Wallet';
    if (g.contains('bank')) return 'Bank transfer';
    if (g.isNotEmpty) {
      return g.replaceAll('_', ' ').replaceAll('-', ' ');
    }
    if (p.contains('cash')) return 'Cash on arrival';
    return 'Payment';
  }

  String get paymentStatusLabel {
    final p = paymentStatusKey;
    if (p.isEmpty) return 'Pending';
    return p.replaceAll('-', ' ');
  }

  bool get isCompleted =>
      statusKey.contains('completed') || statusKey.contains('delivered');

  bool get isCancelled => statusKey.contains('cancel');

  bool get isRefunded => statusKey.contains('refund');

  /// Website `canCancelOrder` — until completed / cancelled / refunded.
  bool get canCancel => !isCompleted && !isCancelled && !isRefunded;

  /// Raw completed eligibility for returns (settings window applied by caller).
  bool get canRequestReturnBase =>
      isCompleted &&
      !isCancelled &&
      !paymentStatusKey.contains('reversal') &&
      !isReturn;

  bool get canRequestReturn => canRequestReturnBase;

  String? get reviewEligibleDate =>
      orderCompletedDate ?? orderDeliverDate;

  bool get hasOrderReview => (orderReviewId ?? 0) > 0;

  bool get canUpdate {
    // Deferred import-free check: status gate only.
    // Callers should also use `canEditOrder(...)` for the 4h delivery cutoff.
    return !isCompleted &&
        !isCancelled &&
        (statusKey.contains('pending') || statusKey.contains('processing'));
  }

  int get resolvedItemsCount =>
      itemsCount ??
      items.fold<int>(0, (s, e) => s + e.quantity);

  double get resolvedDiscount {
    final d = (discount ?? 0) + (couponDiscount ?? 0);
    if (d > 0) return d;
    return items.fold<double>(0, (s, e) => s + e.savedAmount);
  }

  double get displayTotal => paidTotal ?? total ?? 0;

  /// Figma timeline: Order Placed → Preparing → Out for Delivery → Delivered
  List<OrderTimelineStep> get figmaTimeline {
    if (timeline.isNotEmpty) return timeline;
    final placed = formatOrderDateTime(createdAt);
    final k = statusKey;
    final cancelled = isCancelled;
    final delivered = isCompleted;
    final out = k.contains('out-for-delivery') || k.contains('out for');
    final preparing = delivered ||
        out ||
        k.contains('processing') ||
        k.contains('packed') ||
        k.contains('facility') ||
        k.contains('distribution');
    return [
      OrderTimelineStep(
        title: 'Order Placed',
        subtitle: placed,
        done: !cancelled,
      ),
      OrderTimelineStep(
        title: 'Preparing Your Order',
        subtitle: '',
        done: preparing && !cancelled,
      ),
      OrderTimelineStep(
        title: 'On the way',
        subtitle: '',
        done: (out || delivered) && !cancelled,
      ),
      OrderTimelineStep(
        title: 'Completed',
        subtitle: '',
        done: delivered && !cancelled,
      ),
    ];
  }

  String? addressLine(Map<String, dynamic>? addr) {
    if (addr == null || addr.isEmpty) return null;
    final nested = addr['address'];
    final map = nested is Map
        ? {...addr, ...Map<String, dynamic>.from(nested)}
        : addr;
    final parts = <String>[
      if ((map['name'] ?? map['customer_name'] ?? customerName) != null)
        '${map['name'] ?? map['customer_name'] ?? customerName}',
      if ((map['phone'] ?? customerContact) != null)
        '${map['phone'] ?? customerContact}',
      if (map['street'] != null) '${map['street']}',
      if (map['address'] is String) '${map['address']}',
      [
        map['city'],
        map['state'],
        map['postal_code'] ?? map['zip'],
      ].where((e) => e != null && '$e'.trim().isNotEmpty).join(', '),
      if (map['country'] != null) '${map['country']}',
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join('\n');
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final products = <OrderItemModel>[];
    final rawItems = json['order_products'] ?? json['items'] ?? json['products'];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          products.add(OrderItemModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final steps = <OrderTimelineStep>[];
    final rawTimeline = json['timeline'] ??
        json['status_history'] ??
        json['order_status_timeline'] ??
        json['order_status_history'];
    String? completedDate;
    String? deliverDate;
    if (rawTimeline is List) {
      for (final e in rawTimeline) {
        if (e is Map) {
          steps.add(OrderTimelineStep.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    } else if (rawTimeline is Map) {
      final map = Map<String, dynamic>.from(rawTimeline);
      completedDate = map['order_completed_date']?.toString();
      deliverDate = map['order_deliver_date']?.toString();
      for (final entry in map.entries) {
        if (entry.value != null) {
          steps.add(OrderTimelineStep(
            title: entry.key.toString().replaceAll('_', ' '),
            subtitle: entry.value.toString(),
            done: true,
          ));
        }
      }
    }

    final history = json['order_status_history'];
    if (history is Map) {
      completedDate ??= history['order_completed_date']?.toString();
      deliverDate ??= history['order_deliver_date']?.toString();
    }

    final id = json['id']?.toString() ??
        json['order_id']?.toString() ??
        json['tracking_number']?.toString() ??
        '';

    Map<String, dynamic>? asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

    final proof = <String>[];
    final rawProof = json['payment_proof'];
    if (rawProof is List) {
      for (final e in rawProof) {
        if (e is String && e.trim().isNotEmpty) {
          proof.add(e.trim());
        } else if (e is Map) {
          final src = (e['original'] ?? e['thumbnail'] ?? e['url'])
              ?.toString()
              .trim();
          if (src != null && src.isNotEmpty) proof.add(src);
        }
      }
    }

    final fulfillment = asMap(json['fullfillment_user_info']) ??
        asMap(json['fulfillment_user_info']);
    final avatar = fulfillment?['avatar'];
    String? avatarUrl;
    if (avatar is Map) {
      avatarUrl =
          (avatar['thumbnail'] ?? avatar['original'])?.toString();
    } else if (avatar is String) {
      avatarUrl = avatar;
    }

    final paymentResponse = asMap(json['payment_response']);

    return OrderModel(
      id: id,
      trackingNumber: json['tracking_number']?.toString() ??
          json['trackingNumber']?.toString(),
      status: json['order_status']?.toString() ??
          json['status']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      paymentGateway: json['payment_gateway']?.toString(),
      total: ProductModel.asDouble(
        json['total'] ?? json['amount'] ?? json['grand_total'],
      ),
      subtotal: ProductModel.asDouble(
        json['amount'] ?? json['subtotal'],
      ),
      deliveryFee: ProductModel.asDouble(
        json['delivery_fee'] ?? json['shipping_amount'],
      ),
      discount: ProductModel.asDouble(json['discount']),
      couponDiscount: ProductModel.asDouble(json['coupon_discount']),
      salesTax: ProductModel.asDouble(json['sales_tax'] ?? json['tax']),
      paidTotal: ProductModel.asDouble(json['paid_total']),
      walletAmountUsed: ProductModel.asDouble(json['wallet_amount_used']),
      deliveryTime: json['delivery_time']?.toString(),
      orderNotes: json['order_notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
      itemsCount: UserModel._asInt(json['items_count']) ??
          (products.isNotEmpty
              ? products.fold<int>(0, (s, e) => s + e.quantity)
              : null),
      items: products,
      timeline: steps,
      shippingAddress: asMap(json['shipping_address']),
      billingAddress: asMap(json['billing_address']),
      customerName: json['customer_name']?.toString(),
      customerContact: json['customer_contact']?.toString(),
      shippingType: json['shipping_type']?.toString(),
      isReturn: json['is_return'] == true ||
          json['is_return'] == 1 ||
          json['is_return']?.toString() == 'true',
      orderReviewId: UserModel._asInt(json['order_review_id']),
      orderCompletedDate: completedDate,
      orderDeliverDate: deliverDate,
      fulfillmentId: UserModel._asInt(
        json['fullfillment_id'] ?? json['fulfillment_id'],
      ),
      fulfillmentName: fulfillment?['name']?.toString(),
      fulfillmentEmail: fulfillment?['email']?.toString(),
      fulfillmentAvatarUrl: avatarUrl,
      paymentProof: proof,
      paymentReference: paymentResponse?['reference']?.toString() ??
          json['payment_reference']?.toString(),
    );
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
    this.id,
    this.productId,
    this.variationOptionId,
    this.image,
    this.regularPrice,
    this.subtotal,
    this.isReturned = false,
    this.variationLabel,
    this.shopId,
    this.shopName,
  });

  final int? id;
  final int? productId;
  final int? variationOptionId;
  final String name;
  final int quantity;
  final double price;
  final MediaImage? image;
  final double? regularPrice;
  final double? subtotal;
  final bool isReturned;
  final String? variationLabel;
  final int? shopId;
  final String? shopName;

  double get lineTotal => subtotal ?? (price * quantity);

  double get savedAmount {
    final reg = regularPrice;
    if (reg == null || reg <= price) return 0;
    return (reg - price) * quantity;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final snapshot = json['product_snapshot'];
    String? name;
    MediaImage? image;
    double? regular;
    int? shopId = UserModel._asInt(json['shop_id']);
    if (product is Map) {
      name = product['name']?.toString();
      image = MediaImage.fromJson(product['image']);
      regular = ProductModel.asDouble(product['price']);
      shopId ??= UserModel._asInt(product['shop_id']);
      final shop = product['shop'];
      if (shop is Map) shopId ??= UserModel._asInt(shop['id']);
    }
    if ((name == null || name.isEmpty) && snapshot is Map) {
      name = snapshot['name']?.toString();
      image ??= MediaImage.fromJson(snapshot['image']);
      regular ??= ProductModel.asDouble(snapshot['price']);
      shopId ??= UserModel._asInt(snapshot['shop_id']);
    }
    name ??= json['name']?.toString() ?? json['title']?.toString();
    image ??= MediaImage.fromJson(json['image']);
    final unit = ProductModel.asDouble(
          json['sale_price'] ??
              json['unit_price'] ??
              json['price'] ??
              json['subtotal'],
        ) ??
        0;
    final qty = UserModel._asInt(json['order_quantity']) ??
        UserModel._asInt(json['quantity']) ??
        1;

    String? variationLabel;
    final varSnap = json['variation_option_snapshot'] ?? json['variation'];
    final varData = json['variation_option'] ?? json['variation_data'];
    final source = varSnap is Map
        ? varSnap
        : (varData is Map ? varData : null);
    if (source != null) {
      variationLabel = source['title']?.toString();
      if ((variationLabel == null || variationLabel.isEmpty) &&
          source['options'] is Map) {
        variationLabel = (source['options'] as Map)
            .entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
      }
    }

    return OrderItemModel(
      id: UserModel._asInt(json['id']),
      productId: UserModel._asInt(json['product_id']) ??
          (product is Map ? UserModel._asInt(product['id']) : null),
      variationOptionId: UserModel._asInt(json['variation_option_id']),
      name: name ?? 'Item',
      quantity: qty,
      price: unit,
      image: image,
      regularPrice: ProductModel.asDouble(json['unit_price']) ?? regular,
      subtotal: ProductModel.asDouble(json['subtotal']),
      isReturned: json['is_returned'] == true ||
          json['is_returned'] == 1 ||
          json['is_returned']?.toString() == 'true',
      variationLabel: variationLabel,
      shopId: shopId,
      shopName: json['shop_name']?.toString(),
    );
  }
}

class ReturnRequestModel {
  const ReturnRequestModel({
    required this.id,
    this.orderId,
    this.trackingNumber,
    this.returnType,
    this.reason,
    this.status,
    this.refundAmount,
    this.refundStatus,
    this.createdAt,
  });

  final int id;
  final int? orderId;
  final String? trackingNumber;
  final String? returnType;
  final String? reason;
  final String? status;
  final double? refundAmount;
  final String? refundStatus;
  final String? createdAt;

  String get displayOrder =>
      trackingNumber?.isNotEmpty == true
          ? trackingNumber!
          : (orderId != null ? '#$orderId' : '#$id');

  String get typeLabel {
    final t = (returnType ?? '').toLowerCase();
    if (t.contains('partial')) return 'Partial refund';
    if (t.contains('exchange')) return 'Exchange';
    if (t.contains('full')) return 'Full refund';
    return returnType?.replaceAll('_', ' ') ?? 'Return';
  }

  String get statusLabel {
    final s = (status ?? refundStatus ?? 'pending').replaceAll('_', ' ');
    if (s.isEmpty) return 'Pending';
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  factory ReturnRequestModel.fromJson(Map<String, dynamic> json) {
    return ReturnRequestModel(
      id: UserModel._asInt(json['id']) ?? 0,
      orderId: UserModel._asInt(json['order_id']),
      trackingNumber: json['tracking_number']?.toString(),
      returnType: json['return_type']?.toString(),
      reason: json['reason']?.toString(),
      status: json['status']?.toString(),
      refundAmount: ProductModel.asDouble(json['refund_amount']),
      refundStatus: json['refund_status']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

String formatOrderDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return raw;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, '
      '${h.toString().padLeft(2, '0')}:$mm $ampm';
}

class OrderTimelineStep {
  const OrderTimelineStep({
    required this.title,
    this.subtitle,
    this.done = false,
  });

  final String title;
  final String? subtitle;
  final bool done;

  factory OrderTimelineStep.fromJson(Map<String, dynamic> json) {
    return OrderTimelineStep(
      title: json['title']?.toString() ??
          json['status']?.toString() ??
          json['name']?.toString() ??
          'Update',
      subtitle: json['subtitle']?.toString() ??
          json['created_at']?.toString() ??
          json['timestamp']?.toString(),
      done: json['done'] == true ||
          json['completed'] == true ||
          json['is_completed'] == true,
    );
  }
}

class WalletModel {
  const WalletModel({
    this.balance = 0,
    this.totalCredited = 0,
    this.totalDebited = 0,
  });

  final double balance;
  final double totalCredited;
  final double totalDebited;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: ProductModel.asDouble(json['balance']) ?? 0,
      totalCredited: ProductModel.asDouble(json['total_credited']) ?? 0,
      totalDebited: ProductModel.asDouble(json['total_debited']) ?? 0,
    );
  }
}

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.transactionType,
    this.description,
    this.createdAt,
    this.balanceAfter,
  });

  final int id;
  final double amount;
  final String transactionType;
  final String? description;
  final String? createdAt;
  final double? balanceAfter;

  bool get isCredit =>
      transactionType.toLowerCase() == 'credit' || amount > 0;

  String get title {
    final d = description?.trim();
    if (d != null && d.isNotEmpty) return d;
    return isCredit ? 'Credit' : 'Debit';
  }

  String get dateLabel {
    final raw = createdAt;
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: UserModel._asInt(json['id']) ?? 0,
      amount: ProductModel.asDouble(json['amount']) ?? 0,
      transactionType: json['transaction_type']?.toString() ?? 'credit',
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString(),
      balanceAfter: ProductModel.asDouble(json['balance_after']),
    );
  }
}

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.title,
    this.body,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? body;
  final bool isRead;
  final String? createdAt;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: UserModel._asInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? json['message']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class BannerModel {
  const BannerModel({
    required this.id,
    this.title,
    this.description,
    this.subtitle,
    this.buttonText,
    this.image,
    this.link,
  });

  final int id;
  final String? title;
  final String? description;
  final String? subtitle;
  final String? buttonText;
  final MediaImage? image;
  final String? link;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: UserModel._asInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString(),
      description: json['description']?.toString(),
      subtitle: json['subtitle']?.toString(),
      buttonText: json['buttonText']?.toString() ??
          json['button_text']?.toString(),
      image: MediaImage.fromJson(json['image'] ?? json['banner']),
      link: json['link']?.toString() ??
          json['link_url']?.toString() ??
          json['url']?.toString(),
    );
  }

  /// Website `customerFacingHeadline` — skip internal admin names.
  String displayHeadline(String fallback) {
    final raw = title?.trim() ?? '';
    final desc = description?.trim() ?? '';
    final looksInternal = raw.isEmpty ||
        RegExp(r'\bbanner\b', caseSensitive: false).hasMatch(raw) ||
        RegExp(r'^home\s*page$', caseSensitive: false).hasMatch(raw);
    if (!looksInternal) return raw;
    if (desc.isNotEmpty) return desc;
    final cleaned = raw
        .replaceAll(RegExp(r'\s*\bbanner\b\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'^home\s*page\s*', caseSensitive: false), '')
        .trim();
    if (cleaned.length >= 2) return cleaned;
    return fallback;
  }
}

class ManufacturerModel {
  const ManufacturerModel({
    required this.id,
    required this.name,
    this.slug,
    this.image,
  });

  final int id;
  final String name;
  final String? slug;
  final MediaImage? image;

  factory ManufacturerModel.fromJson(Map<String, dynamic> json) {
    return ManufacturerModel(
      id: UserModel._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      image: MediaImage.fromJson(json['image']),
    );
  }
}

/// Shipping row from `GET /shipping/read/{id}`.
class ShippingClassModel {
  const ShippingClassModel({
    required this.id,
    this.name,
    this.amount = 0,
    this.type = 'fixed',
  });

  final int id;
  final String? name;
  final double amount;
  final String type;

  factory ShippingClassModel.fromJson(Map<String, dynamic> json) {
    return ShippingClassModel(
      id: UserModel._asInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      amount: ProductModel.asDouble(json['amount']) ?? 0,
      type: (json['type']?.toString() ?? 'fixed').toLowerCase(),
    );
  }
}

/// Site options from `GET /settings` (shipping thresholds, slots, etc.).
class SiteSettingsModel {
  const SiteSettingsModel({
    this.freeShipping = false,
    this.freeShippingAmount = 0,
    this.minimumOrderAmount = 0,
    this.maximumShippingAmountOff = 0,
    this.shippingClassId,
    this.taxClassId,
    this.siteTitle,
    this.siteSubtitle,
    this.guestCheckout = true,
    this.deliveryTimes = DeliveryTimeSlot.defaults,
    this.paymentGateway = const [],
    this.returnItemDays = 3,
    this.orderReviewDays = 0,
    this.enableReviewPopup = false,
    this.isProductReview = false,
    this.isReview = false,
    this.isRating = false,
  });

  final bool freeShipping;
  final double freeShippingAmount;
  final double minimumOrderAmount;
  final double maximumShippingAmountOff;
  final int? shippingClassId;
  final int? taxClassId;
  final String? siteTitle;
  final String? siteSubtitle;

  /// Website `guestCheckout` — when true, guests may checkout without login.
  final bool guestCheckout;

  /// Website `deliveryTime` slots (Morning / Noon / Afternoon / Evening).
  final List<DeliveryTimeSlot> deliveryTimes;

  /// Website `paymentGateway` options from settings.
  final List<PaymentMethodConfig> paymentGateway;

  /// Website `ReturnItemDays` (default 3).
  final int returnItemDays;

  /// Website `OrderReviewDays` / `orderReviewDays`.
  final int orderReviewDays;

  /// Website `enableReviewPopup`.
  final bool enableReviewPopup;

  final bool isProductReview;
  final bool isReview;
  final bool isRating;

  bool isReturnAllowed(String? completedDate) =>
      _isWithinAllowedDays(completedDate, returnItemDays);

  bool isOrderReviewAllowed(String? completedDate) =>
      _isWithinAllowedDays(completedDate, orderReviewDays);

  static bool _isWithinAllowedDays(String? completedDate, int allowedDays) {
    if (completedDate == null || completedDate.isEmpty || allowedDays <= 0) {
      return false;
    }
    final completed = DateTime.tryParse(completedDate)?.toLocal();
    if (completed == null) return false;
    final deadline = completed.add(Duration(days: allowedDays));
    return deadline.isAfter(DateTime.now());
  }

  String get freeDeliveryAnnouncement {
    if (freeShipping && freeShippingAmount > 0) {
      final amt = freeShippingAmount == freeShippingAmount.roundToDouble()
          ? freeShippingAmount.toStringAsFixed(0)
          : freeShippingAmount.toStringAsFixed(2);
      return 'Complimentary fulfillment on orders over Rs. $amt · Delivered in under an hour · Cash on delivery available';
    }
    return 'Delivered in under an hour · Cash on delivery available';
  }

  factory SiteSettingsModel.fromOptions(Map<String, dynamic> options) {
    bool asBool(dynamic v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is num) return v == 1;
      final s = v.toString().trim().toLowerCase();
      if (s == 'false' || s == '0' || s == 'no') return false;
      if (s == 'true' || s == '1' || s == 'yes') return true;
      return fallback;
    }

    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    int asDays(dynamic v, {int fallback = 0}) {
      if (v is num && v > 0) return v.toInt();
      final n = int.tryParse(v?.toString() ?? '');
      if (n != null && n > 0) return n;
      return fallback;
    }

    int? asClassId(dynamic v) {
      if (v == null) return null;
      if (v is Map) {
        return UserModel._asInt(v['id']);
      }
      return UserModel._asInt(v);
    }

    List<DeliveryTimeSlot> parseSlots(dynamic raw) {
      dynamic value = raw;
      if (value is String && value.isNotEmpty) {
        try {
          value = jsonDecode(value);
        } catch (_) {
          return DeliveryTimeSlot.defaults;
        }
      }
      if (value is! List) return DeliveryTimeSlot.defaults;
      final slots = <DeliveryTimeSlot>[];
      for (final item in value) {
        if (item is Map) {
          final title = item['title']?.toString().trim() ?? '';
          if (title.isEmpty) continue;
          slots.add(
            DeliveryTimeSlot(
              title: title,
              description: item['description']?.toString(),
            ),
          );
        }
      }
      return slots.isEmpty ? DeliveryTimeSlot.defaults : slots;
    }

    return SiteSettingsModel(
      freeShipping: asBool(options['freeShipping']),
      freeShippingAmount: asDouble(options['freeShippingAmount']),
      minimumOrderAmount: asDouble(options['minimumOrderAmount']),
      maximumShippingAmountOff: asDouble(options['maximumShippingAmountOff']),
      shippingClassId: asClassId(options['shippingClass']),
      taxClassId: asClassId(options['taxClass']),
      siteTitle: options['siteTitle']?.toString(),
      siteSubtitle: options['siteSubtitle']?.toString(),
      guestCheckout: asBool(options['guestCheckout'], fallback: true),
      deliveryTimes: parseSlots(options['deliveryTime']),
      paymentGateway: PaymentMethodConfig.parseList(options['paymentGateway']),
      returnItemDays: asDays(options['ReturnItemDays'], fallback: 3),
      orderReviewDays: asDays(
        options['OrderReviewDays'] ?? options['orderReviewDays'],
      ),
      enableReviewPopup: asBool(options['enableReviewPopup']),
      isProductReview: asBool(options['isProductReview']),
      isReview: asBool(
        options['isReview'] ?? options['IsReview'],
      ),
      isRating: asBool(
        options['isRating'] ?? options['IsRatting'] ?? options['IsRating'],
      ),
    );
  }
}

/// Website `paymentGateway` entry from settings / fallback config.
class PaymentMethodConfig {
  const PaymentMethodConfig({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.active = true,
    this.enabled = true,
    this.isDefault = false,
    this.sortOrder = 100,
    this.requiresWalletNumber = false,
    this.walletNumberLabel,
    this.requiresPaymentProof = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? image;
  final bool active;
  final bool enabled;
  final bool isDefault;
  final int sortOrder;
  final bool requiresWalletNumber;
  final String? walletNumberLabel;
  final bool requiresPaymentProof;

  bool get isCashOnDelivery =>
      id == 'cod' || id == 'cash_on_delivery' || id == 'cash';

  bool get isBankTransfer =>
      id == 'bank_transfer' ||
      id == 'manual_payment' ||
      id == 'payment_proof' ||
      requiresPaymentProof;

  bool get isJazzCash => id == 'jazzcash';
  bool get isJazzCashCard => id == 'jazzcash_card';
  bool get isEasyPaisa => id == 'easypaisa';
  bool get isPayFast => id == 'payfast';

  factory PaymentMethodConfig.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    var name = json['name']?.toString() ?? id;
    var requiresWallet = json['requiresWalletNumber'] == true;
    var walletLabel = json['walletNumberLabel']?.toString();
    var requiresProof = json['requiresPaymentProof'] == true;

    if (id == 'payfast') name = 'PayFast';
    if (id == 'jazzcash_card') {
      name = name.isEmpty ? 'JazzCash Card' : name;
      requiresWallet = false;
    }
    if (id == 'bank_transfer' ||
        id == 'manual_payment' ||
        id == 'payment_proof') {
      name = name.isEmpty ? 'Pay & Upload Receipt' : name;
      requiresProof = json['requiresPaymentProof'] != false;
    }
    if (id == 'jazzcash') {
      requiresWallet = true;
      walletLabel ??= 'JazzCash Mobile Number';
    }
    if (id == 'easypaisa') {
      requiresWallet = true;
      walletLabel ??= 'EasyPaisa Mobile Number';
    }

    return PaymentMethodConfig(
      id: id,
      name: name,
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      active: json['active'] != false,
      enabled: json['enabled'] != false,
      isDefault: json['default'] == true,
      sortOrder: UserModel._asInt(json['sortOrder']) ?? 100,
      requiresWalletNumber: requiresWallet,
      walletNumberLabel: walletLabel,
      requiresPaymentProof: requiresProof,
    );
  }

  static List<PaymentMethodConfig> parseList(dynamic raw) {
    dynamic value = raw;
    if (value is String && value.isNotEmpty) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return fallbackPaymentMethods;
      }
    }
    if (value is! List || value.isEmpty) return fallbackPaymentMethods;
    final list = value
        .whereType<Map>()
        .map((e) => PaymentMethodConfig.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.id.isNotEmpty)
        .toList();
    return ensurePaymentMethods(list);
  }

  static const List<PaymentMethodConfig> _fallbackRaw = [
    PaymentMethodConfig(
      id: 'payfast',
      name: 'PayFast',
      description: 'Secure card payment via PayFast',
      sortOrder: 1,
    ),
    PaymentMethodConfig(
      id: 'easypaisa',
      name: 'EasyPaisa',
      description: 'Pay with your EasyPaisa mobile wallet',
      sortOrder: 2,
      requiresWalletNumber: true,
      walletNumberLabel: 'EasyPaisa Mobile Number',
    ),
    PaymentMethodConfig(
      id: 'jazzcash',
      name: 'JazzCash',
      description: 'Pay with your JazzCash mobile wallet',
      sortOrder: 3,
      requiresWalletNumber: true,
      walletNumberLabel: 'JazzCash Mobile Number',
    ),
    PaymentMethodConfig(
      id: 'jazzcash_card',
      name: 'JazzCash Card',
      description: 'Pay by debit/credit card via JazzCash secure page',
      sortOrder: 4,
    ),
    PaymentMethodConfig(
      id: 'cash_on_delivery',
      name: 'Cash On Delivery',
      description: 'Pay when your order arrives',
      sortOrder: 5,
      isDefault: true,
    ),
    PaymentMethodConfig(
      id: 'bank_transfer',
      name: 'Pay & Upload Receipt',
      description:
          'Transfer to our bank/JazzCash/EasyPaisa account, then upload your payment screenshot.',
      sortOrder: 6,
      requiresPaymentProof: true,
    ),
  ];

  static List<PaymentMethodConfig> get fallbackPaymentMethods =>
      ensurePaymentMethods(List<PaymentMethodConfig>.from(_fallbackRaw));

  static List<PaymentMethodConfig> ensurePaymentMethods(
    List<PaymentMethodConfig> input,
  ) {
    final byId = {for (final m in input) m.id: m};
    for (final fallback in const [
      'bank_transfer',
      'jazzcash_card',
    ]) {
      if (!byId.containsKey(fallback)) {
        PaymentMethodConfig? add;
        for (final m in _fallbackRaw) {
          if (m.id == fallback) {
            add = m;
            break;
          }
        }
        if (add != null) byId[fallback] = add;
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  static List<PaymentMethodConfig> activeSorted(
    List<PaymentMethodConfig> methods,
  ) {
    return ensurePaymentMethods(methods)
        .where((m) => m.active)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  static String? defaultId(List<PaymentMethodConfig> methods) {
    final active = activeSorted(methods);
    final preferred = active.where((m) => m.isDefault).toList();
    if (preferred.isNotEmpty) return preferred.first.id;
    return active.isEmpty ? null : active.first.id;
  }
}

class DeliveryTimeSlot {
  const DeliveryTimeSlot({
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  String get label {
    final d = description?.trim();
    if (d == null || d.isEmpty) return title;
    return '$title - $d';
  }

  static const defaults = [
    DeliveryTimeSlot(title: 'Morning', description: '8.00 AM - 11.00 AM'),
    DeliveryTimeSlot(title: 'Noon', description: '11.00 AM - 2.00 PM'),
    DeliveryTimeSlot(title: 'Afternoon', description: '2.00 PM - 5.00 PM'),
    DeliveryTimeSlot(title: 'Evening', description: '5.00 PM - 8.00 PM'),
  ];
}

class CouponModel {
  const CouponModel({
    required this.id,
    this.code,
    this.type,
    this.amount,
    this.minimumCartAmount,
  });

  final int id;
  final String? code;
  final String? type;
  final double? amount;
  final double? minimumCartAmount;

  double discountFor(double subtotal) {
    final a = amount ?? 0;
    if (a <= 0) return 0;
    final t = (type ?? '').toLowerCase();
    if (t.contains('percent') || t == 'percentage') {
      return (subtotal * a / 100).clamp(0, subtotal);
    }
    return a.clamp(0, subtotal);
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: UserModel._asInt(json['id']) ?? 0,
      code: json['code']?.toString(),
      type: json['type']?.toString() ?? json['discount_type']?.toString(),
      amount: ProductModel.asDouble(
        json['amount'] ?? json['discount'] ?? json['value'],
      ),
      minimumCartAmount: ProductModel.asDouble(
        json['minimum_cart_amount'] ?? json['minimumCartAmount'],
      ),
    );
  }
}
