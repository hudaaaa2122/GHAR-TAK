import '../core/config/app_config.dart';

/// User-facing copy centralized for easy i18n later.
class AppStrings {
  AppStrings._();

  static const String appName = AppConfig.appName;
  static const String tagline = AppConfig.tagline;

  static const String home = 'Home';
  static const String categories = 'Categories';
  static const String shop = 'Shop';
  static const String cart = 'Cart';
  static const String orders = 'Orders';
  static const String account = 'Account';
  static const String profile = 'Profile';

  static const String searchHint = 'Search products…';
  static const String addToCart = 'Add to Cart';
  static const String checkout = 'Checkout';
  static const String placeOrder = 'Place Order';
  static const String continueShopping = 'Continue Shopping';

  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String phone = 'Phone';
  static const String name = 'Full name';

  static const String myOrders = 'My Orders';
  static const String wishlist = 'Wishlist';
  static const String addresses = 'Addresses';
  static const String wallet = 'Wallet';
  static const String notifications = 'Notifications';
  static const String returns = 'Returns & Refunds';
  static const String editProfile = 'Edit Profile';
  static const String changePassword = 'Change Password';

  static const String emptyCart = 'Your cart is empty';
  static const String emptyWishlist = 'No saved items yet';
  static const String emptyOrders = 'No orders yet';
  static const String somethingWrong = 'Something went wrong';
  static const String tryAgain = 'Try again';
  static const String loading = 'Loading…';

  static const String grocery = 'Grocery';
  static const String pharmacy = 'Pharmacy';
  static const String bakery = 'Bakery';
  static const String business = 'Business';

  static const String trending = 'Trending Products';
  static const String deals = 'Deals';
  static const String bestSellers = 'Best Sellers';
  static const String limitedStock = 'Limited Stock';
  static const String offers = 'Offers';
}
