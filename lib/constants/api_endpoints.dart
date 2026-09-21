/// Backend path constants. Repositories use these so API wiring stays one place.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyRegistration = '/verify-registration-code';
  static const String logout = '/logout';
  static const String refresh = '/refresh';
  static const String userRead = '/user/read';

  // Catalog
  static const String productList = '/product/list';
  static const String productSales = '/product/sales';
  static const String productBestSellers = '/product/best-sellers';
  static const String productLimited = '/product/limited-edition';
  static String productRead(String idOrSlug) => '/product/read/$idOrSlug';
  static const String categoryList = '/category/list';
  static const String bannerList = '/banner/list';
  static const String manufacturerList = '/manufacturer/list';

  // Cart
  static const String cartList = '/cart/list';
  static const String cartCreate = '/cart/create';
  static String cartUpdate(int productId) => '/cart/update/$productId';
  static String cartDelete(int productId) => '/cart/delete/$productId';

  // Orders (for later API phase)
  static const String orderList = '/order/list';
  static const String orderCreate = '/order/create';
  static String orderRead(String id) => '/order/read/$id';
}
