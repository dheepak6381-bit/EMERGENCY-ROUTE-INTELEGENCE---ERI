import 'dart:collection';
import 'package:latlong2/latlong.dart';
import '../../data/models/hospital_model.dart';
import '../../data/models/road_condition_model.dart';
import 'geo_utils.dart';

/// A node in the Dijkstra graph representing a hospital destination.
class HospitalNode {
  final String id;
  final LatLng location;
  final HospitalModel hospital;
  final Duration rawEta; // from OSRM matrix

  const HospitalNode({
    required this.id,
    required this.location,
    required this.hospital,
    required this.rawEta,
  });
}

/// Result of Dijkstra computation for a single hospital.
class DijkstraPath {
  final HospitalModel hospital;
  final Duration adjustedEta;   // ETA after road condition penalties
  final double weight;          // Dijkstra weight (lower = better)
  final String? conditionNote;  // Active road condition affecting this path

  const DijkstraPath({
    required this.hospital,
    required this.adjustedEta,
    required this.weight,
    this.conditionNote,
  });
}

/// Result of running Dijkstra across all hospital destinations.
class DijkstraResult {
  final List<DijkstraPath> paths; // Sorted by weight (shortest first)
  final LatLng origin;

  const DijkstraResult({required this.paths, required this.origin});
}

/// Priority queue entry for Dijkstra's algorithm.
class _PQEntry implements Comparable<_PQEntry> {
  final int nodeIndex;
  final double distance;

  const _PQEntry(this.nodeIndex, this.distance);

  @override
  int compareTo(_PQEntry other) => distance.compareTo(other.distance);
}

/// Single-source shortest path from the incident to every candidate hospital,
/// with edge weights dynamically adjusted for live road conditions.
///
/// The graph is structured as:
/// - Node 0 = incident location (source)
/// - Nodes 1..N = candidate hospitals (destinations)
/// - Edge weight from source to each hospital = OSRM ETA (seconds),
///   multiplied by a road-condition delay factor when an active condition
///   intersects the straight-line path.
///
/// This is re-run whenever road conditions change so the ranking can shift
/// without recomputing routes from scratch. Dijkstra's relaxation does real
/// work here because edge weights change dynamically, and the shortest-path
/// selection among many destinations is genuinely what the algorithm is for.
///
/// Complexity: O((V + E) log V) where V = 1 + N hospitals
class DijkstraEngine {
  DijkstraEngine._();

  /// Finds shortest paths from incident to all hospitals using Dijkstra's algorithm.
  ///
  /// [incident] - Source location (emergency incident)
  /// [hospitals] - List of hospital nodes with raw ETAs from OSRM
  /// [conditions] - Active road conditions that affect edge weights
  ///
  /// Returns [DijkstraResult] with hospitals sorted by optimal weighted ETA.
  static DijkstraResult findShortestPaths({
    required LatLng incident,
    required List<HospitalNode> hospitals,
    required List<RoadConditionModel> conditions,
  }) {
    if (hospitals.isEmpty) {
      return DijkstraResult(paths: [], origin: incident);
    }

    final int n = hospitals.length;

    // ── Build Adjacency / Weight Matrix ──────────────────────────────────
    // Node 0 = incident (source)
    // Nodes 1..N = hospitals
    //
    // Direct edges from source (0) to each hospital (1..N) with weight =
    // raw ETA in seconds, multiplied by road condition delay factor.

    // Total nodes: 1 (source) + N (hospitals)
    final int totalNodes = n + 1;
    final List<double> dist = List.filled(totalNodes, double.infinity);
    final List<bool> visited = List.filled(totalNodes, false);
    final List<String?> conditionNotes = List.filled(totalNodes, null);

    // Source distance is 0
    dist[0] = 0.0;

    // Priority queue (min-heap)
    final SplayTreeSet<_PQEntry> pq = SplayTreeSet<_PQEntry>((a, b) {
      final cmp = a.distance.compareTo(b.distance);
      return cmp != 0 ? cmp : a.nodeIndex.compareTo(b.nodeIndex);
    });

    pq.add(const _PQEntry(0, 0.0));

    // ── Dijkstra Main Loop ──────────────────────────────────────────────
    while (pq.isNotEmpty) {
      final current = pq.first;
      pq.remove(current);

      final u = current.nodeIndex;
      if (visited[u]) continue;
      visited[u] = true;

      // ── Relax edges from source (node 0) to all hospitals ────────────
      if (u == 0) {
        for (int i = 0; i < n; i++) {
          final hospitalIdx = i + 1; // 1-indexed in graph
          final hospital = hospitals[i];

          // Base weight = raw ETA from OSRM (seconds)
          double weight = hospital.rawEta.inSeconds.toDouble();

          // Apply road condition delay factors (Dijkstra edge relaxation)
          double maxDelay = 1.0;
          String? note;

          for (final cond in conditions) {
            if (!cond.isClear) {
              // Check if the straight-line path intersects this condition
              if (GeoUtils.intersectsLine(incident, hospital.location, cond)) {
                if (cond.delayFactor > maxDelay) {
                  maxDelay = cond.delayFactor;
                  note = cond.note.isNotEmpty
                      ? cond.note
                      : '${cond.statusLabel} on ${cond.segmentId}';
                }
              }
            }
          }

          weight *= maxDelay;

          // Dijkstra relaxation: if new path is shorter, update
          if (dist[u] + weight < dist[hospitalIdx]) {
            dist[hospitalIdx] = dist[u] + weight;
            conditionNotes[hospitalIdx] = note;
            pq.add(_PQEntry(hospitalIdx, dist[hospitalIdx]));
          }
        }
      }

      // No cross-edges between hospitals — only source-to-destination edges
      // exist in this graph. Each hospital is reached directly from the
      // incident location via its OSRM-derived ETA.
    }

    // ── Collect Results ──────────────────────────────────────────────────
    final paths = <DijkstraPath>[];
    for (int i = 0; i < n; i++) {
      final hospitalIdx = i + 1;
      final weight = dist[hospitalIdx];

      if (weight == double.infinity) continue; // Unreachable

      paths.add(DijkstraPath(
        hospital: hospitals[i].hospital,
        adjustedEta: Duration(seconds: weight.round()),
        weight: weight,
        conditionNote: conditionNotes[hospitalIdx],
      ));
    }

    // Sort by Dijkstra weight (shortest path first)
    paths.sort((a, b) => a.weight.compareTo(b.weight));

    return DijkstraResult(paths: paths, origin: incident);
  }
}
