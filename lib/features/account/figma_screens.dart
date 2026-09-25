import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../core/invoice/invoice_pdf.dart';
import '../../core/location/delivery_location.dart';
import '../../core/location/delivery_location_provider.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/figma_chrome.dart';
import '../../shared/widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../location/map_location_picker_screen.dart';
import '../providers.dart';
import 'my_orders_screen.dart';

// PaymentScreen lives in features/payment/payment_screen.dart

// ─── Order Success ───────────────────────────────────────────────────────────

class OrderSuccessScreen extends ConsumerStatefulWidget {
  const OrderSuccessScreen({
    super.key,
    this.orderId,
    this.trackingId,
  });

  final String? orderId;
  final String? trackingId;

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> {
  bool _copied = false;
  bool _downloadingInvoice = false;

  Future<void> _copyTracking(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() => _copied = true);
    showAppToast(context, 'Tracking number copied', isError: false);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _downloadInvoice() async {
    final id = widget.orderId;
    if (id == null || id.isEmpty) {
      showAppToast(context, 'Order id missing for invoice');
      return;
    }
    if (_downloadingInvoice) return;
    setState(() => _downloadingInvoice = true);
    try {
      final order = await ref.read(orderRepositoryProvider).read(id);
      await shareOrderInvoicePdf(order);
      if (mounted) {
        showAppToast(context, 'Invoice ready to share', isError: false);
      }
    } catch (_) {
      if (mounted) showAppToast(context, 'Could not download invoice');
    } finally {
      if (mounted) setState(() => _downloadingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayId = widget.trackingId?.isNotEmpty == true
        ? widget.trackingId!
        : (widget.orderId ?? '—');
    final hasTracking = displayId != '—' && displayId.isNotEmpty;

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order confirmed!',
                style: AppFonts.style(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for your order. We\'ll send you updates as your items are prepared and delivered.',
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tracking number',
                      style: AppFonts.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayId,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppFonts.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.checkoutConfirm,
                            ),
                          ),
                        ),
                        if (hasTracking) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Copy tracking number',
                            onPressed: () => _copyTracking(displayId),
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.checkoutConfirm,
                              backgroundColor: _copied
                                  ? const Color(0xFFE8F5F7)
                                  : Colors.transparent,
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              _copied
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    if (widget.trackingId != null &&
                        widget.trackingId!.isNotEmpty) {
                      context.go(AppRoutes.track(widget.trackingId!));
                    } else if (widget.orderId != null &&
                        widget.orderId!.isNotEmpty) {
                      context.go(AppRoutes.order(widget.orderId!));
                    } else {
                      context.go(AppRoutes.orders);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.checkoutConfirm,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppFonts.style(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  child: const Text('Track your order'),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.orderId != null && widget.orderId!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _downloadingInvoice ? null : _downloadInvoice,
                  icon: _downloadingInvoice
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    _downloadingInvoice
                        ? 'Preparing invoice…'
                        : 'Download invoice PDF',
                    style: AppFonts.style(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (widget.orderId != null && widget.orderId!.isNotEmpty)
                const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue Shopping',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Orders ──────────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const MyOrdersScreen();
}

// ─── Order Details ───────────────────────────────────────────────────────────

// OrderDetailScreen moved to order_detail_screens.dart

// ─── Wishlist ────────────────────────────────────────────────────────────────

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.wishlist,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e is ApiException ? e.message : e.toString(),
                        textAlign: TextAlign.center,
                        style: AppFonts.style(color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(wishlistProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Your wishlist is empty',
                      style: AppFonts.style(fontWeight: FontWeight.w700),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(wishlistProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return InkWell(
                        onTap: () => context.push(AppRoutes.product('${p.id}')),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Icon(
                                    Icons.favorite,
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    size: 48,
                                  ),
                                ),
                              ),
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatRs(p.displayPrice),
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await ref
                                            .read(cartProvider.notifier)
                                            .add(p);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Added to cart'),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: Text(
                                        'Add',
                                        style: AppFonts.style(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(accountRepositoryProvider)
                                            .removeFromWishlist(p.id);
                                        ref.invalidate(wishlistProvider);
                                      } on ApiException catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(e.message)),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Profile (tabs: Info | Password | Addresses) ──────────────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _saving = false;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;

  final _addrLabel = TextEditingController();
  final _addrLine = TextEditingController();
  final _addrCity = TextEditingController();
  final _addrPhone = TextEditingController();
  double? _mapLat;
  double? _mapLng;
  String? _mapLabel;

  String? _avatarPath;

  Future<void> _pickOnMap() async {
    final q = <String, String>{
      if (_mapLat != null) 'lat': '${_mapLat}',
      if (_mapLng != null) 'lng': '${_mapLng}',
    };
    final uri = q.isEmpty
        ? AppRoutes.mapPicker
        : Uri(path: AppRoutes.mapPicker, queryParameters: q).toString();
    final result = await context.push<MapPickResult>(uri);
    if (!mounted || result == null) return;
    setState(() {
      _mapLat = result.lat;
      _mapLng = result.lng;
      _mapLabel = result.label;
      if ((result.street ?? '').trim().isNotEmpty &&
          _addrLine.text.trim().isEmpty) {
        _addrLine.text = result.street!.trim();
      }
      if ((result.city ?? '').trim().isNotEmpty) {
        _addrCity.text = result.city!.trim();
      }
    });
    showAppToast(context, 'Map pin set', isError: false);
  }

  Future<void> _pickAvatar() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update profile photo',
                style: AppFonts.style(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(
                  'Take photo',
                  style: AppFonts.style(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  'Choose from gallery',
                  style: AppFonts.style(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (_avatarPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    'Remove photo',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    setState(() => _avatarPath = null);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == ImageSource.camera) {
      final ok = await AppPermissions.ensureCamera();
      if (!ok) {
        if (mounted) showAppToast(context, 'Camera permission is required');
        return;
      }
    } else {
      final ok = await AppPermissions.ensurePhotos();
      if (!ok) {
        if (mounted) {
          showAppToast(context, 'Photo library permission is required');
        }
        return;
      }
    }
    try {
      final file = await ImagePicker().pickImage(
        source: choice,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (file == null || !mounted) return;
      setState(() => _avatarPath = file.path);
      showAppToast(
        context,
        'Photo selected — tap Save Profile to upload',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    final user = ref.read(authStateProvider).valueOrNull;
    _name.text = user?.name ?? '';
    _phone.text = user?.phoneNo ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    _addrLabel.dispose();
    _addrLine.dispose();
    _addrCity.dispose();
    _addrPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'My Profile',
            onBack: () => context.pop(),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              labelStyle: AppFonts.style(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: AppFonts.style(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Profile Info'),
                Tab(text: 'Change Password'),
                Tab(text: 'Addresses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildProfileInfo(),
                _buildChangePassword(),
                _buildAddresses(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      Map<String, dynamic>? uploaded;
      if (_avatarPath != null) {
        uploaded =
            await ref.read(accountRepositoryProvider).uploadMedia(_avatarPath!);
      }
      final user = await ref.read(accountRepositoryProvider).updateProfile(
            name: _name.text.trim(),
            phoneNo: _phone.text.trim(),
            image: uploaded,
          );
      ref.read(authStateProvider.notifier).setUser(user);
      if (!mounted) return;
      setState(() => _avatarPath = null);
      showAppToast(context, 'Profile updated successfully', isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePassword() async {
    if (_saving) return;
    if (_next.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }
    if (_next.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(accountRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
            confirmPassword: _confirm.text,
          );
      if (!mounted) return;
      _current.clear();
      _next.clear();
      _confirm.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAddress() async {
    if (_saving) return;
    final label = _addrLabel.text.trim();
    final line = _addrLine.text.trim();
    final city = _addrCity.text.trim();
    if (label.isEmpty || line.isEmpty || city.isEmpty) {
      showAppToast(context, 'Please fill label, address and city');
      return;
    }
    setState(() => _saving = true);
    try {
      // Prefer explicit map pin; else device GPS / fallback.
      double? lat = _mapLat;
      double? lng = _mapLng;
      if (lat == null || lng == null) {
        var loc = ref.read(deliveryLocationProvider).valueOrNull;
        loc ??= await resolveDeliveryLocation();
        if (!mounted) return;
        lat = loc.lat;
        lng = loc.lng;
        if (lat == null || lng == null) {
          showAppToast(
            context,
            'Pick a location on the map or enable GPS',
          );
          return;
        }
        if (!loc.hasGps && _mapLat == null) {
          showAppToast(
            context,
            'Using default pin. Prefer “Pick on map” for accuracy.',
            isError: false,
          );
        }
      }

      final repo = ref.read(accountRepositoryProvider);
      final ok = await repo.isDeliverable(lat: lat, lng: lng);
      if (!mounted) return;
      if (!ok) {
        showAppToast(
          context,
          'We don\'t deliver here. Move the pin into the Islamabad F Markaz zone.',
        );
        return;
      }

      await repo.createAddress(
        title: label,
        type: 'shipping',
        street: line,
        city: city,
        lat: lat,
        lng: lng,
        isDefault: false,
      );
      ref.invalidate(addressesProvider);
      if (!mounted) return;
      _addrLabel.clear();
      _addrLine.clear();
      _addrCity.clear();
      _addrPhone.clear();
      setState(() {
        _mapLat = null;
        _mapLng = null;
        _mapLabel = null;
      });
      showAppToast(context, 'Address saved', isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildProfileInfo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep your profile up to date for faster checkout.',
                  style: AppFonts.style(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Builder(
                  builder: (context) {
                    final user = ref.watch(authStateProvider).valueOrNull;
                    final net = resolveMediaUrl(user?.avatar);
                    ImageProvider? bg;
                    if (_avatarPath != null) {
                      bg = FileImage(File(_avatarPath!));
                    } else if (net.isNotEmpty) {
                      bg = NetworkImage(net);
                    }
                    final initial = (user?.name ?? 'A').trim();
                    return CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage: bg,
                      child: bg == null
                          ? Text(
                              initial.isNotEmpty
                                  ? initial[0].toUpperCase()
                                  : 'A',
                              style: AppFonts.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    );
                  },
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _pickAvatar,
            child: Text(
              'Change photo',
              style: AppFonts.style(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _formCard(
          children: [
            _fieldLabel('Full Name'),
            TextField(controller: _name),
            const SizedBox(height: 14),
            _fieldLabel('Email'),
            TextField(
              controller: _email,
              enabled: false,
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.lock_outline, size: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Email cannot be changed. Contact support if needed.',
                style: AppFonts.style(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Phone'),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        const SizedBox(height: 20),
        BrandGradientButton(
          label: _saving ? 'Saving…' : 'Update Profile',
          onPressed: _saving ? null : _saveProfile,
        ),
      ],
    );
  }

  Widget _buildChangePassword() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use a strong password with at least 12 characters.',
                  style: AppFonts.style(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _formCard(
          children: [
            _fieldLabel('Current Password'),
            TextField(
              controller: _current,
              obscureText: !_showCurrent,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrent ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showCurrent = !_showCurrent),
                ),
                counterText: '${_current.text.length}/12',
              ),
              maxLength: 64,
            ),
            const SizedBox(height: 8),
            _fieldLabel('New Password'),
            TextField(
              controller: _next,
              obscureText: !_showNext,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNext ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showNext = !_showNext),
                ),
                counterText: '${_next.text.length}/12',
              ),
              maxLength: 64,
            ),
            const SizedBox(height: 8),
            _fieldLabel('Confirm Password'),
            TextField(
              controller: _confirm,
              obscureText: !_showConfirm,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showConfirm = !_showConfirm),
                ),
                counterText: '${_confirm.text.length}/12',
              ),
              maxLength: 64,
            ),
          ],
        ),
        const SizedBox(height: 20),
        BrandGradientButton(
          label: _saving ? 'Updating…' : 'Update Password',
          onPressed: _saving ? null : _savePassword,
        ),
      ],
    );
  }

  Widget _buildAddresses() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Add New Address',
          style: AppFonts.style(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _formCard(
          children: [
            _fieldLabel('Label'),
            TextField(
              controller: _addrLabel,
              decoration: const InputDecoration(hintText: 'Home / Office'),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Address'),
            TextField(
              controller: _addrLine,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Street, area…'),
            ),
            const SizedBox(height: 12),
            _fieldLabel('City'),
            TextField(
              controller: _addrCity,
              decoration: const InputDecoration(hintText: 'Islamabad'),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Phone'),
            TextField(
              controller: _addrPhone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _fieldLabel('Location pin'),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickOnMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(
                _mapLat != null
                    ? (_mapLabel ?? 'Pin set — tap to change')
                    : 'Pick location on map',
                style: AppFonts.style(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_mapLat != null) ...[
              const SizedBox(height: 6),
              Text(
                '${_mapLat!.toStringAsFixed(5)}, ${_mapLng!.toStringAsFixed(5)}',
                style: AppFonts.style(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 16),
            BrandGradientButton(
              label: _saving ? 'Saving…' : 'Save Address',
              onPressed: _saving ? null : _saveAddress,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Saved Addresses',
          style: AppFonts.style(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ..._buildSavedAddressCards(ref),
      ],
    );
  }


  List<Widget> _buildSavedAddressCards(WidgetRef ref) {
    final async = ref.watch(addressesProvider);
    return async.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [
        Text(
          e is ApiException ? e.message : e.toString(),
          style: AppFonts.style(color: AppColors.error),
        ),
      ],
      data: (addresses) {
        if (addresses.isEmpty) {
          return [
            Text(
              'No saved addresses yet',
              style: AppFonts.style(color: AppColors.textMuted),
            ),
          ];
        }
        final widgets = <Widget>[];
        for (var i = 0; i < addresses.length; i++) {
          if (i > 0) widgets.add(const SizedBox(height: 10));
          widgets.add(_apiAddressCard(addresses[i]));
        }
        return widgets;
      },
    );
  }

  Widget _apiAddressCard(AddressModel a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: a.isDefault
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                a.title,
                style: AppFonts.style(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (a.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Default',
                    style: AppFonts.style(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.lineSummary.isEmpty ? 'No street details' : a.lineSummary,
            style: AppFonts.style(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () async {
                try {
                  await ref
                      .read(accountRepositoryProvider)
                      .deleteAddress(a.id);
                  ref.invalidate(addressesProvider);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address deleted')),
                  );
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept for route compatibility — opens My Profile → Change Password tab.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProfileScreen(initialTab: 1);
  }
}

/// Kept for route compatibility — opens My Profile → Addresses tab.
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProfileScreen(initialTab: 2);
  }
}

// ─── Wallet ──────────────────────────────────────────────────────────────────

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txnsAsync = ref.watch(walletTransactionsProvider);
    final wallet = walletAsync.valueOrNull;
    final balance = wallet?.balance ?? 0;
    final credited = wallet?.totalCredited ?? 0;
    final debited = wallet?.totalDebited ?? 0;

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.wallet,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: AppFonts.style(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        walletAsync.isLoading
                            ? '…'
                            : 'Rs ${balance.toStringAsFixed(0)}',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _walletStat(
                              'Total Credited',
                              'Rs ${credited.toStringAsFixed(0)}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            child: _walletStat(
                              'Total Debited',
                              'Rs ${debited.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transactions',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ...txnsAsync.when(
                  loading: () => [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (e, _) => [
                    Text(
                      e is ApiException ? e.message : e.toString(),
                      style: AppFonts.style(color: AppColors.error),
                    ),
                  ],
                  data: (txns) {
                    if (txns.isEmpty) {
                      return [
                        Text(
                          'No transactions yet',
                          style: AppFonts.style(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ];
                    }
                    return [
                      for (final t in txns)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: t.isCredit
                                      ? AppColors.successSoft
                                      : AppColors.errorSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  t.isCredit
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 18,
                                  color: t.isCredit
                                      ? AppColors.successText
                                      : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      style: AppFonts.style(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${t.isCredit ? 'Credit' : 'Debit'}'
                                      '${t.dateLabel.isEmpty ? '' : ' · ${t.dateLabel}'}',
                                      style: AppFonts.style(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${t.isCredit ? '+' : '−'}${formatRs(t.amount.abs())}',
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: t.isCredit
                                      ? AppColors.successText
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.style(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppFonts.style(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notifications ───────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: AppStrings.notifications,
            onBack: () => context.pop(),
            trailing: TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(accountRepositoryProvider)
                      .markAllNotificationsRead();
                  ref.invalidate(notificationsProvider);
                } catch (e) {
                  if (context.mounted) showAppToast(context, e);
                }
              },
              child: Text(
                'Mark all',
                style: AppFonts.style(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e is ApiException ? e.message : e.toString(),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(notificationsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications',
                      style: AppFonts.style(
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(notificationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      return InkWell(
                        onTap: () async {
                          if (n.isRead) return;
                          try {
                            await ref
                                .read(accountRepositoryProvider)
                                .markNotificationRead(n.id);
                            ref.invalidate(notificationsProvider);
                          } catch (_) {}
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: n.isRead
                                  ? p.border
                                  : AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: p.textPrimary,
                                ),
                              ),
                              if (n.body != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  n.body!,
                                  style: AppFonts.style(
                                    fontSize: 13,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                              if (n.createdAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  n.createdAt!,
                                  style: AppFonts.style(
                                    fontSize: 11,
                                    color: p.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ReturnsScreen moved to order_detail_screens.dart

// TrackOrderScreen moved to order_detail_screens.dart

// ─── Seller ──────────────────────────────────────────────────────────────────

class SellerScreen extends ConsumerStatefulWidget {
  const SellerScreen({super.key});

  @override
  ConsumerState<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends ConsumerState<SellerScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _phone = TextEditingController();

  List<Map<String, dynamic>> _shops = [];
  bool _loadingShops = true;
  bool _submitting = false;
  String? _logoPath;
  String? _coverPath;
  Map<String, dynamic>? _logoMedia;
  Map<String, dynamic>? _coverMedia;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShops());
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _address.dispose();
    _city.dispose();
    _province.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() => _loadingShops = true);
    try {
      final shops = await ref.read(accountRepositoryProvider).myShops();
      if (!mounted) return;
      setState(() {
        _shops = shops;
        _loadingShops = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingShops = false);
    }
  }

  Future<void> _pickShopImage({required bool logo}) async {
    final ok = await AppPermissions.ensurePhotos();
    if (!ok) {
      if (mounted) {
        showAppToast(context, 'Photo library permission is required');
      }
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() {
      if (logo) {
        _logoPath = file.path;
        _uploadingLogo = true;
      } else {
        _coverPath = file.path;
        _uploadingCover = true;
      }
    });
    try {
      final media =
          await ref.read(accountRepositoryProvider).uploadMedia(file.path);
      if (!mounted) return;
      setState(() {
        if (logo) {
          _logoMedia = media;
          _uploadingLogo = false;
        } else {
          _coverMedia = media;
          _uploadingCover = false;
        }
      });
      showAppToast(context, logo ? 'Logo uploaded' : 'Cover uploaded',
          isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (logo) {
          _logoPath = null;
          _uploadingLogo = false;
        } else {
          _coverPath = null;
          _uploadingCover = false;
        }
      });
      showAppToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (logo) {
          _logoPath = null;
          _uploadingLogo = false;
        } else {
          _coverPath = null;
          _uploadingCover = false;
        }
      });
      showAppToast(context, 'Image upload failed');
    }
  }

  Future<void> _createShop() async {
    final name = _name.text.trim();
    final city = _city.text.trim();
    final address = _address.text.trim();
    if (name.isEmpty || city.isEmpty || address.isEmpty) {
      showAppToast(context, 'Shop name, address, and city are required.');
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_uploadingLogo || _uploadingCover) {
        showAppToast(context, 'Please wait for image upload to finish');
        return;
      }
      await ref.read(accountRepositoryProvider).createShop(
            name: name,
            description: _desc.text.trim(),
            streetAddress: address,
            city: city,
            state: _province.text.trim().isEmpty
                ? 'Punjab'
                : _province.text.trim(),
            phone: _phone.text.trim().isEmpty ? '+92' : _phone.text.trim(),
            logo: _logoMedia,
            coverImage: _coverMedia,
          );
      if (!mounted) return;
      showAppToast(context, 'Shop created successfully!');
      _name.clear();
      _desc.clear();
      _address.clear();
      _city.clear();
      _province.clear();
      _phone.clear();
      setState(() {
        _logoPath = null;
        _coverPath = null;
        _logoMedia = null;
        _coverMedia = null;
      });
      await _loadShops();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } catch (_) {
      if (mounted) showAppToast(context, 'Failed to create shop');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _shopTitle(Map<String, dynamic> shop) {
    final name = shop['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Shop';
  }

  String _shopSubtitle(Map<String, dynamic> shop) {
    final address = shop['address'];
    if (address is Map) {
      final city = address['city']?.toString() ?? '';
      final state = address['state']?.toString() ?? '';
      final parts = [city, state].where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(' · ');
    }
    final status = shop['status']?.toString();
    if (status != null && status.isNotEmpty) return status;
    return 'Your shop';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: Column(
        children: [
          FigmaScreenHeader(
            title: 'Become a Seller',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'YOUR SHOPS',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                if (_loadingShops)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_shops.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.of(context).surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'No shops yet. Create your first shop below.',
                      style: AppFonts.style(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                else
                  ..._shops.map((shop) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPalette.of(context).surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.storefront,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _shopTitle(shop),
                                    style: AppFonts.style(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _shopSubtitle(shop),
                                    style: AppFonts.style(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Active',
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.successText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                Text(
                  'Create New Shop',
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _formCard(
                  children: [
                    _fieldLabel('Shop Name'),
                    TextField(
                      controller: _name,
                      decoration:
                          const InputDecoration(hintText: 'Your shop name'),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Description'),
                    TextField(
                      controller: _desc,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tell customers about your shop',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Upload Logo / Cover'),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploadingLogo
                                ? null
                                : () => _pickShopImage(logo: true),
                            icon: _uploadingLogo
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.image_outlined, size: 18),
                            label: Text(
                              _logoPath != null ? 'Logo ✓' : 'Logo',
                              style: AppFonts.style(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.border),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploadingCover
                                ? null
                                : () => _pickShopImage(logo: false),
                            icon: _uploadingCover
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_outlined, size: 18),
                            label: Text(
                              _coverPath != null ? 'Cover ✓' : 'Cover',
                              style: AppFonts.style(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.border),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Address'),
                    TextField(
                      controller: _address,
                      decoration:
                          const InputDecoration(hintText: 'Shop address'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel('City'),
                              TextField(
                                controller: _city,
                                decoration:
                                    const InputDecoration(hintText: 'Islamabad'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel('Province'),
                              TextField(
                                controller: _province,
                                decoration:
                                    const InputDecoration(hintText: 'Punjab'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Phone'),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(hintText: '+92 …'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                BrandGradientButton(
                  label: _submitting ? 'Creating…' : 'Create Shop',
                  onPressed: _submitting ? null : _createShop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan (camera / QR modes) ────────────────────────────────────────────────

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.mode = 'qr'});

  /// `camera` | `qr`
  final String mode;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _busy = false;
  String? _previewPath;
  bool _awaitingConfirm = false;
  MobileScannerController? _imageAnalyzer;
  bool _autoOpened = false;

  bool get _isCamera => widget.mode == 'camera';

  @override
  void initState() {
    super.initState();
    // Open the system camera immediately — avoids the broken live preview.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoOpened) return;
      _autoOpened = true;
      _capturePhoto(source: ImageSource.camera);
    });
  }

  @override
  void dispose() {
    _imageAnalyzer?.dispose();
    super.dispose();
  }

  Future<void> _openBarcodeResult(String code) async {
    final cleaned = code.trim();
    if (cleaned.isEmpty) return;

    setState(() => _busy = true);
    try {
      final products = await ref.read(catalogRepositoryProvider).findByBarcode(
            code: cleaned,
            vertical: ref.read(verticalProvider),
          );

      if (!mounted) return;

      if (products.length == 1) {
        final p = products.first;
        final id = p.slug?.isNotEmpty == true ? p.slug! : '${p.id}';
        context.pushReplacement(AppRoutes.product(id));
        return;
      }

      if (products.isEmpty) {
        context.pushReplacement(
          AppRoutes.productsQuery(search: cleaned, barcode: cleaned),
        );
        showAppToast(
          context,
          'No barcode match. Showing catalog search…',
          isError: false,
        );
        return;
      }

      final allHaveCode = products.every(
        (p) => (p.barCode ?? '').trim().isNotEmpty,
      );
      context.pushReplacement(
        allHaveCode
            ? AppRoutes.productsQuery(barcode: cleaned)
            : AppRoutes.productsQuery(search: cleaned),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e.toString());
      setState(() => _busy = false);
    }
  }

  Future<void> _capturePhoto({ImageSource source = ImageSource.camera}) async {
    if (_busy) return;

    if (source == ImageSource.camera) {
      final ok = await AppPermissions.ensureCamera();
      if (!ok) {
        if (mounted) {
          showAppToast(context, 'Camera permission is required.');
        }
        return;
      }
    } else {
      final ok = await AppPermissions.ensurePhotos();
      if (!ok && mounted) {
        showAppToast(context, 'Photo library permission is required.');
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2400,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted) return;
      if (shot == null) {
        setState(() => _busy = false);
        return;
      }
      setState(() {
        _previewPath = shot.path;
        _awaitingConfirm = true;
        _busy = false;
      });
      // Barcode mode: decode immediately. Photo mode: wait for Search tap.
      if (!_isCamera) {
        await _decodePreview();
      }
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, 'Could not open camera/gallery: $e');
      setState(() => _busy = false);
    }
  }

  Future<String?> _decodeBarcodeFromPath(String path) async {
    try {
      _imageAnalyzer ??= MobileScannerController(autoStart: false);
      BarcodeCapture? capture;
      try {
        capture = await _imageAnalyzer!.analyzeImage(path);
      } catch (_) {
        try {
          await _imageAnalyzer?.dispose();
        } catch (_) {}
        _imageAnalyzer = MobileScannerController(autoStart: false);
        try {
          capture = await _imageAnalyzer!.analyzeImage(path);
        } catch (_) {
          return null;
        }
      }
      final codes = capture?.barcodes
              .map((b) => b.rawValue)
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      return codes.isNotEmpty ? codes.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Pull a searchable product/brand phrase from packaging text (OCR).
  Future<String?> _ocrSearchQueryFromPath(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(path);
      final recognized = await recognizer.processImage(input);
      final lines = <String>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final t = line.text.trim();
          if (t.length >= 3) lines.add(t);
        }
      }
      if (lines.isEmpty) {
        final full = recognized.text.trim();
        if (full.length >= 3) lines.add(full);
      }
      return _pickBestSearchQuery(lines);
    } catch (_) {
      return null;
    } finally {
      await recognizer.close();
    }
  }

  static final _noiseLine = RegExp(
    r'^(net\s*wt|mrp|rs\.?|pk\.?r?|batch|exp|mfg|best\s*before|ingredients?|nutrition|www\.|http|gm|ml|kg|pcs?|strip|tablets?)\b',
    caseSensitive: false,
  );

  String? _pickBestSearchQuery(List<String> lines) {
    final cleaned = lines
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.length >= 3 && l.length <= 48)
        .where((l) => !_noiseLine.hasMatch(l))
        .where((l) => RegExp(r'[A-Za-z]{3,}').hasMatch(l))
        .toList();
    if (cleaned.isEmpty) return null;

    // Prefer title-like lines (mixed case / short brand names) over paragraphs.
    cleaned.sort((a, b) {
      final aScore = (a.length <= 28 ? 2 : 0) +
          (RegExp(r'^[A-Z0-9]').hasMatch(a) ? 1 : 0) +
          (a.split(' ').length <= 5 ? 2 : 0);
      final bScore = (b.length <= 28 ? 2 : 0) +
          (RegExp(r'^[A-Z0-9]').hasMatch(b) ? 1 : 0) +
          (b.split(' ').length <= 5 ? 2 : 0);
      return bScore.compareTo(aScore);
    });

    final best = cleaned.first;
    // Keep first 4 words max for catalog searchTerm.
    final words = best.split(' ').take(4).join(' ').trim();
    return words.isEmpty ? null : words;
  }

  Future<void> _decodePreview() async {
    final path = _previewPath;
    if (path == null || _busy) return;
    setState(() => _busy = true);

    // 1) Barcode on the pack
    final code = await _decodeBarcodeFromPath(path);
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      showAppToast(context, 'Barcode found', isError: false);
      await _openBarcodeResult(code);
      return;
    }

    // 2) Photo mode: OCR brand/product text → catalog search (no manual box)
    if (_isCamera) {
      final query = await _ocrSearchQueryFromPath(path);
      if (!mounted) return;
      if (query != null && query.isNotEmpty) {
        showAppToast(context, 'Searching “$query”…', isError: false);
        context.pushReplacement(AppRoutes.productsQuery(search: query));
        return;
      }
      setState(() => _busy = false);
      showAppToast(
        context,
        'Couldn’t read the pack. Retake closer, or tap Enter name or barcode.',
      );
      return;
    }

    // 3) Barcode-scan mode: keep user on screen to retake / type digits
    setState(() => _busy = false);
    showAppToast(
      context,
      'No barcode detected. Retake closer to the barcode, or enter it manually.',
    );
  }

  Future<void> _searchWithPhoto() => _decodePreview();

  Future<String?> _askProductName({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Future<void> _fallbackManualBarcode() async {
    if (_busy) return;
    final query = await _askProductName(
      title: _isCamera ? 'Search products' : 'Enter barcode',
      hint: _isCamera
          ? 'Product name or barcode'
          : 'Type the barcode digits',
    );
    if (!mounted || query == null || query.isEmpty) return;

    final digitsOnly = RegExp(r'^\d{8,14}$').hasMatch(query);
    if (digitsOnly) {
      await _openBarcodeResult(query);
    } else {
      context.pushReplacement(AppRoutes.productsQuery(search: query));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCamera ? 'Search by photo' : 'Scan barcode';
    final subtitle = _awaitingConfirm
        ? (_busy
            ? (_isCamera ? 'Reading pack text…' : 'Reading barcode…')
            : (_isCamera
                ? 'Tap Search to find this product'
                : 'No barcode yet — retake or enter digits'))
        : (_isCamera
            ? 'Photograph the package, then search'
            : 'Photograph the barcode clearly, then we look it up');

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppFonts.style(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2332),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_previewPath != null)
                              Image.file(
                                File(_previewPath!),
                                fit: BoxFit.cover,
                              )
                            else
                              ColoredBox(
                                color: const Color(0xFF151C28),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isCamera
                                            ? Icons.photo_camera_outlined
                                            : Icons.qr_code_scanner,
                                        color: Colors.white38,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          _isCamera
                                              ? 'Take a clear photo of the product'
                                              : 'Take a clear photo of the barcode',
                                          textAlign: TextAlign.center,
                                          style: AppFonts.style(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_previewPath == null)
                              IgnorePointer(
                                child: Center(
                                  child: SizedBox(
                                    width: 240,
                                    height: 240,
                                    child: CustomPaint(
                                      painter: _ScanFramePainter(),
                                    ),
                                  ),
                                ),
                              ),
                            if (_awaitingConfirm)
                              Positioned(
                                left: 16,
                                bottom: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _busy ? 'READING' : 'PREVIEW',
                                    style: AppFonts.style(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppFonts.style(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: _awaitingConfirm
                  ? Column(
                      children: [
                        if (_isCamera || !_busy)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _searchWithPhoto,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _busy
                                    ? 'Searching…'
                                    : (_isCamera
                                        ? 'Search with this photo'
                                        : 'Read barcode again'),
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _previewPath = null;
                                    _awaitingConfirm = false;
                                  }),
                          child: Text(
                            'Retake',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _fallbackManualBarcode,
                          child: Text(
                            'Enter name or barcode',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryMid,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _capturePhoto(
                                      source: ImageSource.camera,
                                    ),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(
                              _isCamera ? 'Take photo' : 'Scan with camera',
                              style: AppFonts.style(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _capturePhoto(
                                          source: ImageSource.gallery,
                                        ),
                                icon: const Icon(
                                  Icons.photo_library_outlined,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Gallery',
                                  style: AppFonts.style(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  minimumSize: const Size.fromHeight(46),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _busy ? null : _fallbackManualBarcode,
                                icon: const Icon(
                                  Icons.keyboard_alt_outlined,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Type it',
                                  style: AppFonts.style(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  minimumSize: const Size.fromHeight(46),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Cancel',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF57A1C2)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 36.0;
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Voice Search dialog (shown from home) ───────────────────────────────────

Future<void> showVoiceSearchDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => const _VoiceSearchDialog(),
  );
}

class _VoiceSearchDialog extends StatefulWidget {
  const _VoiceSearchDialog();

  @override
  State<_VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<_VoiceSearchDialog> {
  final SpeechToText _speech = SpeechToText();
  String _heard = '';
  String _status = 'Listening…';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _start() async {
    final micOk = await AppPermissions.ensureMicrophone();
    if (!mounted) return;
    if (!micOk) {
      setState(() => _status = 'Microphone permission denied');
      showAppToast(context, 'Microphone permission is required for voice search.');
      return;
    }
    _ready = await _speech.initialize(
      onError: (e) {
        if (!mounted) return;
        setState(() => _status = e.errorMsg);
      },
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _status = _heard.isEmpty ? 'No speech detected' : 'Got it');
        }
      },
    );
    if (!_ready) {
      if (!mounted) return;
      setState(() => _status = 'Speech recognition unavailable');
      return;
    }
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _heard = result.recognizedWords;
          _status = result.finalResult ? 'Searching…' : 'Listening…';
        });
        if (result.finalResult && _heard.trim().isNotEmpty) {
          _finish(_heard.trim());
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        localeId: 'en_US',
        partialResults: true,
      ),
    );
  }

  void _finish(String query) {
    _speech.stop();
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRoutes.productsQuery(search: query));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121A26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () {
                  _speech.stop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ),
            Text(
              'Voice Search',
              style: AppFonts.style(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: AppFonts.style(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_heard.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '"$_heard"',
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                final q = _heard.trim();
                if (q.isEmpty) {
                  showAppToast(context, 'Speak a product name, then try again.');
                  return;
                }
                _finish(q);
              },
              child: Text(
                'Search',
                style: AppFonts.style(
                  color: AppColors.primaryMid,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

Widget _formCard({required List<Widget> children}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

Widget _fieldLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: AppFonts.style(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
