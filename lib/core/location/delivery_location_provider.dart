import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'delivery_location.dart';

const _prefsKey = 'ghertak_delivery_location';

/// When set (e.g. from location gate / map picker), overrides GPS.
final deliveryLocationOverrideProvider =
    StateProvider<DeliveryLocation?>((_) => null);

/// True until the user confirms a delivery pin (website gate behavior).
final needsDeliveryGateProvider = StateProvider<bool>((_) => true);

Future<DeliveryLocation?> readPersistedDeliveryLocation() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw);
    if (map is! Map) return null;
    final lat = double.tryParse('${map['lat']}');
    final lng = double.tryParse('${map['lng']}');
    if (lat == null || lng == null) return null;
    return DeliveryLocation(
      label: map['label']?.toString() ?? 'Delivery location',
      lat: lat,
      lng: lng,
      hasGps: map['hasGps'] == true,
      street: map['street']?.toString(),
      city: map['city']?.toString(),
    );
  } catch (_) {
    return null;
  }
}

Future<void> persistDeliveryLocation(DeliveryLocation loc) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'label': loc.label,
        'lat': loc.lat,
        'lng': loc.lng,
        'hasGps': loc.hasGps,
        'street': loc.street,
        'city': loc.city,
      }),
    );
  } catch (_) {}
}

final deliveryLocationProvider = FutureProvider<DeliveryLocation>((ref) async {
  final override = ref.watch(deliveryLocationOverrideProvider);
  if (override != null) return override;

  final stored = await readPersistedDeliveryLocation();
  if (stored != null) {
    // Already confirmed previously — skip forced gate.
    Future.microtask(() {
      ref.read(needsDeliveryGateProvider.notifier).state = false;
    });
    return stored;
  }
  return resolveDeliveryLocation();
});
