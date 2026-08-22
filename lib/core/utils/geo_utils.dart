import 'package:latlong2/latlong.dart';
import '../../data/models/road_condition_model.dart';

class GeoUtils {
  /// Checks if a route (list of points) intersects the bounding box of a road condition.
  static bool isConditionOnRoute(
      List<LatLng> routePoints, RoadConditionModel condition) {
    if (routePoints.isEmpty) return false;
    
    // Create a bounding box from condition.bounds
    if (condition.bounds.length < 2) return false;

    double minLat = condition.bounds.first.latitude;
    double maxLat = condition.bounds.first.latitude;
    double minLng = condition.bounds.first.longitude;
    double maxLng = condition.bounds.first.longitude;

    for (final point in condition.bounds) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add a small buffer to the bounding box to account for route imprecision (approx 50 meters)
    const double buffer = 0.0005;
    minLat -= buffer;
    maxLat += buffer;
    minLng -= buffer;
    maxLng += buffer;

    for (final point in routePoints) {
      if (point.latitude >= minLat &&
          point.latitude <= maxLat &&
          point.longitude >= minLng &&
          point.longitude <= maxLng) {
        return true; // Route passes through the condition's area
      }
    }
    return false;
  }

  /// Checks if a straight line from origin to destination intersects the bounding box.
  /// Used for the matrix API approximation.
  static bool intersectsLine(
      LatLng origin, LatLng destination, RoadConditionModel condition) {
    // Basic bounding box intersection
    if (condition.bounds.length < 2) return false;
    
    // Sample points along the line
    const int numSamples = 10;
    final points = <LatLng>[];
    
    for (int i = 0; i <= numSamples; i++) {
      final t = i / numSamples;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * t;
      points.add(LatLng(lat, lng));
    }
    
    return isConditionOnRoute(points, condition);
  }
}
