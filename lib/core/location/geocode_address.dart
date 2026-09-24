import 'package:dio/dio.dart';

/// Forward-geocode result — mirrors website `geocodeAddressQuery`.
class GeocodedPlace {
  const GeocodedPlace({
    required this.lat,
    required this.lng,
    required this.label,
  });

  final double lat;
  final double lng;
  final String label;
}

/// Nominatim search used by website DeliveryPinMap / deliveryLocation.ts.
Future<GeocodedPlace?> geocodeAddressQuery(String query) async {
  final q = query.trim();
  if (q.isEmpty) return null;
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        headers: {
          'Accept': 'application/json',
          // Nominatim requires an identifying User-Agent.
          'User-Agent': 'GherTakMobile/1.0 (com.ghertak.ghertak_mobile)',
        },
      ),
    );
    final res = await dio.get<List<dynamic>>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'format': 'json',
        'limit': 1,
        'q': q,
      },
    );
    final results = res.data;
    if (results == null || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lng = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lng == null) return null;
    final label = first['display_name']?.toString().trim();
    return GeocodedPlace(
      lat: lat,
      lng: lng,
      label: (label != null && label.isNotEmpty) ? label : q,
    );
  } catch (_) {
    return null;
  }
}
