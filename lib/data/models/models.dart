class MediaImage {
  const MediaImage({this.original, this.thumbnail});

  final String? original;
  final String? thumbnail;

  String? get best => original?.isNotEmpty == true
      ? original
      : (thumbnail?.isNotEmpty == true ? thumbnail : null);

  factory MediaImage.fromJson(dynamic json) {
    if (json == null) return const MediaImage();
    if (json is String) return MediaImage(original: json, thumbnail: json);
    if (json is Map) {
      return MediaImage(
        original: json['original']?.toString(),
        thumbnail: json['thumbnail']?.toString(),
      );
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
      avatar: json['avatar']?.toString() ??
          MediaImage.fromJson(json['image']).best,
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
    this.image,
    this.categoryId,
    this.shopId,
    this.manufacturerId,
    this.rating,
    this.reviewCount,
    this.description,
  });

  final int id;
  final String name;
  final String? slug;
  final double price;
  final double? salePrice;
  final int? quantity;
  final MediaImage? image;
  final int? categoryId;
  final int? shopId;
  final int? manufacturerId;
  final double? rating;
  final int? reviewCount;
  final String? description;

  double get displayPrice => salePrice != null && salePrice! > 0 && salePrice! < price
      ? salePrice!
      : price;

  bool get hasDiscount =>
      salePrice != null && salePrice! > 0 && salePrice! < price;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'];
    final category = json['category'];
    final shopId = UserModel._asInt(json['shop_id']) ??
        (shop is Map ? UserModel._asInt(shop['id']) : null);
    final categoryId = UserModel._asInt(json['category_id']) ??
        (category is Map ? UserModel._asInt(category['id']) : null);

    return ProductModel(
      id: UserModel._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      price: asDouble(json['price']) ?? 0,
      salePrice: asDouble(json['sale_price']),
      quantity: UserModel._asInt(json['quantity']),
      image: MediaImage.fromJson(json['image'] ?? json['gallery']?[0]),
      categoryId: categoryId,
      shopId: shopId,
      manufacturerId: UserModel._asInt(json['manufacturer_id']),
      rating: asDouble(json['rating']),
      reviewCount: UserModel._asInt(json['review_count']),
      description: json['description']?.toString(),
    );
  }

  static double? asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) => asDouble(v);
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.parentId,
    this.image,
    this.children = const [],
  });

  final int id;
  final String name;
  final String? slug;
  final int? parentId;
  final MediaImage? image;
  final List<CategoryModel> children;

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
    return CategoryModel(
      id: UserModel._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      parentId: UserModel._asInt(json['parent_id']),
      // Website: resolveMediaUrl(image) || resolveMediaUrl(icon)
      image: MediaImage.fromJson(json['image'] ?? json['icon']),
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
    this.deliveryTime,
    this.orderNotes,
    this.createdAt,
    this.itemsCount,
    this.items = const [],
    this.timeline = const [],
    this.shippingAddress,
    this.billingAddress,
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
  final String? deliveryTime;
  final String? orderNotes;
  final String? createdAt;
  final int? itemsCount;
  final List<OrderItemModel> items;
  final List<OrderTimelineStep> timeline;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;

  String get displayId => trackingNumber?.isNotEmpty == true
      ? trackingNumber!
      : id;

  String get statusKey => (status ?? '').toLowerCase().replaceAll('_', '-');

  String get statusLabel {
    final k = statusKey;
    if (k.contains('cancel')) return 'Cancelled';
    if (k.contains('refund')) return 'Refunded';
    if (k.contains('fail')) return 'Failed';
    if (k.contains('deliver') || k.contains('completed')) return 'Delivered';
    if (k.contains('out-for-delivery') || k.contains('out for')) {
      return 'Out for delivery';
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
      return 'Cash on delivery';
    }
    if (g.contains('jazz')) return 'JazzCash';
    if (g.contains('easy')) return 'EasyPaisa';
    if (g.contains('payfast') || g.contains('card')) return 'Card / PayFast';
    if (g.contains('wallet') || p.contains('wallet')) return 'Wallet';
    if (g.contains('bank')) return 'Bank transfer';
    if (g.isNotEmpty) {
      return g.replaceAll('_', ' ').replaceAll('-', ' ');
    }
    if (p.contains('cash')) return 'Cash on delivery';
    return 'Payment';
  }

  bool get isCompleted =>
      statusKey.contains('completed') || statusKey.contains('delivered');

  bool get isCancelled => statusKey.contains('cancel');

  bool get canCancel =>
      !isCompleted &&
      !isCancelled &&
      (statusKey.contains('pending') ||
          statusKey.contains('processing') ||
          statusKey.isEmpty);

  bool get canRequestReturn => isCompleted && !isCancelled;

  bool get canUpdate =>
      !isCompleted &&
      !isCancelled &&
      (statusKey.contains('pending') || statusKey.contains('processing'));

  int get resolvedItemsCount =>
      itemsCount ??
      items.fold<int>(0, (s, e) => s + e.quantity);

  double get resolvedDiscount {
    final d = (discount ?? 0) + (couponDiscount ?? 0);
    if (d > 0) return d;
    return items.fold<double>(0, (s, e) => s + e.savedAmount);
  }

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
        title: 'Out for Delivery',
        subtitle: '',
        done: (out || delivered) && !cancelled,
      ),
      OrderTimelineStep(
        title: 'Delivered',
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
      if ((map['name'] ?? map['customer_name']) != null)
        '${map['name'] ?? map['customer_name']}',
      if (map['phone'] != null) '${map['phone']}',
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
        json['order_status_timeline'];
    if (rawTimeline is List) {
      for (final e in rawTimeline) {
        if (e is Map) {
          steps.add(OrderTimelineStep.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    } else if (rawTimeline is Map) {
      for (final entry in rawTimeline.entries) {
        if (entry.value != null) {
          steps.add(OrderTimelineStep(
            title: entry.key.toString().replaceAll('_', ' '),
            subtitle: entry.value.toString(),
            done: true,
          ));
        }
      }
    }

    final id = json['id']?.toString() ??
        json['order_id']?.toString() ??
        json['tracking_number']?.toString() ??
        '';

    Map<String, dynamic>? asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

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
    if (product is Map) {
      name = product['name']?.toString();
      image = MediaImage.fromJson(product['image']);
      regular = ProductModel.asDouble(product['price']);
    }
    if ((name == null || name.isEmpty) && snapshot is Map) {
      name = snapshot['name']?.toString();
      image ??= MediaImage.fromJson(snapshot['image']);
      regular ??= ProductModel.asDouble(snapshot['price']);
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
    this.image,
    this.link,
  });

  final int id;
  final String? title;
  final MediaImage? image;
  final String? link;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: UserModel._asInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString(),
      image: MediaImage.fromJson(json['image'] ?? json['banner']),
      link: json['link']?.toString() ?? json['url']?.toString(),
    );
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

/// Site options from `GET /settings` (free shipping, minimums, etc.).
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
  });

  final bool freeShipping;
  final double freeShippingAmount;
  final double minimumOrderAmount;
  final double maximumShippingAmountOff;
  final int? shippingClassId;
  final int? taxClassId;
  final String? siteTitle;
  final String? siteSubtitle;

  String get freeDeliveryAnnouncement {
    if (freeShipping && freeShippingAmount > 0) {
      final amt = freeShippingAmount == freeShippingAmount.roundToDouble()
          ? freeShippingAmount.toStringAsFixed(0)
          : freeShippingAmount.toStringAsFixed(2);
      return 'Free delivery on orders over Rs. $amt · Cash on delivery available';
    }
    return 'Cash on delivery available';
  }

  factory SiteSettingsModel.fromOptions(Map<String, dynamic> options) {
    bool asBool(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    int? asClassId(dynamic v) {
      if (v == null) return null;
      if (v is Map) {
        return UserModel._asInt(v['id']);
      }
      return UserModel._asInt(v);
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
    );
  }
}
