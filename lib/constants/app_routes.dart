/// Central named routes for the entire app.
/// Screens must navigate via these constants — never hardcode path strings.
class AppRoutes {
  AppRoutes._();

  // —— Shell / tabs ——
  static const String home = '/';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String profile = '/profile';

  // —— Auth ——
  static const String splash = '/splash';
  static const String intro = '/intro';
  static const String login = '/login';
  static const String register = '/register';
  static const String verify = '/verify';
  static const String changePassword = '/change-password';

  // —— Catalog ——
  static const String search = '/search';
  static const String products = '/products';
  static const String productDetail = '/product/:id';
  static const String verticalHome = '/vertical/:slug';
  static const String scan = '/scan';

  // —— Checkout ——
  static const String checkout = '/checkout';
  static const String payment = '/payment';
  static const String orderSuccess = '/order-success';
  static const String orderSummary = '/order-summary';

  // —— Orders ——
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String tracking = '/tracking/:id';

  // —— Account ——
  static const String menu = '/menu';
  static const String editProfile = '/edit-profile';
  static const String addresses = '/addresses';
  static const String addressForm = '/addresses/form';
  static const String mapPicker = '/map-picker';
  static const String wishlist = '/wishlist';
  static const String wallet = '/wallet';
  static const String notifications = '/notifications';
  static const String returns = '/returns';
  static const String info = '/info';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String faq = '/faq';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String seller = '/seller';

  /// Build `/product/{idOrSlug}`.
  static String product(String idOrSlug) => '/product/$idOrSlug';

  /// Build `/orders/{id}`.
  static String order(String id) => '/orders/$id';

  /// Build `/tracking/{id}`.
  static String track(String id) => '/tracking/$id';

  /// Build `/vertical/{slug}` (grocery | pharmacy | bakery | business).
  static String vertical(String slug) => '/vertical/$slug';

  /// Build `/scan?mode=camera|qr`.
  static String scanMode(String mode) =>
      Uri(path: scan, queryParameters: {'mode': mode}).toString();

  /// Build `/order-success?orderId=&trackingId=`.
  static String orderSuccessWith({String? orderId, String? trackingId}) {
    final params = <String, String>{
      if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
      if (trackingId != null && trackingId.isNotEmpty) 'trackingId': trackingId,
    };
    if (params.isEmpty) return orderSuccess;
    return Uri(path: orderSuccess, queryParameters: params).toString();
  }

  /// Build `/edit-profile?tab=0|1|2` (Profile Info | Password | Addresses).
  static String editProfileTab(int tab) =>
      Uri(path: editProfile, queryParameters: {'tab': '$tab'}).toString();

  /// Product list with optional query params.
  static String productsQuery({
    String? search,
    String? barcode,
    String? endpoint,
    int? categoryId,
    int? manufacturerId,
  }) {
    final params = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
      if (endpoint != null && endpoint.isNotEmpty) 'endpoint': endpoint,
      if (categoryId != null) 'categoryId': '$categoryId',
      if (manufacturerId != null) 'manufacturerId': '$manufacturerId',
    };
    if (params.isEmpty) return products;
    return Uri(path: products, queryParameters: params).toString();
  }
}
