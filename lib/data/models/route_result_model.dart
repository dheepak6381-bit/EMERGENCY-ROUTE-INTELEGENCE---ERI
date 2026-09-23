import 'package:latlong2/latlong.dart';
import '../../core/utils/traffic_classifier.dart';
import '../../core/utils/scoring_engine.dart';
import 'hospital_model.dart';

/// Result of a routing computation from ORS API
class RouteResult {
  final List<LatLng> points;
  final Duration baseDuration;       // ORS raw duration
  final Duration adjustedDuration;   // After road_condition delay factors applied
  final double distanceMeters;
  final String hospitalId;
  final String? conditionNote;       // If a road condition affected this route

  const RouteResult({
    required this.points,
    required this.baseDuration,
    required this.adjustedDuration,
    required this.distanceMeters,
    required this.hospitalId,
    this.conditionNote,
  });

  TrafficSeverity get trafficSeverity =>
      TrafficClassifier.classify(baseDuration, adjustedDuration);

  String get etaLabel {
    final mins = adjustedDuration.inMinutes;
    if (mins < 1) return '<1 min';
    return '$mins min';
  }

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  bool get hasCondition => conditionNote != null && conditionNote!.isNotEmpty;
}

/// Ranked hospital with route and score
class RankedHospital {
  final HospitalModel hospital;
  final RouteResult route;
  final ScoreBreakdown score;
  final int rank;
  final String reasoning;

  const RankedHospital({
    required this.hospital,
    required this.route,
    required this.score,
    required this.rank,
    required this.reasoning,
  });
}
