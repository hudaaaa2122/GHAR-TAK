import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Startup permission prompts + delivery location label used on Home.
class DeliveryLocation {
  const DeliveryLocation({
    required this.label,
    this.lat,
    this.lng,
    this.hasGps = false,
    this.street,
    this.city,
  });

  /// Shown in the home header (replaces mocked "Gulberg III").
  final String label;
  final double? lat;
  final double? lng;
  final bool hasGps;
  final String? street;
  final String? city;

  /// Fallback when location permission is denied / unavailable.
  /// Pin sits inside the live "F markaz" delivery zone (Islamabad).
  static const DeliveryLocation fallback = DeliveryLocation(
    label: 'Islamabad, Pakistan',
    lat: 33.6980,
    lng: 73.0500,
    hasGps: false,
    street: 'F Markaz',
    city: 'Islamabad',
  );
}

class AppPermissions {
  AppPermissions._();

  static bool _requestedOnce = false;

  /// Ask camera, microphone, and location once after first frame.
  static Future<void> requestStartupPermissions() async {
    if (_requestedOnce) return;
    _requestedOnce = true;
    try {
      await [
        Permission.camera,
        Permission.microphone,
        Permission.locationWhenInUse,
      ].request();
    } catch (_) {
      // Best-effort — plugins may still prompt later.
    }
  }

  static Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> ensureMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> ensureLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted || status.isLimited;
  }
}

Future<DeliveryLocation> resolveDeliveryLocation() async {
  try {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return DeliveryLocation.fallback;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return DeliveryLocation.fallback;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );

    String label = DeliveryLocation.fallback.label;
    String? street;
    String? city = DeliveryLocation.fallback.city;
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
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
                : city);
        final parts = <String>[
          if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
          if ((p.administrativeArea ?? '').trim().isNotEmpty &&
              (p.locality ?? '').trim() != (p.administrativeArea ?? '').trim())
            p.administrativeArea!.trim(),
        ];
        if (parts.isNotEmpty) label = parts.join(', ');
      }
    } catch (_) {
      label =
          '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}';
    }

    return DeliveryLocation(
      label: label,
      lat: pos.latitude,
      lng: pos.longitude,
      hasGps: true,
      street: street,
      city: city,
    );
  } catch (_) {
    return DeliveryLocation.fallback;
  }
}

/// Top-right toast for ~3 seconds (API / validation errors).
void showAppToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  bool isError = true,
}) {
  final text = message.trim();
  if (text.isEmpty) return;

  final overlay = Overlay.maybeOf(context);
  if (overlay == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: duration),
    );
    return;
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      final top = MediaQuery.paddingOf(ctx).top + 12;
      return Positioned(
        top: top,
        right: 12,
        left: 72,
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topRight,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(12 * (1 - v), 0),
                  child: child,
                ),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isError
                      ? const Color(0xFFB3261E)
                      : const Color(0xFF1B6B4A),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Future<void>.delayed(duration, () {
    try {
      entry.remove();
    } catch (_) {}
  });
}
