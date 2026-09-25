import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../constants/app_routes.dart';
import '../../core/location/delivery_location.dart';
import '../../core/location/delivery_location_provider.dart';
import '../../core/location/geocode_address.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../shared/widgets.dart';
import '../providers.dart';

/// Website-style “Where should we deliver?” gate with map + zone check.
Future<bool> showDeliveryLocationGate(
  BuildContext context, {
  bool barrierDismissible = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: barrierDismissible,
    isDismissible: barrierDismissible,
    backgroundColor: Colors.transparent,
    builder: (_) => const DeliveryLocationGateSheet(),
  );
  return result == true;
}

class DeliveryLocationGateSheet extends ConsumerStatefulWidget {
  const DeliveryLocationGateSheet({super.key});

  @override
  ConsumerState<DeliveryLocationGateSheet> createState() =>
      _DeliveryLocationGateSheetState();
}

class _DeliveryLocationGateSheetState
    extends ConsumerState<DeliveryLocationGateSheet> {
  late LatLng _pin;
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  bool _busy = false;
  bool _searching = false;
  bool? _deliverable;
  String? _label;
  String? _street;
  String? _city;
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    final fallback = DeliveryLocation.fallback;
    _pin = LatLng(fallback.lat!, fallback.lng!);
    _label = fallback.label;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _fillSearchBar(String? text) {
    final value = (text ?? '').trim();
    if (value.isEmpty) return;
    _searchCtrl.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _bootstrap() async {
    // Prefer live GPS so the search bar defaults to the current location.
    await _goToGps();
    if (!mounted) return;
    if (_label != null && _label!.trim().isNotEmpty) return;

    final current = ref.read(deliveryLocationProvider).valueOrNull;
    final lat = current?.lat;
    final lng = current?.lng;
    if (current == null || lat == null || lng == null) return;

    setState(() {
      _pin = LatLng(lat, lng);
      _label = current.label;
      _street = current.street;
      _city = current.city;
    });
    final searchText = [
      if ((current.street ?? '').trim().isNotEmpty) current.street!.trim(),
      if ((current.city ?? '').trim().isNotEmpty) current.city!.trim(),
    ].join(', ');
    _fillSearchBar(searchText.isNotEmpty ? searchText : current.label);
    _mapController.move(_pin, 15);
    await _checkZone();
  }

  Future<void> _goToGps() async {
    try {
      final ok = await AppPermissions.ensureLocation();
      if (!ok) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _pin = LatLng(pos.latitude, pos.longitude);
        _selectedAddressId = null;
        _deliverable = null;
      });
      _mapController.move(_pin, 16);
      await _reverseGeocode();
      await _checkZone();
    } catch (_) {}
  }

  Future<void> _reverseGeocode() async {
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        _pin.latitude,
        _pin.longitude,
      );
      if (places.isEmpty || !mounted) return;
      final p = places.first;
      final lineParts = <String>[
        if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      ];
      final city = (p.locality ?? '').trim().isNotEmpty
          ? p.locality!.trim()
          : ((p.subAdministrativeArea ?? '').trim().isNotEmpty
              ? p.subAdministrativeArea!.trim()
              : 'Islamabad');
      final parts = <String>[
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
      ];
      final label = parts.isEmpty
          ? '${_pin.latitude.toStringAsFixed(4)}, ${_pin.longitude.toStringAsFixed(4)}'
          : parts.join(', ');
      final searchText = lineParts.isNotEmpty
          ? [...lineParts, if (city.trim().isNotEmpty) city].join(', ')
          : label;
      setState(() {
        _street = lineParts.isEmpty ? null : lineParts.join(', ');
        _city = city;
        _label = label;
      });
      _fillSearchBar(searchText);
    } catch (_) {}
  }

  Future<void> _checkZone() async {
    try {
      final ok = await ref.read(accountRepositoryProvider).isDeliverable(
            lat: _pin.latitude,
            lng: _pin.longitude,
          );
      if (!mounted) return;
      setState(() => _deliverable = ok);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deliverable = null);
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _pin = point;
      _selectedAddressId = null;
      _deliverable = null;
    });
    await _reverseGeocode();
    await _checkZone();
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty || _searching) return;
    setState(() => _searching = true);
    final found = await geocodeAddressQuery(q);
    if (!mounted) return;
    setState(() => _searching = false);
    if (found == null) {
      showAppToast(context, 'No results for “$q”. Try another area.');
      return;
    }
    setState(() {
      _pin = LatLng(found.lat, found.lng);
      _label = found.label;
      _selectedAddressId = null;
      _deliverable = null;
    });
    _mapController.move(_pin, 16);
    await _reverseGeocode();
    await _checkZone();
  }

  Future<void> _selectAddress(AddressModel a) async {
    if (a.lat != null && a.lng != null) {
      setState(() {
        _selectedAddressId = a.id;
        _pin = LatLng(a.lat!, a.lng!);
        _street = a.street;
        _city = a.city;
        _label = a.lineSummary.isEmpty ? a.title : a.lineSummary;
        _deliverable = null;
      });
      _fillSearchBar(_label);
      _mapController.move(_pin, 16);
      await _checkZone();
      return;
    }

    // Website: geocode saved address text when no pin exists.
    final query = [
      a.street,
      a.city,
      a.state,
      if ((a.country ?? '').trim().isNotEmpty) a.country else 'Pakistan',
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    final found = query.isEmpty ? null : await geocodeAddressQuery(query);
    if (!mounted) return;
    if (found == null) {
      showAppToast(
        context,
        'This saved address has no map pin yet. Drop one on the map.',
      );
      return;
    }
    setState(() {
      _selectedAddressId = a.id;
      _pin = LatLng(found.lat, found.lng);
      _street = a.street;
      _city = a.city;
      _label = found.label;
      _deliverable = null;
    });
    _fillSearchBar(found.label);
    _mapController.move(_pin, 16);
    await _checkZone();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    if (_deliverable == false) {
      showAppToast(
        context,
        'We don\'t deliver here. Move the pin into a delivery zone.',
      );
      return;
    }
    setState(() => _busy = true);
    final loc = DeliveryLocation(
      label: _label ?? 'Delivery location',
      lat: _pin.latitude,
      lng: _pin.longitude,
      hasGps: true,
      street: _street,
      city: _city,
    );
    await persistDeliveryLocation(loc);
    ref.read(deliveryLocationOverrideProvider.notifier).state = loc;
    ref.read(needsDeliveryGateProvider.notifier).state = false;
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final addressesAsync = ref.watch(addressesProvider);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where should we deliver?',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set your pin inside our delivery area to continue.',
                        style: AppFonts.style(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push(AppRoutes.login),
                  icon: Icon(
                    auth == null ? Icons.login : Icons.person_outline,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runSearch(),
                    style: AppFonts.style(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search an area',
                      hintStyle: AppFonts.style(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.checkoutConfirm,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _searching ? null : _runSearch,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textBody,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _searching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Search',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: _goToGps,
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.near_me_outlined,
                        color: AppColors.checkoutConfirm,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pin,
                    initialZoom: 14,
                    onTap: (_, p) => _onMapTap(p),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ghertak.ghertak_mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pin,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _label ?? 'Tap the map to place your pin',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_deliverable != null)
                      WebStatusPill(
                        label: _deliverable! ? 'Deliverable' : 'Out of zone',
                        foreground: _deliverable!
                            ? AppColors.successText
                            : AppColors.error,
                        background: _deliverable!
                            ? AppColors.successSoft
                            : AppColors.errorSoft,
                      ),
                  ],
                ),
                if (auth != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: addressesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (list) {
                        if (list.isEmpty) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.addresses),
                              child: Text(
                                'Add saved address',
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final a = list[i];
                            final selected = _selectedAddressId == a.id;
                            return ChoiceChip(
                              label: Text(a.title),
                              selected: selected,
                              onSelected: (_) => _selectAddress(a),
                              selectedColor: AppColors.primarySoft,
                              labelStyle: AppFonts.style(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.textSecondary,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                WebPrimaryButton(
                  label: _busy ? 'Saving…' : 'Deliver here',
                  onPressed: _busy ? null : _confirm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
