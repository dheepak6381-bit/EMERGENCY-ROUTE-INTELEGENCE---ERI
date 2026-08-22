import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_result_model.dart';
import '../models/road_condition_model.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/constants/app_constants.dart';

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  @override
  String toString() => 'RateLimitException: $message';
}

/// Service wrapping the OSRM Public API for Routing and Matrix computations.
/// Uses Contraction Hierarchies (Optimized Dijkstra).
class OsrmService {
  static final OsrmService _instance = OsrmService._internal();
  factory OsrmService() => _instance;
  OsrmService._internal();

  final http.Client _client = http.Client();
  static const String _baseUrl = AppConstants.osrmBaseUrl;

  /// Fetch route from [origin] to [destination].
  Future<RouteResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
    required String hospitalId,
    required List<RoadConditionModel> conditions,
  }) async {
    try {
      // OSRM coordinates format: {longitude},{latitude}
      final coords = '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/$coords?overview=full&geometries=geojson'
      );

      final response = await _client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 429) {
        throw RateLimitException('OSRM route rate limit exceeded.');
      }
      if (response.statusCode != 200) {
        throw Exception('OSRM route error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] != 'Ok') return null;
      
      final routes = json['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final baseDurationSecs = (route['duration'] as num?)?.toDouble() ?? 0.0;
      final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;

      // Decode GeoJSON LineString
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      // Apply road condition delay factors
      double maxDelay = 1.0;
      String? conditionNote;
      for (final cond in conditions) {
        if (!cond.isClear && GeoUtils.isConditionOnRoute(points, cond)) {
          if (cond.delayFactor > maxDelay) {
            maxDelay = cond.delayFactor;
            conditionNote = cond.note.isNotEmpty
                ? cond.note
                : '${cond.statusLabel} on ${cond.segmentId}';
          }
        }
      }

      final adjustedDurationSecs = baseDurationSecs * maxDelay;

      return RouteResult(
        points: points,
        baseDuration: Duration(seconds: baseDurationSecs.round()),
        adjustedDuration: Duration(seconds: adjustedDurationSecs.round()),
        distanceMeters: distanceMeters,
        hospitalId: hospitalId,
        conditionNote: conditionNote,
      );
    } catch (e) {
      if (e is RateLimitException) rethrow;
      return null;
    }
  }

  /// Batch ETA computation using OSRM Table API.
  Future<Map<String, Duration>> getMatrix({
    required LatLng origin,
    required List<({String id, LatLng location})> hospitals,
    required List<RoadConditionModel> conditions,
  }) async {
    if (hospitals.isEmpty) return {};

    try {
      // OSRM coordinates format: {longitude},{latitude}
      final coordsList = [
        '${origin.longitude},${origin.latitude}',
        ...hospitals.map((h) => '${h.location.longitude},${h.location.latitude}')
      ];
      final coordsString = coordsList.join(';');

      // We want times from source (0) to all destinations (1..N)
      final destinations = List.generate(hospitals.length, (i) => i + 1).join(';');
      
      final url = Uri.parse(
          '$_baseUrl/table/v1/driving/$coordsString?sources=0&destinations=$destinations'
      );

      final response = await _client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 429) {
        throw RateLimitException('OSRM matrix rate limit exceeded.');
      }
      if (response.statusCode != 200) {
        throw Exception('OSRM matrix error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] != 'Ok') return {};
      
      final durationsRaw = (json['durations'] as List<dynamic>).first as List<dynamic>;

      final result = <String, Duration>{};
      for (int i = 0; i < hospitals.length; i++) {
        final raw = (durationsRaw[i] as num?)?.toDouble();
        if (raw == null) continue; // Unroutable
        
        // Apply max delay factor from active conditions on this straight-line approximation
        double maxDelay = 1.0;
        for (final cond in conditions) {
          if (!cond.isClear && GeoUtils.intersectsLine(origin, hospitals[i].location, cond)) {
            if (cond.delayFactor > maxDelay) maxDelay = cond.delayFactor;
          }
        }
        
        final adjusted = raw * maxDelay;
        result[hospitals[i].id] = Duration(seconds: adjusted.round());
      }
      return result;
    } catch (e) {
      if (e is RateLimitException) rethrow;
      return {};
    }
  }
}
