import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/hospital_model.dart';
import '../data/models/road_condition_model.dart';
import '../data/services/firestore_service.dart';

/// Stream of all hospitals from Firestore — auto-updates on load change.
final hospitalsStreamProvider = StreamProvider<List<HospitalModel>>((ref) {
  return FirestoreService().hospitalsStream();
});

/// Stream of active (non-clear) road conditions.
final roadConditionsStreamProvider =
    StreamProvider<List<RoadConditionModel>>((ref) {
  return FirestoreService().roadConditionsStream();
});
