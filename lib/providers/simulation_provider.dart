import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/firestore_service.dart';
import '../data/models/hospital_model.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'hospital_provider.dart';
import 'routing_provider.dart';
import 'ticker_provider.dart';
import 'incident_provider.dart';

/// Controls the Ops Control (simulation) panel visibility
final simulationPanelVisibleProvider = StateProvider<bool>((ref) => false);

/// Tracks baseline hospital loads for reset
final _baselineLoadsProvider = StateProvider<Map<String, int>>((ref) => {});

class SimulationNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final FirestoreService _fs = FirestoreService();

  SimulationNotifier(this._ref) : super(false);

  /// Store baseline loads when hospitals first load (for reset)
  void captureBaseline(List<HospitalModel> hospitals) {
    final current = _ref.read(_baselineLoadsProvider);
    if (current.isEmpty) {
      final baselines = {for (var h in hospitals) h.id: h.currentLoad};
      _ref.read(_baselineLoadsProvider.notifier).state = baselines;
    }
  }

  /// Spike a hospital's load to 95% — simulates capacity crisis
  Future<void> spikeHospitalLoad(HospitalModel hospital) async {
    await _fs.updateHospitalLoad(hospital.id, 95);
    _ref.read(tickerProvider.notifier).addEvent(
      '⚠ ${hospital.name} now at 95% capacity — recommendation may switch',
      isWarning: true,
    );
    // Recompute routes to reflect new ranking
    await _ref.read(routingProvider.notifier).computeRoutes();
  }

  /// Block a road segment — simulates construction/accident
  Future<void> blockRoadSegment(String segmentId, String segmentName) async {
    await _fs.updateRoadCondition(
      segmentId,
      'construction',
      'Road blocked — construction reported at $segmentName. Expect delays.',
    );
    _ref.read(tickerProvider.notifier).addEvent(
      '⚠ Route updated — construction detected on $segmentName, +20% ETA added',
      isWarning: true,
    );
    await _ref.read(routingProvider.notifier).computeRoutes();
  }

  /// Mark road as congested
  Future<void> markRoadCongested(String segmentId, String segmentName) async {
    await _fs.updateRoadCondition(
      segmentId,
      'congested',
      'Heavy traffic reported on $segmentName. +35% delay expected.',
    );
    _ref.read(tickerProvider.notifier).addEvent(
      '⚠ Congestion on $segmentName — routing adjusted, +35% ETA',
      isWarning: true,
    );
    await _ref.read(routingProvider.notifier).computeRoutes();
  }

  /// Reset all simulated conditions
  Future<void> resetAll() async {
    final baselines = _ref.read(_baselineLoadsProvider);
    await _fs.resetRoadConditions();
    if (baselines.isNotEmpty) {
      await _fs.resetHospitalLoads(baselines);
    }
    _ref.read(tickerProvider.notifier).addEvent(
      '✓ All conditions reset — routing restored to baseline',
      isWarning: false,
    );
    await _ref.read(routingProvider.notifier).computeRoutes();
  }

  /// Simulate 6:15 PM Rush Hour scenario (Hackathon preset)
  Future<void> simulateRushHour() async {
    // 1. Find nearest hospital to spike load
    final incident = _ref.read(incidentProvider);
    final hospitals = _ref.read(hospitalsStreamProvider).valueOrNull ?? [];
    if (hospitals.isNotEmpty) {
      final distanceCalc = const latlong2.Distance();
      var nearest = hospitals.first;
      var minDist = distanceCalc.as(latlong2.LengthUnit.Meter, incident.location, nearest.location);
      for (var h in hospitals) {
        final dist = distanceCalc.as(latlong2.LengthUnit.Meter, incident.location, h.location);
        if (dist < minDist) {
          minDist = dist;
          nearest = h;
        }
      }
      await _fs.updateHospitalLoad(nearest.id, 95);
    }

    // 2. Block and congest roads
    final conditions = _ref.read(roadConditionsStreamProvider).valueOrNull ?? [];
    if (conditions.length >= 2) {
      await _fs.updateRoadCondition(
        conditions[0].id,
        'construction',
        'Road blocked — construction reported at ${conditions[0].segmentId}. Expect delays.',
      );
      await _fs.updateRoadCondition(
        conditions[1].id,
        'congested',
        'Heavy traffic reported on ${conditions[1].segmentId}. +35% delay expected.',
      );
    }

    _ref.read(tickerProvider.notifier).addEvent(
      '⚠ 6:15 PM Rush Hour Simulated: High capacity at nearest hospital & heavy traffic.',
      isWarning: true,
    );
    await _ref.read(routingProvider.notifier).computeRoutes();
  }
}

final simulationProvider =
    StateNotifierProvider<SimulationNotifier, bool>((ref) {
  return SimulationNotifier(ref);
});
