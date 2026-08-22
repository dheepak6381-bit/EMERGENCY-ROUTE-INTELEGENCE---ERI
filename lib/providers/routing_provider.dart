import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/hospital_model.dart';
import '../data/models/route_result_model.dart';
import '../data/models/road_condition_model.dart';
import '../data/services/osrm_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/scoring_engine.dart';
import 'incident_provider.dart';
import 'hospital_provider.dart';
import 'ticker_provider.dart';

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
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      _computeRoutesInternal(hospitalsOverride: hospitalsOverride);
    });
  }

  Future<void> _computeRoutesInternal({List<HospitalModel>? hospitalsOverride}) async {
    final incident = _ref.read(incidentProvider);
    final secIncident = _ref.read(secondaryIncidentProvider);
    final emergencyType = _ref.read(emergencyTypeProvider);
    final conditionsAsync = _ref.read(roadConditionsStreamProvider);

    final hospitals = hospitalsOverride ?? _ref.read(hospitalsStreamProvider).valueOrNull ?? [];
    final conditions = conditionsAsync.valueOrNull ?? [];

    if (hospitals.isEmpty) {
      state = state.copyWith(
        error: 'No hospitals available. Check Firestore connection.',
        isLoading: false,
        hasComputed: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final primaryRes = await _calculateForIncident(incident, hospitals, conditions, emergencyType);

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

    Map<String, Duration> etaMap = {};
    try {
      final hosEntries = limitedHospitals.map((h) => (id: h.id, location: h.location)).toList();
      etaMap = await _osrm.getMatrix(
        origin: incident.location,
        hospitals: hosEntries,
        conditions: conditions,
      );
    } on RateLimitException catch (e) {
      _ref.read(tickerProvider.notifier).addEvent('⚠ Routing service rate-limited — using cached/estimated data');
    } catch (e) {
      // Fallback
    }

    final candidates = <({HospitalModel hospital, Duration eta})>[];
    for (final h in limitedHospitals) {
      Duration eta = etaMap[h.id] ?? const Duration(hours: 2);
      if (etaMap[h.id] == null) {
        final distMeters = distanceCalc.as(LengthUnit.Meter, incident.location, h.location);
        final estimatedSeconds = (distMeters / 50000) * 3600;
        eta = Duration(seconds: estimatedSeconds.round());
      }
      candidates.add((hospital: h, eta: eta));
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
        item.hospital, item.eta, emergencyType, i + 1, top3,
      );

      RouteResult? route;
      if (i == 0) {
        try {
          route = await _osrm.getRoute(
            origin: incident.location,
            destination: item.hospital.location,
            hospitalId: item.hospital.id,
            conditions: conditions,
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

  /// Straight-line fallback when ORS API fails.
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
