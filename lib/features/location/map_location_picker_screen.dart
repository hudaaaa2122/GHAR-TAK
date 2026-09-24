import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/delivery_location.dart';
import '../../core/location/geocode_address.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Result returned when the user confirms a map pin.
class MapPickResult {
  const MapPickResult({
    required this.lat,
    required this.lng,
    this.label,
    this.street,
    this.city,
  });

  final double lat;
  final double lng;
  final String? label;
  final String? street;
  final String? city;
}

/// Full-screen map to choose a delivery pin (OpenStreetMap — no Google key).
/// Includes website-style “Search an area” type-to-search (Nominatim).
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  final double? initialLat;
  final double? initialLng;

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  late LatLng _pin;
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  bool _busy = false;
  bool _searching = false;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _pin = LatLng(
      widget.initialLat ?? DeliveryLocation.fallback.lat!,
      widget.initialLng ?? DeliveryLocation.fallback.lng!,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToGps());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToGps() async {
    try {
      final ok = await AppPermissions.ensureLocation();
      if (!ok) {
        if (mounted) {
          setState(() {
            _hint = 'Location is blocked. Drop a pin or search instead.';
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _pin = LatLng(pos.latitude, pos.longitude);
        _hint = 'Moved to your current location';
      });
      _mapController.move(_pin, 16);
    } catch (_) {
      // Keep fallback pin.
    }
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty || _searching) return;
    setState(() {
      _searching = true;
      _hint = null;
    });
    final found = await geocodeAddressQuery(q);
    if (!mounted) return;
    setState(() => _searching = false);
    if (found == null) {
      setState(() => _hint = 'No results for “$q”. Try another area.');
      return;
    }
    setState(() {
      _pin = LatLng(found.lat, found.lng);
      _hint = found.label;
    });
    _mapController.move(_pin, 16);
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    String? street;
    String? city;
    String label =
        '${_pin.latitude.toStringAsFixed(5)}, ${_pin.longitude.toStringAsFixed(5)}';
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        _pin.latitude,
        _pin.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final lineParts = <String>[
          if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
          if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
        ];
        if (lineParts.isNotEmpty) street = lineParts.join(', ');
        city = (p.locality ?? '').trim().isNotEmpty
            ? p.locality!.trim()
            : ((p.subAdministrativeArea ?? '').trim().isNotEmpty
                ? p.subAdministrativeArea!.trim()
                : 'Islamabad');
        final parts = <String>[
          if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        ];
        if (parts.isNotEmpty) label = parts.join(', ');
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(
      context,
      MapPickResult(
        lat: _pin.latitude,
        lng: _pin.longitude,
        label: label,
        street: street,
        city: city,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Choose on map',
          style: AppFonts.style(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
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
                    onTap: _busy ? null : _goToGps,
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
          if (_hint != null)
            Material(
              color: AppColors.primarySoft,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _hint!,
                        style: AppFonts.style(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pin,
                    initialZoom: 15,
                    onTap: (_, point) {
                      setState(() {
                        _pin = point;
                        _hint = 'Pin updated — confirm when ready';
                      });
                    },
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
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFB3261E),
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            'Search an area, or tap the map to place your delivery pin.\n'
                            '${_pin.latitude.toStringAsFixed(5)}, '
                            '${_pin.longitude.toStringAsFixed(5)}',
                            textAlign: TextAlign.center,
                            style: AppFonts.style(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _busy ? null : _confirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _busy ? 'Saving…' : 'Use this location',
                            style: AppFonts.style(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
