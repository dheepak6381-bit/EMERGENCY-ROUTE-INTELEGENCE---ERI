/// Central constants for the ERI application.
/// All scoring weights, radii, timeouts defined here for easy tuning.
import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  // ── Demo / Seed Location ──────────────────────────────────────────────────
  /// Kalasalingam Academy of Research and Education, Krishnankoil, Tamil Nadu
  static const LatLng kareLocation = LatLng(9.4145, 77.7050);
  static const String kareLocationName =
      'Kalasalingam Academy of Research & Education';

  // ── Hospital Scoring Weights (must sum to 1.0) ──────────────────────────
  static const double wEta = 0.50;        // Fastest ETA gets highest score
  static const double wSpecialty = 0.30;  // Specialty match bonus
  static const double wCapacity = 0.20;   // Available capacity score

  // ── Search Radius ─────────────────────────────────────────────────────────
  static const double hospitalSearchRadiusKm = 120.0;

  // ── Traffic Classification Thresholds ────────────────────────────────────
  /// Duration multiplier above which traffic is rated Heavy (>30% delay)
  static const double heavyTrafficMultiplier = 1.3;

  /// Duration multiplier above which traffic is rated Moderate (>10% delay)
  static const double moderateTrafficMultiplier = 1.1;

  // ── Road Condition Delay Factors ──────────────────────────────────────────
  static const double congestedDelayFactor = 1.35;    // +35% ETA
  static const double constructionDelayFactor = 1.20; // +20% ETA

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration routeDrawDuration = Duration(milliseconds: 900);
  static const Duration cardReorderDuration = Duration(milliseconds: 400);
  static const Duration tickerDisplayDuration = Duration(seconds: 8);
  static const Duration tickerFadeDuration = Duration(milliseconds: 500);

  // ── Map Config ────────────────────────────────────────────────────────────
  static const double defaultZoom = 11.5;
  static const double incidentZoom = 13.0;
  static const String osmTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String osmUserAgent = 'com.eri.app/1.0';

  // ── OSRM API ──────────────────────────────────────────────────────────────
  static const String osrmBaseUrl = 'https://routing.openstreetmap.de/routed-car';

  // ── Nominatim ─────────────────────────────────────────────────────────────
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  // ── Firestore Collections ─────────────────────────────────────────────────
  static const String hospitalsCollection = 'hospitals';
  static const String roadConditionsCollection = 'road_conditions';
  static const String incidentsCollection = 'incidents';
}

/// Emergency types supported by ERI
enum EmergencyType {
  cardiac('Cardiac', '❤️', 'cardiac', 'Time-critical: minimize ETA'),
  trauma('Trauma', '🩹', 'trauma', 'Time-critical: prioritize level-1 trauma centers'),
  burns('Burns', '🔥', 'burns', 'Prioritize burns-capable facility'),
  respiratory('Respiratory', '💨', 'respiratory', 'Ensure ventilator availability'),
  general('General', '🏥', 'general', '');

  const EmergencyType(this.label, this.emoji, this.firestoreKey, this.urgencyFraming);
  final String label;
  final String emoji;
  final String firestoreKey;
  final String urgencyFraming;
}
