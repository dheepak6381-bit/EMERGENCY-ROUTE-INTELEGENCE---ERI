import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:eri/core/utils/traffic_classifier.dart';

void main() {
  group('TrafficClassifier', () {
    test('returns light traffic when ratio is under 1.1', () {
      final base = const Duration(minutes: 10);
      final adjusted = const Duration(minutes: 10, seconds: 30); // 1.05x
      final severity = TrafficClassifier.classify(base, adjusted);
      expect(severity, equals(TrafficSeverity.light));
    });

    test('returns moderate traffic when ratio is between 1.1 and 1.3', () {
      final base = const Duration(minutes: 10);
      final adjusted = const Duration(minutes: 12); // 1.2x
      final severity = TrafficClassifier.classify(base, adjusted);
      expect(severity, equals(TrafficSeverity.moderate));
    });

    test('returns heavy traffic when ratio is 1.3 or above', () {
      final base = const Duration(minutes: 10);
      final adjusted = const Duration(minutes: 14); // 1.4x
      final severity = TrafficClassifier.classify(base, adjusted);
      expect(severity, equals(TrafficSeverity.heavy));
    });

    test('returns heavy traffic when delay is over 100%', () {
      final base = const Duration(minutes: 10);
      final adjusted = const Duration(minutes: 25); // 2.5x
      final severity = TrafficClassifier.classify(base, adjusted);
      expect(severity, equals(TrafficSeverity.heavy));
    });

    test('label matches severity', () {
      expect(TrafficClassifier.label(TrafficSeverity.light), equals('Light'));
      expect(TrafficClassifier.label(TrafficSeverity.moderate), equals('Moderate'));
      expect(TrafficClassifier.label(TrafficSeverity.heavy), equals('Heavy'));
    });
  });
}
