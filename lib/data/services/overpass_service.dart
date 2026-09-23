import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/hospital_model.dart';

class OverpassService {
  static const String _overpassApiUrl = 'http://overpass-api.de/api/interpreter';

  /// Finds ALL hospitals within a given radius (e.g., 50km) of the incident.
  /// Uses OpenStreetMap's Overpass API (free, no API key).
  Future<List<HospitalModel>> fetchLiveHospitals({
    required LatLng incidentLocation,
    double radiusKm = 50.0,
  }) async {
    final radiusMeters = (radiusKm * 1000).round();
    final lat = incidentLocation.latitude;
    final lon = incidentLocation.longitude;

    // Overpass QL query: find all nodes, ways, relations tagged as hospital within radius
    final query = '''
      [out:json][timeout:5];
      nwr["amenity"="hospital"](around:$radiusMeters,$lat,$lon);
      out center;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassApiUrl),
        body: {'data': query},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        final hospitals = <HospitalModel>[];
        for (var el in elements) {
          try {
            final h = HospitalModel.fromOverpass(el);
            if (h != null) hospitals.add(h);
          } catch (e) {
            // Skip invalid nodes
          }
        }
        return hospitals;
      } else {
        throw Exception('Overpass API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch live hospitals: $e');
    }
  }
}
