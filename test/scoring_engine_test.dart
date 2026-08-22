import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:eri/core/utils/scoring_engine.dart';
import 'package:eri/data/models/hospital_model.dart';
import 'package:eri/core/constants/app_constants.dart';

void main() {
  group('ScoringEngine Tests', () {
    final hospitalA = HospitalModel(
      id: 'hA',
      name: 'Hospital A',
      location: const LatLng(0, 0),
      specialties: ['cardiac', 'trauma'],
      emergencyTypesAccepted: ['cardiac'],
      bedCapacity: 100,
      currentLoad: 50,
    );

    final hospitalB = HospitalModel(
      id: 'hB',
      name: 'Hospital B',
      location: const LatLng(0, 0),
      specialties: ['burns'],
      emergencyTypesAccepted: ['burns'],
      bedCapacity: 100,
      currentLoad: 80,
    );

    test('Reasoning string generation for rank 1 with alternative', () {
      final allCandidates = <({HospitalModel hospital, Duration eta})>[
        (hospital: hospitalA, eta: const Duration(minutes: 10)),
        (hospital: hospitalB, eta: const Duration(minutes: 15)),
      ];

      final reasoning = ScoringEngine.reasoningString(
        hospitalA,
        const Duration(minutes: 10),
        EmergencyType.cardiac,
        1,
        allCandidates,
      );

      expect(reasoning, contains('5 min closer than nearest alternative'));
      expect(reasoning, contains('accepts cardiac cases'));
      expect(reasoning, contains('50% capacity available'));
    });

    test('Reasoning string generation for rank 2', () {
      final reasoning = ScoringEngine.reasoningString(
        hospitalA,
        const Duration(minutes: 10),
        EmergencyType.cardiac,
        2,
        [],
      );

      expect(reasoning, contains('Has Cardiac capability'));
      expect(reasoning, contains('10 min ETA'));
      expect(reasoning, contains('50% free'));
    });
    
    test('Reasoning string generation for backup (rank 3+)', () {
      final reasoning = ScoringEngine.reasoningString(
        hospitalB,
        const Duration(minutes: 20),
        EmergencyType.cardiac,
        3,
        [],
      );

      expect(reasoning, contains('Backup option: 20 min ETA'));
      expect(reasoning, contains('80% current load'));
    });
  });
}
