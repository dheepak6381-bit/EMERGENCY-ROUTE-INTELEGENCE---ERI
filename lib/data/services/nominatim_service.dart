import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';

class NominatimResult {
  final String displayName;
  final LatLng location;

  const NominatimResult({required this.displayName, required this.location});
}

/// Free geocoding via OpenStreetMap Nominatim — no API key required.
class NominatimService {
  static final NominatimService _instance = NominatimService._internal();
  factory NominatimService() => _instance;
  NominatimService._internal();

  final http.Client _client = http.Client();

  /// Search for a place by text query. Returns up to 5 results.
  Future<List<NominatimResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = Uri.parse(
        '${AppConstants.nominatimBaseUrl}/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=5'
        '&countrycodes=in',
      );

      final response = await _client.get(url, headers: {
        'User-Agent': AppConstants.osmUserAgent,
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as List<dynamic>;
      return json.map((item) {
        final m = item as Map<String, dynamic>;
        return NominatimResult(
          displayName: m['display_name'] as String? ?? '',
          location: LatLng(
            double.tryParse(m['lat'] as String? ?? '0') ?? 0,
            double.tryParse(m['lon'] as String? ?? '0') ?? 0,
          ),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Reverse geocode a lat/lng to an address string.
  Future<String?> reverseGeocode(LatLng location) async {
    try {
      final url = Uri.parse(
        '${AppConstants.nominatimBaseUrl}/reverse'
        '?lat=${location.latitude}'
        '&lon=${location.longitude}'
        '&format=json',
      );
      final response = await _client.get(url, headers: {
        'User-Agent': AppConstants.osmUserAgent,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
