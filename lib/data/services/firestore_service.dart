import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital_model.dart';
import '../models/road_condition_model.dart';
import '../models/incident_log_model.dart';
import '../../core/constants/app_constants.dart';

/// Wraps all Firestore reads and writes for ERI.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Hospitals ─────────────────────────────────────────────────────────────

  /// Real-time stream of all hospitals in the collection.
  Stream<List<HospitalModel>> hospitalsStream() {
    return _db
        .collection(AppConstants.hospitalsCollection)
        .snapshots()
        .map((snap) =>
            snap.docs.map(HospitalModel.fromFirestore).toList());
  }

  /// Update hospital current_load (used by simulation panel).
  Future<void> updateHospitalLoad(String hospitalId, int load) async {
    await _db
        .collection(AppConstants.hospitalsCollection)
        .doc(hospitalId)
        .update({
      'current_load': load,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  // ── Road Conditions ───────────────────────────────────────────────────────

  /// Real-time stream of all road conditions.
  Stream<List<RoadConditionModel>> roadConditionsStream() {
    return _db
        .collection(AppConstants.roadConditionsCollection)
        .snapshots()
        .map((snap) =>
            snap.docs.map(RoadConditionModel.fromFirestore).toList());
  }

  /// Update a road segment status (used by simulation panel).
  Future<void> updateRoadCondition(
      String segmentId, String status, String note) async {
    await _db
        .collection(AppConstants.roadConditionsCollection)
        .doc(segmentId)
        .update({
      'status': status,
      'note': note,
      'reported_at': FieldValue.serverTimestamp(),
    });
  }

  /// Reset all road conditions to "clear".
  Future<void> resetRoadConditions() async {
    final snap = await _db
        .collection(AppConstants.roadConditionsCollection)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': 'clear',
        'note': '',
        'reported_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Reset all hospital loads to their baseline values.
  Future<void> resetHospitalLoads(Map<String, int> baselines) async {
    final batch = _db.batch();
    baselines.forEach((id, load) {
      batch.update(
        _db.collection(AppConstants.hospitalsCollection).doc(id),
        {
          'current_load': load,
          'last_updated': FieldValue.serverTimestamp(),
        },
      );
    });
    await batch.commit();
  }

  // ── Incident Audit Log ─────────────────────────────────────────────────

  /// Write a dispatched incident audit log entry to Firestore.
  Future<void> logIncident(IncidentLogModel log) async {
    await _db
        .collection(AppConstants.incidentsCollection)
        .doc(log.id)
        .set(log.toFirestore());
  }

  /// Stream the most recent incident logs (for the Audit Log panel).
  Stream<List<IncidentLogModel>> incidentLogsStream({int limit = 10}) {
    return _db
        .collection(AppConstants.incidentsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(IncidentLogModel.fromFirestore).toList());
  }
}
