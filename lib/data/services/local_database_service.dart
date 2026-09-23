import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/hospital_model.dart';
import 'dart:math' as math;

class LocalDatabaseService {
  LocalDatabaseService._();
  
  static final LocalDatabaseService instance = LocalDatabaseService._();
  
  List<HospitalModel>? _cachedHospitals;
  
  Future<void> init() async {
    if (_cachedHospitals != null) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/india_hospitals_master.json');
      final elements = json.decode(jsonString) as List;
      
      final parsed = <HospitalModel>[];
      for (var el in elements) {
        try {
          final h = HospitalModel.fromOverpass(el);
          parsed.add(h);
        } catch (e) {
          // skip
        }
      }
      _cachedHospitals = parsed;
      print('Loaded \${_cachedHospitals!.length} offline hospitals successfully.');
    } catch (e) {
      print('Failed to load offline hospital database: $e');
      _cachedHospitals = [];
    }
  }

  /// Searches the massive offline database for hospitals within radius.
  Future<List<HospitalModel>> searchNearbyOffline({
    required LatLng location,
    double radiusKm = 50.0,
  }) async {
    if (_cachedHospitals == null) {
      await init();
    }
    
    if (_cachedHospitals == null || _cachedHospitals!.isEmpty) {
      return [];
    }

    final distanceCalc = const Distance();
    final radiusMeters = radiusKm * 1000;
    
    // Fast spatial filter using basic lat/lon bounds before exact haversine
    final latDelta = radiusKm / 111.0; 
    final lonDelta = radiusKm / (111.0 * math.cos(location.latitude * math.pi / 180));
    
    final minLat = location.latitude - latDelta;
    final maxLat = location.latitude + latDelta;
    final minLon = location.longitude - lonDelta;
    final maxLon = location.longitude + lonDelta;

    final results = <HospitalModel>[];
    
    for (final h in _cachedHospitals!) {
      final hLat = h.location.latitude;
      final hLon = h.location.longitude;
      
      // Fast bounding box check
      if (hLat >= minLat && hLat <= maxLat && hLon >= minLon && hLon <= maxLon) {
        // Exact haversine check
        final dist = distanceCalc.as(LengthUnit.Meter, location, h.location);
        if (dist <= radiusMeters) {
          results.add(h);
        }
      }
    }
    
    return results;
  }
}
