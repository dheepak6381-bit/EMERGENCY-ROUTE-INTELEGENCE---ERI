import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';

/// Data model for a dispatched incident audit log entry.
///
/// Written to Firestore's `incidents` collection each time a route
/// is finalized, providing a full audit trail for post-incident review.
class IncidentLogModel {
  final String id;
  final DateTime timestamp;
  final LatLng incidentLocation;
  final String emergencyType;
  final int? victimCount; // Nullable — only set when NLP engine was used
  final String dispatchedHospitalName;
  final String dispatchedHospitalId;
  final double etaMinutes;
  final Map<String, double> scoreBreakdown; // {eta, specialty, capacity}
  final String reasoningString;
  final String? roadConditionNoteIfAny;

  const IncidentLogModel({
    required this.id,
    required this.timestamp,
    required this.incidentLocation,
    required this.emergencyType,
    this.victimCount,
    required this.dispatchedHospitalName,
    required this.dispatchedHospitalId,
    required this.etaMinutes,
    required this.scoreBreakdown,
    required this.reasoningString,
    this.roadConditionNoteIfAny,
  });

  /// Serialize to Firestore document map.
  Map<String, dynamic> toFirestore() => {
        'id': id,
        'timestamp': FieldValue.serverTimestamp(),
        'incident_lat': incidentLocation.latitude,
        'incident_lng': incidentLocation.longitude,
        'emergency_type': emergencyType,
        'victim_count': victimCount,
        'dispatched_hospital_name': dispatchedHospitalName,
        'dispatched_hospital_id': dispatchedHospitalId,
        'eta_minutes': etaMinutes,
        'score_breakdown': scoreBreakdown,
        'reasoning': reasoningString,
        'road_condition_note': roadConditionNoteIfAny,
      };

  /// Deserialize from Firestore document snapshot.
  factory IncidentLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IncidentLogModel(
      id: data['id'] as String? ?? doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      incidentLocation: LatLng(
        (data['incident_lat'] as num?)?.toDouble() ?? 0.0,
        (data['incident_lng'] as num?)?.toDouble() ?? 0.0,
      ),
      emergencyType: data['emergency_type'] as String? ?? 'general',
      victimCount: (data['victim_count'] as num?)?.toInt(),
      dispatchedHospitalName:
          data['dispatched_hospital_name'] as String? ?? 'Unknown',
      dispatchedHospitalId:
          data['dispatched_hospital_id'] as String? ?? '',
      etaMinutes: (data['eta_minutes'] as num?)?.toDouble() ?? 0.0,
      scoreBreakdown: Map<String, double>.from(
        (data['score_breakdown'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      reasoningString: data['reasoning'] as String? ?? '',
      roadConditionNoteIfAny: data['road_condition_note'] as String?,
    );
  }
}
