import '../../app/theme/color_palette.dart';
import 'package:flutter/material.dart';

enum TrafficSeverity { light, moderate, heavy }

class TrafficClassifier {
  TrafficClassifier._();

  /// Classify traffic given base ORS duration vs Firestore-adjusted duration.
  /// [baseDuration] — ORS raw duration (no congestion applied)
  /// [adjustedDuration] — duration after applying road_conditions delay factors
  static TrafficSeverity classify(
    Duration baseDuration,
    Duration adjustedDuration,
  ) {
    if (baseDuration.inSeconds == 0) return TrafficSeverity.light;
    final ratio =
        adjustedDuration.inSeconds / baseDuration.inSeconds.toDouble();
    if (ratio >= 1.3) return TrafficSeverity.heavy;
    if (ratio >= 1.1) return TrafficSeverity.moderate;
    return TrafficSeverity.light;
  }

  static String label(TrafficSeverity severity) {
    switch (severity) {
      case TrafficSeverity.light:
        return 'Light';
      case TrafficSeverity.moderate:
        return 'Moderate';
      case TrafficSeverity.heavy:
        return 'Heavy';
    }
  }

  static Color color(TrafficSeverity severity) {
    switch (severity) {
      case TrafficSeverity.light:
        return AppColors.statusGreen;
      case TrafficSeverity.moderate:
        return AppColors.statusAmber;
      case TrafficSeverity.heavy:
        return AppColors.statusRed;
    }
  }
}
