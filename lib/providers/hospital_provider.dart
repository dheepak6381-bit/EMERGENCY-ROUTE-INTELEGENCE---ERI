import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/hospital_model.dart';
import '../data/models/road_condition_model.dart';
import '../data/services/firestore_service.dart';
import '../data/services/overpass_service.dart';
import '../data/tn_hospitals_fallback.dart';
import '../data/local_hospital_data.dart';

final overpassServiceProvider = Provider<OverpassService>((ref) {
  return OverpassService();
});

final tnHospitalsFallbackProvider = Provider<List<HospitalModel>>((ref) {
  return TNHospitalsFallback.hospitals;
});

/// Stream of all hospitals from Firestore — auto-updates on load change.
/// Falls back to local hardcoded data if Firestore is empty or fails.
/// This is mainly used by the dashboard UI for statistics, not for routing.
final hospitalsStreamProvider = StreamProvider<List<HospitalModel>>((ref) {
  return FirestoreService().hospitalsStream().map((hospitals) {
    if (hospitals.isEmpty) {
      return LocalHospitalData.hospitals;
    }
    return hospitals;
  }).handleError((_) {
    return LocalHospitalData.hospitals;
  });
});

/// Stream of active (non-clear) road conditions.
final roadConditionsStreamProvider =
    StreamProvider<List<RoadConditionModel>>((ref) {
  return FirestoreService().roadConditionsStream();
});
