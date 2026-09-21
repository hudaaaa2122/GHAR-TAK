class MediaImage {
  const MediaImage({this.original, this.thumbnail});

  final String? original;
  final String? thumbnail;

  String? get best => thumbnail?.isNotEmpty == true
      ? thumbnail
      : (original?.isNotEmpty == true ? original : null);

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
    return ProductModel(
      id: UserModel._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      price: _asDouble(json['price']) ?? 0,
      salePrice: _asDouble(json['sale_price']),
      quantity: UserModel._asInt(json['quantity']),
      image: MediaImage.fromJson(json['image'] ?? json['gallery']?[0]),
      categoryId: UserModel._asInt(json['category_id']),
      shopId: UserModel._asInt(json['shop_id']),
      manufacturerId: UserModel._asInt(json['manufacturer_id']),
      rating: _asDouble(json['rating']),
      reviewCount: UserModel._asInt(json['review_count']),
      description: json['description']?.toString(),
    );
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
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
      image: MediaImage.fromJson(json['image']),
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
  });

  final int id;
  final int quantity;
  final ProductModel product;
  final int? variationOptionId;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productRaw = json['product'];
    return CartItemModel(
      id: UserModel._asInt(json['id']) ?? 0,
      quantity: UserModel._asInt(json['quantity']) ?? 1,
      variationOptionId: UserModel._asInt(json['variation_option_id']),
      product: productRaw is Map
          ? ProductModel.fromJson(Map<String, dynamic>.from(productRaw))
          : const ProductModel(
              id: 0,
              name: 'Unknown',
            ),
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
