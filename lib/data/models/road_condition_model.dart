import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Firestore document model for road_conditions/{id}
class RoadConditionModel {
  final String id;
  final String segmentId;
  final String status; // "clear" | "congested" | "construction"
  final LatLng centerPoint; // approximate center of affected segment
  final List<LatLng> bounds; // polygon or line representing affected road
  final DateTime? reportedAt;
  final String note; // human-readable reason shown in tooltip

  const RoadConditionModel({
    required this.id,
    required this.segmentId,
    required this.status,
    required this.centerPoint,
    required this.bounds,
    this.reportedAt,
    required this.note,
  });

  factory RoadConditionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse bounds as list of {lat, lng} maps
    final rawBounds = data['bounds'] as List<dynamic>? ?? [];
    final bounds = rawBounds
        .map((b) => LatLng(
              (b['lat'] as num?)?.toDouble() ?? 0.0,
              (b['lng'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();

    return RoadConditionModel(
      id: doc.id,
      segmentId: data['segment_id'] as String? ?? doc.id,
      status: data['status'] as String? ?? 'clear',
      centerPoint: LatLng(
        (data['center_lat'] as num?)?.toDouble() ?? 0.0,
        (data['center_lng'] as num?)?.toDouble() ?? 0.0,
      ),
      bounds: bounds,
      reportedAt: (data['reported_at'] as Timestamp?)?.toDate(),
      note: data['note'] as String? ?? '',
    );
  }

  bool get isClear => status == 'clear';
  bool get isCongested => status == 'congested';
  bool get isConstruction => status == 'construction';

  /// Delay factor to apply to ETA calculations
  double get delayFactor {
    switch (status) {
      case 'congested':
        return 1.35;
      case 'construction':
        return 1.20;
      default:
        return 1.0;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'congested':
        return 'Congested';
      case 'construction':
        return 'Under Construction';
      default:
        return 'Clear';
    }
  }
}
