import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivery_location.dart';

/// When set (e.g. from map picker), overrides GPS-resolved location.
final deliveryLocationOverrideProvider =
    StateProvider<DeliveryLocation?>((_) => null);

final deliveryLocationProvider = FutureProvider<DeliveryLocation>((ref) async {
  final override = ref.watch(deliveryLocationOverrideProvider);
  if (override != null) return override;
  return resolveDeliveryLocation();
});
