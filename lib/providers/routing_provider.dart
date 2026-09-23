import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../data/models/hospital_model.dart';
import '../data/models/route_result_model.dart';
import '../data/models/road_condition_model.dart';
import '../data/models/incident_log_model.dart';
import '../data/services/osrm_service.dart';
import '../data/services/firestore_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/scoring_engine.dart';
import '../core/utils/dijkstra_engine.dart';
import 'incident_provider.dart';
import 'hospital_provider.dart';
import 'ticker_provider.dart';
import '../data/services/local_database_service.dart';

/// State for the routing computation
class RoutingState {
  final List<RankedHospital> rankedHospitals;
  final RouteResult? selectedRoute; // route to the top-ranked hospital
  final List<RankedHospital> secondaryRankedHospitals;
  final RouteResult? secondaryRoute; // route for second incident
  final bool isLoading;
  final String? error;
  final bool hasComputed;

  const RoutingState({
    required this.rankedHospitals,
    this.selectedRoute,
    this.secondaryRankedHospitals = const [],
    this.secondaryRoute,
    required this.isLoading,
    this.error,
    required this.hasComputed,
  });

  static const RoutingState initial = RoutingState(
    rankedHospitals: [],
    isLoading: false,
    hasComputed: false,
  );

  RoutingState copyWith({
    List<RankedHospital>? rankedHospitals,
    RouteResult? selectedRoute,
    List<RankedHospital>? secondaryRankedHospitals,
    RouteResult? secondaryRoute,
    bool? isLoading,
    String? error,
    bool? hasComputed,
  }) =>
      RoutingState(
        rankedHospitals: rankedHospitals ?? this.rankedHospitals,
        selectedRoute: selectedRoute ?? this.selectedRoute,
        secondaryRankedHospitals: secondaryRankedHospitals ?? this.secondaryRankedHospitals,
        secondaryRoute: secondaryRoute ?? this.secondaryRoute,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        hasComputed: hasComputed ?? this.hasComputed,
      );
}

class RoutingNotifier extends StateNotifier<RoutingState> {
  final Ref _ref;
  final OsrmService _osrm = OsrmService();

  RoutingNotifier(this._ref) : super(RoutingState.initial);

  Timer? _debounce;

  Future<void> computeRoutes({List<HospitalModel>? hospitalsOverride}) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _computeRoutesInternal(hospitalsOverride: hospitalsOverride);
    });
  }

  Future<void> _computeRoutesInternal({List<HospitalModel>? hospitalsOverride}) async {
    final incident = _ref.read(incidentProvider);
    final secIncident = _ref.read(secondaryIncidentProvider);
    final emergencyType = _ref.read(emergencyTypeProvider);
    final conditionsAsync = _ref.read(roadConditionsStreamProvider);
    final conditions = conditionsAsync.valueOrNull ?? [];

    // ── Dynamic Hospital Discovery (Live + Offline 70k) ────────────
    var hospitals = <HospitalModel>[];
    try {
      final overpass = _ref.read(overpassServiceProvider);
      hospitals = await overpass.fetchLiveHospitals(
        incidentLocation: incident.location,
        radiusKm: 30.0,
      );
      if (hospitals.length < 5) {
        _ref.read(tickerProvider.notifier).addEvent('Expanding live search radius to 100km...');
        hospitals = await overpass.fetchLiveHospitals(
          incidentLocation: incident.location,
          radiusKm: 100.0,
        );
      }
    } catch (e) {
      _ref.read(tickerProvider.notifier).addEvent('⚠ Network timeout. Initializing Offline 70k Database...', isWarning: true);
    }

    // Master Offline Fallback (70,000 Hospitals Database)
    if (hospitals.isEmpty) {
      hospitals = await LocalDatabaseService.instance.searchNearbyOffline(
        location: incident.location,
        radiusKm: 150.0, // Expand radius for offline to guarantee finding something
      );
      if (hospitals.isNotEmpty) {
        _ref.read(tickerProvider.notifier).addEvent('✓ Offline Mode: Found \${hospitals.length} hospitals in master database');
      }
    }
    
    // Ultimate Fallback to Hardcoded List if JSON missing
    if (hospitals.isEmpty) {
      hospitals = _ref.read(tnHospitalsFallbackProvider);
    }
    
    // Mix in provided overrides (e.g. from tests or manual selection)
    if (hospitalsOverride != null && hospitalsOverride.isNotEmpty) {
      hospitals = hospitalsOverride;
    }

    if (hospitals.isEmpty) {
      state = state.copyWith(
        error: 'No hospitals available. Please check internet connection.',
        isLoading: false,
        hasComputed: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final primaryRes = await _calculateForIncident(incident, hospitals, conditions, emergencyType);

    // ── Incident Audit Log ──────────────────────────────────────────────
    // Write to Firestore for post-incident review. Wrapped in try/catch
    // so a logging failure never blocks the dispatcher UI.
    if (primaryRes.$1.isNotEmpty) {
      try {
        final topRanked = primaryRes.$1.first;
        final log = IncidentLogModel(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          incidentLocation: incident.location,
          emergencyType: emergencyType.label,
          victimCount: null, // Set by NLP engine if used
          dispatchedHospitalName: topRanked.hospital.name,
          dispatchedHospitalId: topRanked.hospital.id,
          etaMinutes: topRanked.route.adjustedDuration.inMinutes.toDouble(),
          scoreBreakdown: {
            'eta': topRanked.score.etaScore,
            'specialty': topRanked.score.specialtyScore,
            'capacity': topRanked.score.capacityScore,
          },
          reasoningString: topRanked.reasoning,
          roadConditionNoteIfAny: null,
        );
        FirestoreService().logIncident(log); // fire-and-forget
      } catch (e) {
        // Silent — logging must never block dispatch
      }
    }

    List<RankedHospital> secondaryRanked = [];
    RouteResult? secondaryRoute;

    if (secIncident != null) {
      final topHosp = primaryRes.$1.isNotEmpty ? primaryRes.$1.first.hospital : null;
      final adjustedHospitals = hospitals.map((h) {
        if (topHosp != null && h.id == topHosp.id) {
          // Inflate load to prevent double booking
          return h.copyWith(currentLoad: h.currentLoad + 35);
        }
        return h;
      }).toList();

      final secRes = await _calculateForIncident(secIncident, adjustedHospitals, conditions, emergencyType);
      secondaryRanked = secRes.$1;
      secondaryRoute = secRes.$2;
    }

    state = state.copyWith(
      rankedHospitals: primaryRes.$1,
      selectedRoute: primaryRes.$2,
      secondaryRankedHospitals: secondaryRanked,
      secondaryRoute: secondaryRoute,
      isLoading: false,
      hasComputed: true,
      error: null,
    );
  }

  Future<(List<RankedHospital>, RouteResult?)> _calculateForIncident(
    IncidentState incident,
    List<HospitalModel> hospitals,
    List<RoadConditionModel> conditions,
    EmergencyType emergencyType,
  ) async {
    final distanceCalc = const Distance();
    final allHospitals = List<HospitalModel>.from(hospitals);
    allHospitals.sort((a, b) {
      final distA = distanceCalc.as(LengthUnit.Meter, incident.location, a.location);
      final distB = distanceCalc.as(LengthUnit.Meter, incident.location, b.location);
      return distA.compareTo(distB);
    });
    final limitedHospitals = allHospitals.take(49).toList();

    // ── Step 1: Get raw ETAs from OSRM ─────────────────────────────────
    Map<String, Duration> etaMap = {};
    try {
      final hosEntries = limitedHospitals.map((h) => (id: h.id, location: h.location)).toList();
      etaMap = await _osrm.getMatrix(
        origin: incident.location,
        hospitals: hosEntries,
        conditions: conditions,
      );
    } on RateLimitException catch (e) {
      _ref.read(tickerProvider.notifier).addEvent('⚠ Routing service rate-limited — using estimated data');
    } catch (e) {
      // Fallback to distance-based estimation
    }

    // ── Step 2: Build Dijkstra nodes ────────────────────────────────────
    final dijkstraNodes = <HospitalNode>[];
    for (final h in limitedHospitals) {
      Duration rawEta = etaMap[h.id] ?? const Duration(hours: 2);
      if (etaMap[h.id] == null) {
        // Haversine distance-based fallback ETA
        final distMeters = distanceCalc.as(LengthUnit.Meter, incident.location, h.location);
        final estimatedSeconds = (distMeters / 50000) * 3600; // 50 km/h avg
        rawEta = Duration(seconds: estimatedSeconds.round());
      }
      dijkstraNodes.add(HospitalNode(
        id: h.id,
        location: h.location,
        hospital: h,
        rawEta: rawEta,
      ));
    }

    // ── Step 3: Run Dijkstra's Algorithm ────────────────────────────────
    final dijkstraResult = DijkstraEngine.findShortestPaths(
      incident: incident.location,
      hospitals: dijkstraNodes,
      conditions: conditions,
    );

    _ref.read(tickerProvider.notifier).addEvent(
      '✓ Dijkstra computed — ${dijkstraResult.paths.length} hospitals evaluated',
    );

    // ── Step 4: Score & Rank (Dijkstra ETA + Specialty + Capacity) ──────
    final candidates = <({HospitalModel hospital, Duration eta, String? condNote})>[];
    for (final path in dijkstraResult.paths) {
      candidates.add((
        hospital: path.hospital,
        eta: path.adjustedEta,
        condNote: path.conditionNote,
      ));
    }

    candidates.sort((a, b) {
      final scoreA = ScoringEngine.score(a.hospital, a.eta, emergencyType);
      final scoreB = ScoringEngine.score(b.hospital, b.eta, emergencyType);
      return scoreB.total.compareTo(scoreA.total);
    });

    final top3 = candidates.take(3).toList();
    final ranked = <RankedHospital>[];
    RouteResult? primaryRoute;

    for (int i = 0; i < top3.length; i++) {
      final item = top3[i];
      final score = ScoringEngine.score(item.hospital, item.eta, emergencyType);
      final reasoning = ScoringEngine.reasoningString(
        item.hospital, item.eta, emergencyType, i + 1,
        top3.map((c) => (hospital: c.hospital, eta: c.eta)).toList(),
      );

      RouteResult? route;
      if (i == 0) {
        try {
          route = await _osrm.getRoute(
            origin: incident.location,
            destination: item.hospital.location,
            hospitalId: item.hospital.id,
            conditions: conditions.toList(),
          );
        } catch (_) {}
        primaryRoute = route;
        route ??= _fallbackRoute(incident.location, item.hospital.location, item.hospital.id, item.eta);
      }

      ranked.add(RankedHospital(
        hospital: item.hospital,
        route: route ?? _fallbackRoute(incident.location, item.hospital.location, item.hospital.id, item.eta),
        score: score,
        rank: i + 1,
        reasoning: reasoning,
      ));
    }

    return (ranked, primaryRoute ?? (ranked.isNotEmpty ? ranked.first.route : null));
  }

  /// Straight-line fallback when OSRM API fails.
  RouteResult _fallbackRoute(
    LatLng origin,
    LatLng destination,
    String hospitalId,
    Duration eta,
  ) {
    return RouteResult(
      points: [origin, destination],
      baseDuration: eta,
      adjustedDuration: eta,
      distanceMeters: const Distance().as(
        LengthUnit.Meter,
        origin,
        destination,
      ),
      hospitalId: hospitalId,
    );
  }
}

final routingProvider =
    StateNotifierProvider<RoutingNotifier, RoutingState>((ref) {
  return RoutingNotifier(ref);
});
