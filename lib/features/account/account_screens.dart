import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final darkModeOn = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: auth.when(
        data: (user) {
          if (user == null) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: p.tealSoft,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 36,
                          color: p.teal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sign in to manage your account',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Orders, addresses, wishlist and more await.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          color: p.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      BrandGradientButton(
                        label: 'Sign In',
                        onPressed: () => context.push(AppRoutes.login),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: p.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final initial = (user.name ?? 'U').trim().isEmpty
              ? 'U'
              : (user.name!.trim())[0].toUpperCase();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  name: user.name ?? 'Customer',
                  phone: user.phoneNo ?? '+92 —',
                  email: user.email ?? '',
                  initial: initial,
                  onEditAvatar: () => context.push(AppRoutes.editProfile),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Column(
                    children: [
                      FigmaSectionCard(
                        title: 'ACCOUNT',
                        children: [
                          FigmaSettingsTile(
                            icon: Icons.person_outline,
                            label: 'Edit Profile',
                            onTap: () => context.push(AppRoutes.editProfile),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.lock_outline,
                            label: 'Change Password',
                            onTap: () =>
                                context.push(AppRoutes.editProfileTab(1)),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.location_on_outlined,
                            label: 'My Addresses',
                            onTap: () =>
                                context.push(AppRoutes.editProfileTab(2)),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.credit_card_outlined,
                            label: 'Payment Methods',
                            showDivider: false,
                            onTap: () => context.push(AppRoutes.payment),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FigmaSectionCard(
                        title: 'ORDERS',
                        children: [
                          FigmaSettingsTile(
                            icon: Icons.receipt_long_outlined,
                            label: 'Order History',
                            onTap: () => context.go(AppRoutes.orders),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.favorite_border,
                            label: 'My Wishlist',
                            onTap: () => context.push(AppRoutes.wishlist),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.replay_outlined,
                            label: 'Return & Refund',
                            onTap: () => context.push(AppRoutes.returns),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Wallet',
                            onTap: () => context.push(AppRoutes.wallet),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.local_shipping_outlined,
                            label: 'Track My Order',
                            showDivider: false,
                            onTap: () => context.push(AppRoutes.track('GT-88421')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FigmaSectionCard(
                        title: 'Seller',
                        children: [
                          FigmaSettingsTile(
                            icon: Icons.storefront_outlined,
                            label: 'Become a Seller',
                            showDivider: false,
                            onTap: () => context.push(AppRoutes.seller),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FigmaSectionCard(
                        title: 'PREFERENCES',
                        children: [
                          FigmaSettingsTile(
                            icon: Icons.notifications_none,
                            label: 'Notifications',
                            trailing: Switch.adaptive(
                              value: _notificationsOn,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) => setState(() => _notificationsOn = v),
                            ),
                            onTap: () => context.push(AppRoutes.notifications),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.dark_mode_outlined,
                            label: 'Dark Mode',
                            showDivider: false,
                            trailing: Switch.adaptive(
                              value: darkModeOn,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) =>
                                  ref.read(themeModeProvider.notifier).setDark(v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FigmaSectionCard(
                        title: 'SUPPORT',
                        children: [
                          FigmaSettingsTile(
                            icon: Icons.help_outline,
                            label: 'Help Center',
                            onTap: () => context.push(AppRoutes.info),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.star_outline,
                            label: 'Rate Gher Tak',
                            showDivider: false,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thanks for supporting Gher Tak!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: p.card,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              await ref.read(authStateProvider.notifier).logout();
                              if (context.mounted) context.go(AppRoutes.home);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.errorSoft),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 37,
                                    height: 37,
                                    decoration: BoxDecoration(
                                      color: AppColors.errorSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.logout,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign Out',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.email,
    required this.initial,
    required this.onEditAvatar,
  });

  final String name;
  final String phone;
  final String email;
  final String initial;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final radius = BrandHeaderShapeClipper.radiusForWidth(
      MediaQuery.sizeOf(context).width,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, radius + 8),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onEditAvatar,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: Icon(
                                Icons.edit,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          email,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _stat('23', 'Orders'),
                    _divider(),
                    _stat('3', 'Saved'),
                    _divider(),
                    _stat('Rs 2,500', 'Saved'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 42,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(
          'Menu',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppColors.primary),
                  title: Text(
                    user?.name ?? 'Sign in / Register',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () => context.push(
                    user == null ? AppRoutes.login : AppRoutes.profile,
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: AppColors.primary),
                  title: Text('Home', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  onTap: () => context.go(AppRoutes.home),
                ),
                ListTile(
                  leading: const Icon(Icons.grid_view_outlined, color: AppColors.primary),
                  title: Text('Shop', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  onTap: () => context.go(AppRoutes.categories),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                  title: Text('My orders', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  onTap: () => context.go(AppRoutes.orders),
                ),
                ListTile(
                  leading: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
                  title: Text('Offers', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  onTap: () => context.push(AppRoutes.productsQuery(endpoint: 'sales')),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.primary),
                  title: Text('About Us', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  onTap: () => context.push(AppRoutes.about),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline, color: AppColors.primary),
                  title: Text('Contact Us', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  onTap: () => context.push(AppRoutes.contact),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.primary),
                  title: Text('FAQ', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  onTap: () => context.push(AppRoutes.faq),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                  title: Text('Terms & Privacy', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  onTap: () => context.push(AppRoutes.info),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

/// Shop tab — aligned to Figma Shop (310:647): search, chips, product grid.
class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int _chipIndex = 0;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final products = ref.watch(offersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  FigmaBackButton(
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onSubmitted: (q) {
                        if (q.trim().isEmpty) return;
                        context.push(AppRoutes.productsQuery(search: q.trim()));
                      },
                      decoration: InputDecoration(
                        hintText: 'Search All...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0F2F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: cats.when(
                data: (list) {
                  final chips = <(String, IconData?)>[
                    ('All', Icons.shopping_bag_outlined),
                    ...list.take(8).map((c) => (c.name, null as IconData?)),
                  ];
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: chips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final active = i == _chipIndex;
                      final (label, icon) = chips[i];
                      return ChoiceChip(
                        selected: active,
                        showCheckmark: false,
                        avatar: icon == null
                            ? null
                            : Icon(
                                icon,
                                size: 16,
                                color: active ? Colors.white : AppColors.textSecondary,
                              ),
                        label: Text(label),
                        labelStyle: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: active ? Colors.white : AppColors.textPrimary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                        onSelected: (_) {
                          setState(() => _chipIndex = i);
                          if (i == 0) return;
                          final cat = list[i - 1];
                          context.push(
                            AppRoutes.productsQuery(categoryId: cat.id),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: products.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No products yet',
                        style: GoogleFonts.manrope(color: AppColors.textMuted),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => ProductCard(
                      product: list[i],
                      onTap: () => context.push(
                        AppRoutes.product('${list[i].id}'),
                      ),
                      onAdd: () => ref
                          .read(cartProvider.notifier)
                          .add(list[i]),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin fallback for routes not yet fully designed.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(title: title),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  subtitle ?? 'Coming soon.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _slot = 0;
  final Set<int> _noteChips = {};
  final _notes = TextEditingController();

  static const _slots = [
    ('Today', '60 min delivery ⚡'),
    ('Tomorrow', 'Morning slot'),
    ('Tomorrow', 'Evening slot'),
  ];

  static const _chipLabels = [
    (Icons.notifications_off_outlined, 'Do not ring the bell'),
    (Icons.door_front_door_outlined, 'Leave it at the door'),
    (Icons.phone_outlined, 'Call before delivery'),
    (Icons.inventory_2_outlined, 'Contains fragile items'),
  ];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider).valueOrNull ?? [];
    final itemsTotal = cart.fold<double>(
      0,
      (s, e) => s + e.product.displayPrice * e.quantity,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Checkout',
            onBack: () => context.pop(),
          ),
          const CheckoutStepper(activeStep: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _iconBadge(Icons.location_on_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Delivery Address',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.addresses),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Change',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Home 🏠',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '23-B, Model Town Extension, Block B,\nLahore, Punjab — 54700',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push(AppRoutes.addresses),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: Color(0xFFC8E6F5),
                            style: BorderStyle.solid,
                          ),
                          backgroundColor: const Color(0xFFF0F9FF),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '+ Add New Address',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _iconBadge(Icons.calendar_today_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Slot',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _slotChip(0)),
                          const SizedBox(width: 8),
                          Expanded(child: _slotChip(1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _slotChip(2, fullWidth: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _iconBadge(Icons.notes_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Order notes',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(optional)',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add delivery instructions, special requests or a gift message.',
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _chipLabels.length; i++)
                            _noteChip(i),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notes,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Leave at the door, call before delivery, gift wrap please…',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    children: [
                      _totalRow('Items', formatRs(itemsTotal)),
                      const SizedBox(height: 10),
                      _totalRow(
                        'Delivery',
                        'FREE',
                        valueColor: AppColors.successText,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),
                      Row(
                        children: [
                          Text(
                            'Total Payable',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatRs(itemsTotal),
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                BrandGradientButton(
                  label: 'Proceed to Payments',
                  onPressed: () => context.push(AppRoutes.payment),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: AppColors.primarySoftAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: AppColors.primary),
    );
  }

  Widget _slotChip(int index, {bool fullWidth = false}) {
    final selected = _slot == index;
    final slot = _slots[index];
    return GestureDetector(
      onTap: () => setState(() => _slot = index),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoftAlt : AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              slot.$1,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              slot.$2,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: selected ? AppColors.textSecondary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteChip(int index) {
    final selected = _noteChips.contains(index);
    final chip = _chipLabels[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _noteChips.remove(index);
          } else {
            _noteChips.add(index);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(9),
          border: selected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chip.$1,
              size: 16,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              chip.$2,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
