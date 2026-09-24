/// Backend path constants aligned with GherTak FastAPI (`GherTak-BackEnd-FastAPI`).
class ApiEndpoints {
  ApiEndpoints._();

  // —— Auth ——
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyRegistration = '/verify-registration-code';
  static const String resendVerification = '/resend-verification-code';
  static const String logout = '/logout';
  static const String refresh = '/refresh';
  static const String google = '/google';

  // —— User / password ——
  static const String userRead = '/user/read';
  static const String userProfile = '/user/profile';
  static const String userUpdate = '/user/update';
  static const String changePassword = '/user/change-password';
  static const String forgotPassword = '/user/forgot-password';
  static const String verifyResetCode = '/user/verify-code';
  static const String resetPassword = '/user/reset-password';

  // —— Catalog ——
  static const String productList = '/product/list';
  static const String productSales = '/product/sales';
  static const String productBestSellers = '/product/best-sellers';
  static const String productLimited = '/product/limited-edition';
  static const String productTrending = '/product/trending';
  static const String productNewArrivals = '/product/new-arrivals';
  static String productRead(String idOrSlug) => '/product/read/$idOrSlug';
  static const String categoryList = '/category/list';
  /// Website home “Shop by category” tiles (backend first-product image fallback).
  static const String categoryBrowseTiles = '/category/browse-tiles';
  static const String bannerList = '/banner/list';
  static const String manufacturerList = '/manufacturer/list';

  // —— Cart (customer) ——
  static const String cartMy = '/cart/my-cart';
  static const String cartAdd = '/cart/add';
  /// Website EditOrderDialog uses this to load order items into cart.
  static const String cartBulkCreate = '/cart/bulk-create';
  static String cartUpdate(int productId) => '/cart/update/$productId';
  static String cartRemove(int productId) => '/cart/remove/$productId';
  static const String cartDeleteAll = '/cart/delete-all';

  // —— Orders ——
  static const String orderCreateFromCart = '/order/create-from-cart';
  static const String orderCartCreate = '/order/cartcreate';
  /// Customer-scoped orders (website uses this / `/order/list`).
  static const String orderMyOrders = '/order/my-orders';
  static const String orderList = '/order/list';
  /// Admin/seller only — do not use for customers.
  static const String orderMyActive = '/order/my-not-completed';
  static const String orderMyCompleted = '/order/my-completed';
  static String orderRead(String id) => '/order/read/$id';
  static String orderTracking(String tracking) => '/order/tracking/$tracking';
  static String orderCancel(String id) => '/order/$id/cancel';
  static String orderCustomerEdit(String id) => '/order/$id/customer-edit';
  static String orderReviewByOrder(String orderId) =>
      '/order-review/order/$orderId';
  static const String orderReviewCreate = '/order-review/create';

  // —— Address ——
  static const String addressList = '/address/list';
  static const String addressCreate = '/address/create';
  static String addressUpdate(int id) => '/address/update/$id';
  static String addressDelete(int id) => '/address/delete/$id';
  static String addressRead(int id) => '/address/read/$id';

  // —— Delivery zones ——
  static const String deliveryZoneList = '/delivery-zone/list';
  static const String deliveryZoneCheck = '/delivery-zone/check';

  // —— Shipping / tax (site settings class ids) ——
  static String shippingRead(Object id) => '/shipping/read/$id';
  static String taxRead(Object id) => '/tax/read/$id';

  // —— Wishlist ——
  static const String wishlistMine = '/wishlist/my-wishlist';
  static const String wishlistAdd = '/wishlist/add';
  static String wishlistRemove(int id) => '/wishlist/remove/$id';
  static const String wishlistRemoveByProduct = '/wishlist/remove-by-product';
  static String wishlistCheck(int productId) =>
      '/wishlist/check/$productId';

  // —— Wallet ——
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';

  // —— Notifications ——
  static const String notificationList = '/notification/list';
  static const String notificationUnreadCount = '/notification/unread-count';
  static String notificationMarkRead(int id) =>
      '/notification/$id/mark-as-read';
  static const String notificationMarkAllRead = '/notification/mark-all-as-read';

  // —— Returns ——
  static const String returnsMine = '/returns/my-returns';
  static const String returnsRequest = '/returns/request';

  // —— Media ——
  static const String mediaCreate = '/media/create';

  // —— Payment ——
  static const String paymentGateways = '/payment/gateways';
  static String paymentInitiate(String orderId) =>
      '/payment/initiate/$orderId';

  // —— Coupon ——
  static String couponRedeem(String code) => '/coupon/redeem/$code';

  // —— Shop (become a seller) ——
  static const String shopCreate = '/shop/create';
  static const String shopMyShops = '/shop/my-shops';

  // —— Contact / support ——
  static const String contactSupport = '/contactus/support';

  // —— Settings ——
  static const String settings = '/settings';
}
