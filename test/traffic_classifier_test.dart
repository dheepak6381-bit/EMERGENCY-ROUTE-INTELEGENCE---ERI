import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:eri/core/utils/traffic_classifier.dart';

void main() {
  group('TrafficClassifier', () {
    test('returns light traffic when delay is under 20%', () {
      final base = const Duration(minutes: 10);
      final adjusted = const Duration(minutes: 11);
      final severity = TrafficClassifier.classify(base, adjusted);
      expect(severity, equals(TrafficSeverity.light));
    });

    test('returns moderate traffic when delay is between 20% and 50%', () {
      final base = const Duration(minutes: 10);
      final adjusted = const Duration(minutes: 14);
      final severity = TrafficClassifier.classify(base, adjusted);
      expect(severity, equals(TrafficSeverity.moderate));
    });

    test('returns heavy traffic when delay is over 50%', () {
      final base = const Duration(minutes: 10);
      final adjusted = const Duration(minutes: 16);
      final severity = TrafficClassifier.classify(base, adjusted);
      expect(severity, equals(TrafficSeverity.heavy));
    });

    test('returns severe traffic when delay is over 100%', () {
      final base = const Duration(minutes: 10);
      final adjusted = const Duration(minutes: 25);
      final severity = TrafficClassifier.classify(base, adjusted);
      expect(severity, equals(TrafficSeverity.severe));
    });

    test('label matches severity', () {
      expect(TrafficClassifier.label(TrafficSeverity.light), equals('Light Traffic'));
      expect(TrafficClassifier.label(TrafficSeverity.moderate), equals('Moderate Traffic'));
      expect(TrafficClassifier.label(TrafficSeverity.heavy), equals('Heavy Traffic'));
      expect(TrafficClassifier.label(TrafficSeverity.severe), equals('Severe Traffic'));
    });
  });
}
