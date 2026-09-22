import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../constants/app_strings.dart';
import '../core/theme/vertical_theme.dart';
import '../features/account/account_screens.dart';
import '../features/account/figma_screens.dart';
import '../features/account/order_detail_screens.dart';
import '../features/auth/auth_screens.dart';
import '../features/auth/splash_intro_screens.dart';
import '../features/cart/cart_screen.dart';
import '../features/home/home_screen.dart';
import '../features/info/info_screens.dart';
import '../features/location/map_location_picker_screen.dart';
import '../features/product/product_detail_screen.dart';
import '../features/product/product_list_screen.dart';
import '../features/providers.dart';

/// Single source of navigation. All paths come from [AppRoutes].
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.intro,
        builder: (_, __) => const IntroScreen(),
      ),
      // Only mount the active tab — IndexedStack built all 5 on first Home open and froze emulators.
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return children[navigationShell.currentIndex];
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.categories,
                builder: (_, __) => const CategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (_, __) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, __) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => OrderDetailScreen(
                      orderId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (_, state) => ProductDetailScreen(
          idOrSlug: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return ProductListScreen(
            search: q['search'],
            barcode: q['barcode'],
            endpoint: q['endpoint'],
            categoryId: int.tryParse(q['categoryId'] ?? ''),
            manufacturerId: int.tryParse(q['manufacturerId'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verify,
        builder: (_, state) => VerifyScreen(
          email: (state.extra as String?) ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.menu,
        builder: (_, __) => const MenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (_, __) => const PaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        builder: (_, state) => OrderSuccessScreen(
          orderId: state.uri.queryParameters['orderId'],
          trackingId: state.uri.queryParameters['trackingId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.tracking,
        builder: (_, state) => TrackOrderScreen(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (_, __) => const WishlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (_, __) => const AddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.mapPicker,
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return MapLocationPickerScreen(
            initialLat: double.tryParse(q['lat'] ?? ''),
            initialLng: double.tryParse(q['lng'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return EditProfileScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.returns,
        builder: (_, __) => const ReturnsScreen(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (_, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'qr';
          return ScanScreen(mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.verticalHome,
        builder: (_, state) {
          final slug = state.pathParameters['slug'] ?? 'grocery';
          return HomeScreen(initialVertical: slug);
        },
      ),
      GoRoute(
        path: AppRoutes.seller,
        builder: (_, __) => const SellerScreen(),
      ),
      GoRoute(
        path: AppRoutes.info,
        builder: (_, __) => const HelpHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        builder: (_, __) => const ContactScreen(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        builder: (_, __) => const FaqScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, __) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, __) => const PrivacyScreen(),
      ),
    ],
  );
});

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(verticalThemeProvider);
    final cartCount = ref.watch(cartProvider).valueOrNull?.fold<int>(
              0,
              (s, e) => s + e.quantity,
            ) ??
        0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        indicatorColor: theme.primarySoft,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: theme.primary),
            label: AppStrings.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: theme.primary),
            label: AppStrings.shop,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: Icon(Icons.shopping_cart, color: theme.primary),
            ),
            label: AppStrings.cart,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: theme.primary),
            label: AppStrings.orders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: theme.primary),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
