import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_fonts.dart';

import '../../constants/app_routes.dart';
import '../../core/location/delivery_location.dart';
import '../../core/location/delivery_location_provider.dart';
import '../../core/order/edit_order_session.dart';
import '../../core/pricing/delivery_pricing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../../data/models/models.dart';
import '../location/map_location_picker_screen.dart';
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
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Orders, addresses, wishlist and more await.',
                        textAlign: TextAlign.center,
                        style: AppFonts.style(
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
                          style: AppFonts.style(
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
                  avatarUrl: user.avatar,
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
                            onTap: () => context.push(AppRoutes.trackLookup),
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
                            icon: Icons.support_agent_outlined,
                            label: 'Customer Support',
                            onTap: () => context.push(AppRoutes.support),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.mail_outline,
                            label: 'Contact Us',
                            onTap: () => context.push(AppRoutes.contact),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.quiz_outlined,
                            label: 'FAQ',
                            onTap: () => context.push(AppRoutes.faq),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.groups_outlined,
                            label: 'Our Team',
                            onTap: () => context.push(AppRoutes.team),
                          ),
                          FigmaSettingsTile(
                            icon: Icons.map_outlined,
                            label: 'Sitemap',
                            onTap: () => context.push(AppRoutes.siteMap),
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
                                    style: AppFonts.style(
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

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.email,
    required this.initial,
    this.avatarUrl,
    required this.onEditAvatar,
  });

  final String name;
  final String phone;
  final String email;
  final String initial;
  final String? avatarUrl;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersCount =
        ref.watch(ordersProvider).valueOrNull?.length.toString() ?? '—';
    final wishlistCount =
        ref.watch(wishlistProvider).valueOrNull?.length.toString() ?? '—';
    final wallet = ref.watch(walletProvider).valueOrNull;
    final walletLabel = wallet == null
        ? '—'
        : 'Rs ${wallet.balance.toStringAsFixed(0)}';
    final avatar = resolveMediaUrl(avatarUrl);

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
                      ClipOval(
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 3,
                              ),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: avatar.isEmpty
                                    ? ColoredBox(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        child: Center(
                                          child: Text(
                                            initial,
                                            style: AppFonts.style(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: avatar,
                                        fit: BoxFit.cover,
                                        width: 64,
                                        height: 64,
                                        alignment: Alignment.center,
                                        memCacheWidth: 192,
                                        memCacheHeight: 192,
                                        fadeInDuration: Duration.zero,
                                        errorWidget: (_, __, ___) => Center(
                                          child: Text(
                                            initial,
                                            style: AppFonts.style(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        placeholder: (_, __) => Center(
                                          child: Text(
                                            initial,
                                            style: AppFonts.style(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
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
                          style: AppFonts.style(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: AppFonts.style(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          email,
                          style: AppFonts.style(
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
                    _stat(ordersCount, 'Orders'),
                    _divider(),
                    _stat(wishlistCount, 'Wishlist'),
                    _divider(),
                    _stat(walletLabel, 'Wallet'),
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
            style: AppFonts.style(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.style(
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
    final loggedIn = user != null;
    final initials = () {
      final n = (user?.name ?? '').trim();
      if (n.isEmpty) return 'GT';
      final parts = n.split(RegExp(r'\s+'));
      if (parts.length == 1) {
        return parts.first.substring(0, 1).toUpperCase();
      }
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }();

    final items = <({
      String name,
      IconData icon,
      String route,
      bool auth,
      bool go,
    })>[
      (
        name: 'My Orders',
        icon: Icons.shopping_bag_outlined,
        route: AppRoutes.orders,
        auth: true,
        go: true,
      ),
      (
        name: 'Wishlist',
        icon: Icons.favorite_border,
        route: AppRoutes.wishlist,
        auth: true,
        go: false,
      ),
      (
        name: 'Notifications',
        icon: Icons.notifications_none,
        route: AppRoutes.notifications,
        auth: true,
        go: false,
      ),
      (
        name: 'Track My Order',
        icon: Icons.location_on_outlined,
        route: AppRoutes.trackLookup,
        auth: false,
        go: false,
      ),
      (
        name: 'Wallet',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.wallet,
        auth: true,
        go: false,
      ),
      (
        name: 'Offers',
        icon: Icons.local_offer_outlined,
        route: AppRoutes.productsQuery(endpoint: 'sales'),
        auth: false,
        go: false,
      ),
      (
        name: 'Trending',
        icon: Icons.trending_up,
        route: AppRoutes.productsQuery(endpoint: 'trending'),
        auth: false,
        go: false,
      ),
      (
        name: 'New Arrivals',
        icon: Icons.auto_awesome_outlined,
        route: AppRoutes.productsQuery(endpoint: 'new-arrivals'),
        auth: false,
        go: false,
      ),
      (
        name: 'About Us',
        icon: Icons.info_outline,
        route: AppRoutes.about,
        auth: false,
        go: false,
      ),
      (
        name: 'Contact Us',
        icon: Icons.phone_outlined,
        route: AppRoutes.contact,
        auth: false,
        go: false,
      ),
      (
        name: 'FAQ',
        icon: Icons.help_outline,
        route: AppRoutes.faq,
        auth: false,
        go: false,
      ),
      (
        name: 'Terms & Privacy',
        icon: Icons.description_outlined,
        route: AppRoutes.info,
        auth: false,
        go: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      appBar: AppBar(
        backgroundColor: AppPalette.of(context).surface,
        elevation: 0,
        title: Text(
          'Menu',
          style: AppFonts.style(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppPalette.of(context).textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(
                    initials,
                    style: AppFonts.style(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3B6EA8),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loggedIn ? (user.name ?? 'Account') : 'Welcome',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      InkWell(
                        onTap: () => context.push(
                          loggedIn ? AppRoutes.profile : AppRoutes.login,
                        ),
                        child: Text(
                          loggedIn ? 'View profile' : 'Sign in',
                          style: AppFonts.style(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.tealMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 4),
          for (final item in items)
            ListTile(
              leading: Icon(item.icon, color: AppColors.textSecondary),
              title: Text(
                item.name,
                style: AppFonts.style(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () {
                if (item.auth && !loggedIn) {
                  context.push(AppRoutes.login);
                  return;
                }
                if (item.go) {
                  context.go(item.route);
                } else {
                  context.push(item.route);
                }
              },
            ),
          if (loggedIn) ...[
            Divider(height: 1, color: AppColors.borderLight),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFE25C2A)),
              title: Text(
                'Logout',
                style: AppFonts.style(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: const Color(0xFFE25C2A),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.home);
              },
            ),
          ],
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
      backgroundColor: AppPalette.of(context).background,
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
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.inputFill,
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
                        labelStyle: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: active
                              ? Colors.white
                              : AppPalette.of(context).textPrimary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppPalette.of(context).surface,
                        side: BorderSide(
                          color: active
                              ? AppColors.primary
                              : AppPalette.of(context).border,
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
                        style: AppFonts.style(color: AppColors.textMuted),
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
      backgroundColor: AppPalette.of(context).background,
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
                  style: AppFonts.style(color: AppColors.textSecondary),
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
  /// 0 = Today … 3 = Today+3. Default tomorrow like website.
  int _dateIndex = 1;
  DateTime? _customDate;
  int? _timeIndex = 0;
  int? _selectedAddressId;
  final Set<int> _noteChips = {};
  final _notes = TextEditingController();
  final _guestName = TextEditingController();
  final _guestPhone = TextEditingController();
  final _guestEmail = TextEditingController();

  /// Website `getQuickDeliveryDates` — Today + next 3 days.
  List<DateTime> get _quickDates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(4, (i) => today.add(Duration(days: i)));
  }

  DateTime get _selectedDate {
    if (_customDate != null) return _customDate!;
    final dates = _quickDates;
    return dates[_dateIndex.clamp(0, dates.length - 1)];
  }

  bool get _isTodaySelected {
    final today = _quickDates.first;
    final selected = _selectedDate;
    return selected.year == today.year &&
        selected.month == today.month &&
        selected.day == today.day;
  }

  bool get _isCustomDateSelected {
    final custom = _customDate;
    if (custom == null) return false;
    return !_quickDates.any(
      (d) =>
          d.year == custom.year &&
          d.month == custom.month &&
          d.day == custom.day,
    );
  }

  static const _chipLabels = [
    (Icons.notifications_off_outlined, 'Do not ring the bell'),
    (Icons.door_front_door_outlined, 'Leave it at the door'),
    (Icons.phone_outlined, 'Call on arrival'),
    (Icons.inventory_2_outlined, 'Contains fragile items'),
  ];

  void _selectQuickDate(int index) {
    setState(() {
      _dateIndex = index;
      _customDate = null;
      if (index == 0) {
        _timeIndex = null; // same-day slots fully booked
      } else {
        _timeIndex ??= 0;
      }
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.checkoutConfirm,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    final day = DateTime(picked.year, picked.month, picked.day);
    final quickIndex = _quickDates.indexWhere(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
    setState(() {
      if (quickIndex >= 0) {
        _dateIndex = quickIndex;
        _customDate = null;
        if (quickIndex == 0) {
          _timeIndex = null;
        } else {
          _timeIndex ??= 0;
        }
      } else {
        _customDate = day;
        _timeIndex ??= 0;
      }
    });
  }

  /// Website `PriorityPlanDialog` — toast + close only (no slot unlock / API).
  Future<void> _showPriorityPlanSheet() async {
    var yearly = false;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            const monthly = 499;
            const yearlyAmt = 3999;
            final save = monthly * 12 - yearlyAmt;
            final priceLabel = yearly
                ? 'PKR ${_formatPkr(yearlyAmt)}/year'
                : 'PKR ${_formatPkr(monthly)}/month';
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14181F).withValues(alpha: 0.18),
                      blurRadius: 48,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      decoration: const BoxDecoration(
                        gradient: AppColors.buttonGradient,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'GherTak Priority',
                              style: AppFonts.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(ctx),
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: Column(
                        children: [
                          Text(
                            'Choose a Plan',
                            textAlign: TextAlign.center,
                            style: AppFonts.style(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Auto renews · Cancel anytime',
                            textAlign: TextAlign.center,
                            style: AppFonts.style(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF3F6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _planCycleChip(
                                      label: 'Monthly',
                                      selected: !yearly,
                                      onTap: () =>
                                          setModal(() => yearly = false),
                                    ),
                                  ),
                                  Expanded(
                                    child: _planCycleChip(
                                      label: 'Yearly',
                                      selected: yearly,
                                      onTap: () =>
                                          setModal(() => yearly = true),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: yearly ? 10 : 0,
                                        right: yearly ? 72 : 0,
                                        left: yearly ? 72 : 0,
                                      ),
                                      child: Text(
                                        priceLabel,
                                        textAlign: TextAlign.center,
                                        style: AppFonts.style(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (yearly)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE7F6EE),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'Save Rs. ${_formatPkr(save)}',
                                            style: AppFonts.style(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF15824B),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.buttonGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          showAppToast(
                                            context,
                                            yearly
                                                ? 'Solo yearly plan selected'
                                                : 'Solo monthly plan selected',
                                            isError: false,
                                          );
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Subscribe Now',
                                              style: AppFonts.style(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatPkr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  Widget _planCycleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.checkoutConfirm : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: AppFonts.style(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    _guestName.dispose();
    _guestPhone.dispose();
    _guestEmail.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(editOrderSessionProvider);
      if (session?.orderNotes != null && session!.orderNotes!.isNotEmpty) {
        _notes.text = session.orderNotes!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider).valueOrNull ?? [];
    final editSession = ref.watch(editOrderSessionProvider);
    final itemsTotal = cart.fold<double>(
      0,
      (s, e) => s + e.product.displayPrice * e.quantity,
    );
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: editSession != null ? 'Update order' : 'Checkout',
            onBack: () => context.pop(),
          ),
          if (editSession != null)
            Material(
              color: const Color(0xFFE1F0F3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF11788C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Updating ${editSession.trackingNumber}',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF11788C),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(editOrderSessionProvider.notifier).clear();
                        await ref.read(cartProvider.notifier).clear();
                        if (!context.mounted) return;
                        showAppToast(
                          context,
                          'Edit cancelled. You are back to normal shopping.',
                          isError: false,
                        );
                        context.go(AppRoutes.home);
                      },
                      child: Text(
                        'Cancel',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const CheckoutStepper(activeStep: 2),
          FreeDeliveryBar(
            subtotal: itemsTotal,
            threshold: settings?.freeShippingAmount ?? 0,
            enabled: settings?.freeShipping == true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              physics: const ClampingScrollPhysics(),
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
                              'Drop-off address',
                              style: AppFonts.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _changeDeliveryPlace(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Change',
                              style: AppFonts.style(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildAddressPicker(ref),
                      if (ref.watch(authStateProvider).valueOrNull == null) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Contact for delivery',
                          style: AppFonts.style(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _guestName,
                          decoration: const InputDecoration(
                            hintText: 'Full name',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _guestPhone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '03XXXXXXXXX',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _guestEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email (optional)',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Delivery place is used for this order only — not saved to an account.',
                          style: AppFonts.style(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ] else ...[
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
                            style: AppFonts.style(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
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
                            'Schedule',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose a delivery date',
                        style: AppFonts.style(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var i = 0; i < _quickDates.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(child: _dateChip(i)),
                          ],
                          const SizedBox(width: 6),
                          Expanded(child: _selectDateChip()),
                        ],
                      ),
                      if (_isTodaySelected) ...[
                        const SizedBox(height: 14),
                        _priorityBanner(),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Delivery time slot',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final times = ref
                                  .watch(settingsProvider)
                                  .valueOrNull
                                  ?.deliveryTimes ??
                              DeliveryTimeSlot.defaults;
                          if (_isTodaySelected) {
                            return Column(
                              children: [
                                for (var i = 0; i < times.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 8),
                                  _fullyBookedSlot(times[i]),
                                ],
                              ],
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < times.length; i++) ...[
                                if (i > 0) const SizedBox(height: 8),
                                _timeSlotRow(i, times[i]),
                              ],
                            ],
                          );
                        },
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
                          _iconBadge(Icons.notes_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Order notes',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(optional)',
                            style: AppFonts.style(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add drop-off notes, special requests or a gift message.',
                        style: AppFonts.style(
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
                              'e.g. Leave at the door, call on arrival, gift wrap please…',
                          hintStyle: AppFonts.style(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(color: AppColors.border),
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
                      ..._checkoutDeliveryRows(itemsTotal),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),
                      Row(
                        children: [
                          Text(
                            'Total Payable',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatRs(
                              itemsTotal + _checkoutQuote(itemsTotal).fee,
                            ),
                            style: AppFonts.style(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      ..._checkoutFreeShipHint(itemsTotal),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                BrandGradientButton(
                  label: ref.watch(editOrderSessionProvider) != null
                      ? 'Continue to update'
                      : 'Proceed to Payments',
                  onPressed: () => _proceedToPayment(ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _changeDeliveryPlace() async {
    final loggedIn = ref.read(authStateProvider).valueOrNull != null;
    if (loggedIn) {
      context.push(AppRoutes.addresses);
      return;
    }
    final current = ref.read(deliveryLocationProvider).valueOrNull;
    final result = await Navigator.of(context).push<MapPickResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialLat: current?.lat,
          initialLng: current?.lng,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final loc = DeliveryLocation(
      label: result.label ??
          [
            if ((result.street ?? '').isNotEmpty) result.street,
            if ((result.city ?? '').isNotEmpty) result.city,
          ].whereType<String>().join(', '),
      lat: result.lat,
      lng: result.lng,
      hasGps: true,
      street: result.street,
      city: result.city,
    );
    // Session / local only — do not POST to address API for guests.
    ref.read(deliveryLocationOverrideProvider.notifier).state = loc;
    await persistDeliveryLocation(loc);
    ref.read(needsDeliveryGateProvider.notifier).state = false;
    ref.invalidate(deliveryLocationProvider);
    if (mounted) {
      showAppToast(context, 'Delivery place updated', isError: false);
      setState(() {});
    }
  }

  Widget _buildAddressPicker(WidgetRef ref) {
    final loggedIn = ref.watch(authStateProvider).valueOrNull != null;
    if (!loggedIn) {
      final locAsync = ref.watch(deliveryLocationProvider);
      return locAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => _guestDeliveryCard(DeliveryLocation.fallback),
        data: _guestDeliveryCard,
      );
    }

    final addressesAsync = ref.watch(addressesProvider);
    return addressesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(
        friendlyUserMessage(e),
        style: AppFonts.style(color: AppColors.error, fontSize: 12),
      ),
      data: (addresses) {
        if (addresses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No saved addresses. Add one to continue.',
              style: AppFonts.style(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        final defaults = addresses.where((a) => a.isDefault).toList();
        final selectedId = _selectedAddressId ??
            (defaults.isNotEmpty ? defaults.first.id : addresses.first.id);
        if (_selectedAddressId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedAddressId = selectedId);
          });
        }
        return Column(
          children: [
            for (final a in addresses) ...[
              InkWell(
                onTap: () => setState(() => _selectedAddressId = a.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedId == a.id
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedId == a.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: AppFonts.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.lineSummary.isEmpty
                                  ? 'Incomplete address'
                                  : a.lineSummary,
                              style: AppFonts.style(
                                fontSize: 12,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _guestDeliveryCard(DeliveryLocation loc) {
    final line = [
      if ((loc.street ?? '').trim().isNotEmpty) loc.street!.trim(),
      if ((loc.city ?? '').trim().isNotEmpty) loc.city!.trim(),
    ].join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  line.isNotEmpty ? line : loc.label,
                  style: AppFonts.style(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DeliveryQuote _checkoutQuote(double subtotal) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final shipping = ref.watch(shippingClassProvider).valueOrNull;
    return quoteDelivery(
      subtotal: subtotal,
      settings: settings,
      baseShippingAmount: shipping?.amount ?? 0,
      shippingType: shipping?.type ?? 'fixed',
    );
  }

  List<Widget> _checkoutDeliveryRows(double subtotal) {
    final shippingAsync = ref.watch(shippingClassProvider);
    if (shippingAsync.isLoading) {
      return [_totalRow('Fulfillment', '…')];
    }
    final q = _checkoutQuote(subtotal);
    if (q.baseFee <= 0 && shippingAsync.valueOrNull == null) {
      return [_totalRow('Fulfillment', '—')];
    }
    if (q.isFree) {
      return [
        _totalRow(
          'Fulfillment',
          'COMPLIMENTARY',
          valueColor: AppColors.successText,
        ),
      ];
    }
    return [
      _totalRow('Fulfillment', formatRs(q.fee)),
    ];
  }

  List<Widget> _checkoutFreeShipHint(double subtotal) {
    final q = _checkoutQuote(subtotal);
    if (!q.freeShippingEnabled || q.threshold <= 0) return const [];
    if (subtotal >= q.threshold) {
      return [
        const SizedBox(height: 10),
        Text(
          'Your order qualifies for complimentary fulfillment!',
          style: AppFonts.style(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.successText,
          ),
        ),
      ];
    }
    final need = q.threshold - subtotal;
    return [
      const SizedBox(height: 10),
      Text(
        'Add ${formatRs(need)} more for complimentary fulfillment',
        style: AppFonts.style(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          height: 1.35,
        ),
      ),
    ];
  }

  void _proceedToPayment(WidgetRef ref) {
    final user = ref.read(authStateProvider).valueOrNull;
    final loggedIn = user != null;

    late final Map<String, dynamic> shipping;
    String? addressTitle;
    int? addressId;
    late final String phone;

    if (!loggedIn) {
      final name = _guestName.text.trim();
      phone = _guestPhone.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
      if (name.isEmpty) {
        showAppToast(context, 'Please enter your name');
        return;
      }
      if (phone.length < 10) {
        showAppToast(context, 'Please enter a valid phone number');
        return;
      }
      final loc = ref.read(deliveryLocationProvider).valueOrNull ??
          DeliveryLocation.fallback;
      if (loc.lat == null || loc.lng == null) {
        showAppToast(context, 'Please set a delivery place on the map');
        return;
      }
      shipping = {
        'name': name,
        'phone': phone,
        if (_guestEmail.text.trim().isNotEmpty)
          'email': _guestEmail.text.trim(),
        'street': (loc.street ?? '').isNotEmpty ? loc.street : loc.label,
        'city': loc.city ?? 'Islamabad',
        'state': 'Islamabad Capital Territory',
        'country': 'Pakistan',
        'title': 'Delivery',
        'location': {'lat': loc.lat, 'lng': loc.lng},
      };
      addressTitle = 'Delivery';
    } else {
      final addresses = ref.read(addressesProvider).valueOrNull ?? [];
      if (addresses.isEmpty) {
        showAppToast(context, 'Please add an address first');
        context.push(AppRoutes.addresses);
        return;
      }
      final defaults = addresses.where((a) => a.isDefault).toList();
      final id = _selectedAddressId ??
          (defaults.isNotEmpty ? defaults.first.id : addresses.first.id);
      final address = addresses.firstWhere((a) => a.id == id);
      if ((address.street ?? '').isEmpty || (address.city ?? '').isEmpty) {
        showAppToast(context, 'Selected address is incomplete');
        return;
      }
      if (address.lat == null || address.lng == null) {
        showAppToast(context, 'Set a map pin for this address');
        return;
      }
      phone = (address.phone?.isNotEmpty == true)
          ? address.phone!
          : (user.phoneNo ?? '');
      if (phone.trim().isEmpty) {
        showAppToast(
          context,
          'Add a phone number to your profile or address',
        );
        return;
      }
      shipping = address.toShippingPayload(
        customerName: user.name ?? 'Customer',
        customerPhone: phone,
      );
      addressTitle = address.title;
      addressId = address.id;
    }

    final chipNotes = _noteChips.map((i) => _chipLabels[i].$2).join('; ');
    final notes = [
      if (chipNotes.isNotEmpty) chipNotes,
      if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
    ].join(' · ');

    if (_isTodaySelected) {
      showAppToast(
        context,
        "Today's slots are fully booked. Pick another date, or join Gher Tak Premium.",
      );
      return;
    }
    final times = ref.read(settingsProvider).valueOrNull?.deliveryTimes ??
        DeliveryTimeSlot.defaults;
    if (_timeIndex == null ||
        _timeIndex! < 0 ||
        _timeIndex! >= times.length) {
      showAppToast(context, 'Please select a delivery time slot');
      return;
    }
    final date = _selectedDate;
    final time = times[_timeIndex!];
    final weekday = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][date.weekday - 1];
    final month = const [
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
    ][date.month - 1];
    final deliveryTime = '$weekday ${date.day} $month · ${time.label}';

    ref.read(checkoutDraftProvider.notifier).state = CheckoutDraft(
      shippingAddress: shipping,
      deliveryTime: deliveryTime,
      orderNotes: notes.isEmpty ? null : notes,
      addressTitle: addressTitle,
      addressId: addressId,
    );
    context.push(AppRoutes.payment);
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

  Widget _dateChip(int index) {
    final date = _quickDates[index];
    final isToday = index == 0;
    final selected = !_isCustomDateSelected &&
        date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    final weekday = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][date.weekday - 1];
    final month = const [
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
    ][date.month - 1];
    return GestureDetector(
      onTap: () => _selectQuickDate(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.checkoutConfirm : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              isToday ? 'TODAY' : weekday.toUpperCase(),
              style: AppFonts.style(
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
                letterSpacing: 0.4,
                color: selected
                    ? AppColors.checkoutConfirm
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${date.day}',
              style: AppFonts.style(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: selected
                    ? AppColors.checkoutConfirm
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              month,
              style: AppFonts.style(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: selected
                    ? AppColors.checkoutConfirm
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectDateChip() {
    final selected = _isCustomDateSelected;
    final date = _customDate;
    final weekday = date == null
        ? null
        : const [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun',
          ][date.weekday - 1];
    final month = date == null
        ? null
        : const [
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
          ][date.month - 1];
    return GestureDetector(
      onTap: _pickCustomDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.checkoutConfirm,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.checkoutConfirm,
            width: 1.5,
          ),
        ),
        child: selected && date != null
            ? Column(
                children: [
                  Text(
                    weekday!.toUpperCase(),
                    style: AppFonts.style(
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      letterSpacing: 0.4,
                      color: AppColors.checkoutConfirm,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${date.day}',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.checkoutConfirm,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    month!,
                    style: AppFonts.style(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: AppColors.checkoutConfirm,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _priorityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Gher Tak Priority',
                style: AppFonts.style(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Skip the queue on every order',
            style: AppFonts.style(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Today's slots are fully booked. Still need it today!",
            style: AppFonts.style(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: _showPriorityPlanSheet,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.checkoutConfirm,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Join Gher Tak Premium',
                style: AppFonts.style(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.checkoutConfirm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullyBookedSlot(DeliveryTimeSlot slot) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD7DCE3), width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  slot.label.replaceFirst(' - ', ' · '),
                  style: AppFonts.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9AA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 28,
          top: 0,
          bottom: 0,
          child: Center(
            child: Transform.rotate(
              angle: -0.32,
              child: Container(
                width: 108,
                padding: const EdgeInsets.symmetric(vertical: 3.5),
                color: const Color(0xFFE24B4B),
                child: Text(
                  'FULLY BOOKED',
                  textAlign: TextAlign.center,
                  style: AppFonts.style(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeSlotRow(int index, DeliveryTimeSlot slot) {
    final selected = _timeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _timeIndex = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F6F8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.checkoutConfirm : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.checkoutConfirm : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.checkoutConfirm
                      : const Color(0xFFD7DCE3),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                slot.label.replaceFirst(' - ', ' · '),
                style: AppFonts.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F0F4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Selected',
                  style: AppFonts.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.checkoutConfirm,
                  ),
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
              style: AppFonts.style(
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
          style: AppFonts.style(
            fontSize: AppFonts.body,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppFonts.style(
            fontWeight: FontWeight.w700,
            fontSize: AppFonts.body,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
