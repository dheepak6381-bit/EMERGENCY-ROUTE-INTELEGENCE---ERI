import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:eri/data/services/osrm_service.dart';
import 'package:eri/data/models/road_condition_model.dart';

void main() {
  group('Routing Fallback Logic', () {
    test('OsrmService getRoute throws when simulateFailure is true', () async {
      final service = OsrmService();
      service.simulateFailure = true;

      expect(
        () => service.getRoute(
          origin: const LatLng(9.5, 77.9),
          destination: const LatLng(9.6, 78.0),
          hospitalId: 'test_hosp',
          conditions: [],
        ),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('OsrmService getMatrix throws when simulateFailure is true', () async {
      final service = OsrmService();
      service.simulateFailure = true;

      expect(
        () => service.getMatrix(
          origin: const LatLng(9.5, 77.9),
          hospitals: [(id: 'test_hosp', location: const LatLng(9.6, 78.0))],
          conditions: [],
        ),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
