import '../models/models.dart';

/// Tested placeholder catalog / user / cart data.
/// Shaped like backend JSON so swapping to live APIs is a repository change only.
class MockData {
  MockData._();

  static const _img = 'https://picsum.photos/seed';

  static String productImage(int id) => '$_img/gt$id/1000';

  static final UserModel demoUser = UserModel(
    id: 1,
    name: 'Ahmed Khan',
    email: 'ahmed@example.com',
    phoneNo: '+92 300 1234567',
    avatar: '$_img/avatar1/200',
  );

  static final List<CategoryModel> categories = [
    CategoryModel(
      id: 1,
      name: 'Fresh Produce',
      slug: 'fresh-produce',
      image: MediaImage(original: '$_img/cat1/200', thumbnail: '$_img/cat1/200'),
      children: const [
        CategoryModel(id: 11, name: 'Fruits', slug: 'fruits'),
        CategoryModel(id: 12, name: 'Vegetables', slug: 'vegetables'),
      ],
    ),
    CategoryModel(
      id: 2,
      name: 'Dairy & Eggs',
      slug: 'dairy-eggs',
      image: MediaImage(original: '$_img/cat2/200', thumbnail: '$_img/cat2/200'),
    ),
    CategoryModel(
      id: 3,
      name: 'Beverages',
      slug: 'beverages',
      image: MediaImage(original: '$_img/cat3/200', thumbnail: '$_img/cat3/200'),
    ),
    CategoryModel(
      id: 4,
      name: 'Snacks',
      slug: 'snacks',
      image: MediaImage(original: '$_img/cat4/200', thumbnail: '$_img/cat4/200'),
    ),
    CategoryModel(
      id: 5,
      name: 'Household',
      slug: 'household',
      image: MediaImage(original: '$_img/cat5/200', thumbnail: '$_img/cat5/200'),
    ),
    CategoryModel(
      id: 6,
      name: 'Personal Care',
      slug: 'personal-care',
      image: MediaImage(original: '$_img/cat6/200', thumbnail: '$_img/cat6/200'),
    ),
  ];

  static final List<BannerModel> banners = [
    BannerModel(
      id: 1,
      title: 'Free delivery this week',
      image: MediaImage(original: '$_img/banner1/800/320'),
      link: '/products',
    ),
    BannerModel(
      id: 2,
      title: 'Pharmacy essentials',
      image: MediaImage(original: '$_img/banner2/800/320'),
      link: '/vertical/pharmacy',
    ),
    BannerModel(
      id: 3,
      title: 'Fresh bakery deals',
      image: MediaImage(original: '$_img/banner3/800/320'),
      link: '/vertical/bakery',
    ),
  ];

  static final List<ManufacturerModel> manufacturers = [
    ManufacturerModel(
      id: 1,
      name: 'Nestlé',
      slug: 'nestle',
      image: MediaImage(original: '$_img/mfg1/120'),
    ),
    ManufacturerModel(
      id: 2,
      name: 'Unilever',
      slug: 'unilever',
      image: MediaImage(original: '$_img/mfg2/120'),
    ),
    ManufacturerModel(
      id: 3,
      name: 'PepsiCo',
      slug: 'pepsico',
      image: MediaImage(original: '$_img/mfg3/120'),
    ),
    ManufacturerModel(
      id: 4,
      name: 'National',
      slug: 'national',
      image: MediaImage(original: '$_img/mfg4/120'),
    ),
  ];

  static List<ProductModel> get products {
    final names = [
      'Organic Bananas 1kg',
      'Fresh Milk 1L',
      'Brownmeal Bread',
      'Olive Oil 500ml',
      'Basmati Rice 5kg',
      'Green Tea 25 bags',
      'Honey 250g',
      'Tomato Ketchup 400g',
      'Dishwash Liquid 750ml',
      'Face Wash 100ml',
      'Paracetamol 500mg',
      'Vitamin C Tablets',
      'Croissant Pack',
      'Chocolate Cake Slice',
      'A4 Paper Ream',
      'Ballpoint Pens (12)',
    ];
    return List.generate(names.length, (i) {
      final id = i + 1;
      final price = 120.0 + (i * 37);
      final onSale = i % 3 == 0;
      return ProductModel(
        id: id,
        name: names[i],
        slug: names[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
        price: price,
        salePrice: onSale ? price * 0.85 : null,
        quantity: 20 + i,
        image: MediaImage(
          original: productImage(id),
          thumbnail: productImage(id),
        ),
        categoryId: (i % 6) + 1,
        shopId: 1,
        manufacturerId: (i % 4) + 1,
        rating: 3.5 + (i % 15) / 10,
        reviewCount: 12 + i * 3,
        description:
            '${names[i]} — quality product delivered to your door by Gher Tak. '
            'Fresh, verified, and ready for checkout with cash on delivery.',
      );
    });
  }

  static List<ProductModel> byEndpoint(String? endpoint, {String? vertical}) {
    final all = productsForVertical(vertical ?? 'grocery');
    if (endpoint == null || endpoint.contains('list')) return all;
    if (endpoint.contains('sales')) {
      return all.where((p) => p.hasDiscount).toList();
    }
    if (endpoint.contains('best-sellers')) {
      return all.take(8).toList();
    }
    if (endpoint.contains('limited')) {
      return all.skip(2).take(6).toList();
    }
    return all;
  }

  /// Vertical-specific catalog so Pharmacy / Bakery / Business feel distinct.
  static List<ProductModel> productsForVertical(String vertical) {
    final all = products;
    switch (vertical) {
      case 'pharmacy':
        return all
            .where((p) =>
                p.name.toLowerCase().contains('para') ||
                p.name.toLowerCase().contains('vitamin') ||
                p.name.toLowerCase().contains('face') ||
                p.id % 4 == 0)
            .map((p) => ProductModel(
                  id: p.id + 100,
                  name: p.name.contains('Paracetamol') ||
                          p.name.contains('Vitamin')
                      ? p.name
                      : 'Pharmacy · ${p.name}',
                  slug: 'pharm-${p.slug}',
                  price: p.price,
                  salePrice: p.salePrice,
                  quantity: p.quantity,
                  image: p.image,
                  categoryId: p.categoryId,
                  shopId: p.shopId,
                  manufacturerId: p.manufacturerId,
                  rating: p.rating,
                  reviewCount: p.reviewCount,
                  description: p.description,
                ))
            .toList();
      case 'bakery':
        return all
            .where((p) =>
                p.name.toLowerCase().contains('bread') ||
                p.name.toLowerCase().contains('croissant') ||
                p.name.toLowerCase().contains('cake') ||
                p.name.toLowerCase().contains('honey') ||
                p.id % 3 == 1)
            .map((p) => ProductModel(
                  id: p.id + 200,
                  name: p.name.toLowerCase().contains('bread') ||
                          p.name.toLowerCase().contains('cake') ||
                          p.name.toLowerCase().contains('croissant')
                      ? p.name
                      : 'Bakery · ${p.name}',
                  slug: 'bake-${p.slug}',
                  price: p.price,
                  salePrice: p.salePrice,
                  quantity: p.quantity,
                  image: p.image,
                  categoryId: p.categoryId,
                  shopId: p.shopId,
                  manufacturerId: p.manufacturerId,
                  rating: p.rating,
                  reviewCount: p.reviewCount,
                  description: p.description,
                ))
            .toList();
      case 'business':
        return all
            .where((p) =>
                p.name.toLowerCase().contains('paper') ||
                p.name.toLowerCase().contains('pen') ||
                p.name.toLowerCase().contains('oil') ||
                p.id % 3 == 2)
            .map((p) => ProductModel(
                  id: p.id + 300,
                  name: 'Business · ${p.name}',
                  slug: 'biz-${p.slug}',
                  price: p.price,
                  salePrice: p.salePrice,
                  quantity: p.quantity,
                  image: p.image,
                  categoryId: p.categoryId,
                  shopId: p.shopId,
                  manufacturerId: p.manufacturerId,
                  rating: p.rating,
                  reviewCount: p.reviewCount,
                  description: p.description,
                ))
            .toList();
      default:
        return all;
    }
  }

  static List<CategoryModel> categoriesForVertical(String vertical) {
    switch (vertical) {
      case 'pharmacy':
        return const [
          CategoryModel(id: 101, name: 'Medicines', slug: 'medicines'),
          CategoryModel(id: 102, name: 'Vitamins', slug: 'vitamins'),
          CategoryModel(id: 103, name: 'Personal Care', slug: 'personal-care'),
          CategoryModel(id: 104, name: 'First Aid', slug: 'first-aid'),
        ];
      case 'bakery':
        return const [
          CategoryModel(id: 201, name: 'Bread', slug: 'bread'),
          CategoryModel(id: 202, name: 'Cakes', slug: 'cakes'),
          CategoryModel(id: 203, name: 'Pastries', slug: 'pastries'),
          CategoryModel(id: 204, name: 'Cookies', slug: 'cookies'),
        ];
      case 'business':
        return const [
          CategoryModel(id: 301, name: 'Office Supplies', slug: 'office'),
          CategoryModel(id: 302, name: 'Bulk Grocery', slug: 'bulk'),
          CategoryModel(id: 303, name: 'Cleaning', slug: 'cleaning'),
          CategoryModel(id: 304, name: 'Pantry', slug: 'pantry'),
        ];
      default:
        return categories;
    }
  }

  static ProductModel? productByIdOrSlug(String idOrSlug) {
    final asInt = int.tryParse(idOrSlug);
    // Include remapped vertical catalogs (pharmacy +100 / bakery +200 / business +300).
    final catalog = <ProductModel>[
      ...products,
      ...productsForVertical('pharmacy'),
      ...productsForVertical('bakery'),
      ...productsForVertical('business'),
    ];
    for (final p in catalog) {
      if (asInt != null && p.id == asInt) return p;
      if (p.slug == idOrSlug) return p;
    }
    return null;
  }

  static List<ProductModel> search(String term) {
    final q = term.toLowerCase();
    return products
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  /// In-memory cart for mock mode (mutated by [MockCartStore]).
  static final List<CartItemModel> _cart = [];

  static List<CartItemModel> get cartItems => List.unmodifiable(_cart);

  static void cartClear() => _cart.clear();

  static void cartAdd({
    required int productId,
    required int shopId,
    int quantity = 1,
    int? variationOptionId,
    ProductModel? product,
  }) {
    final existing = _cart.indexWhere(
      (e) =>
          e.product.id == productId &&
          e.variationOptionId == variationOptionId,
    );
    if (existing >= 0) {
      final item = _cart[existing];
      _cart[existing] = CartItemModel(
        id: item.id,
        quantity: item.quantity + quantity,
        product: item.product,
        variationOptionId: variationOptionId,
      );
      return;
    }
    final resolved = product ?? productByIdOrSlug('$productId');
    if (resolved == null) {
      throw StateError('Product $productId not found');
    }
    _cart.add(
      CartItemModel(
        id: _cart.length + 1,
        quantity: quantity,
        product: resolved,
        variationOptionId: variationOptionId,
      ),
    );
  }

  static void cartUpdateQty(
    int productId,
    int quantity, {
    int? variationOptionId,
  }) {
    final i = _cart.indexWhere(
      (e) =>
          e.product.id == productId &&
          e.variationOptionId == variationOptionId,
    );
    if (i < 0) return;
    if (quantity <= 0) {
      _cart.removeAt(i);
      return;
    }
    final item = _cart[i];
    _cart[i] = CartItemModel(
      id: item.id,
      quantity: quantity,
      product: item.product,
      variationOptionId: variationOptionId,
    );
  }

  static void cartRemove(int productId, {int? variationOptionId}) {
    _cart.removeWhere(
      (e) =>
          e.product.id == productId &&
          e.variationOptionId == variationOptionId,
    );
  }

  static final List<Map<String, dynamic>> orders = [
    {
      'id': 'GT-10042',
      'status': 'out_for_delivery',
      'total': 1840.0,
      'placed_at': '2026-09-16T14:20:00',
      'items_count': 4,
    },
    {
      'id': 'GT-10031',
      'status': 'delivered',
      'total': 920.0,
      'placed_at': '2026-09-12T11:05:00',
      'items_count': 2,
    },
    {
      'id': 'GT-10018',
      'status': 'cancelled',
      'total': 450.0,
      'placed_at': '2026-09-08T09:40:00',
      'items_count': 1,
    },
  ];

  static final List<Map<String, dynamic>> addresses = [
    {
      'id': 1,
      'label': 'Home',
      'line1': '12 Gulberg III',
      'city': 'Lahore',
      'is_default': true,
    },
    {
      'id': 2,
      'label': 'Office',
      'line1': '88 MM Alam Road',
      'city': 'Lahore',
      'is_default': false,
    },
  ];

  static final List<Map<String, dynamic>> notifications = [
    {
      'id': 1,
      'title': 'Order on the way',
      'body': 'Your order GT-10042 is out for delivery.',
      'unread': true,
    },
    {
      'id': 2,
      'title': 'Weekend deal',
      'body': 'Save 15% on bakery items this weekend.',
      'unread': true,
    },
    {
      'id': 3,
      'title': 'Payment received',
      'body': 'We received payment for order GT-10031.',
      'unread': false,
    },
  ];

  static const double walletBalance = 1250.0;

  static final List<Map<String, dynamic>> walletTx = [
    {'id': 1, 'title': 'Cashback', 'amount': 50.0, 'type': 'credit'},
    {'id': 2, 'title': 'Order GT-10031', 'amount': -920.0, 'type': 'debit'},
    {'id': 3, 'title': 'Top-up', 'amount': 2000.0, 'type': 'credit'},
  ];
}
