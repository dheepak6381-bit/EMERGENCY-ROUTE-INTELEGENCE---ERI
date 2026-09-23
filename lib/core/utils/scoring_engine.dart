import '../../data/models/hospital_model.dart';
import '../../core/constants/app_constants.dart';

/// Hospital ranking score formula (spec §3.2):
///   score = w1*(1/ETA) + w2*(specialty_match) + w3*(1 - current_load/100)
///
/// Weights (AppConstants): wEta=0.5, wSpecialty=0.3, wCapacity=0.2
class ScoreBreakdown {
  final double total;
  final double etaScore;
  final double specialtyScore;
  final double capacityScore;
  final double maxWEta;
  final double maxWSpecialty;
  final double maxWCapacity;

  const ScoreBreakdown({
    required this.total,
    required this.etaScore,
    required this.specialtyScore,
    required this.capacityScore,
    required this.maxWEta,
    required this.maxWSpecialty,
    required this.maxWCapacity,
  });
}

class ScoringEngine {
  ScoringEngine._();

  /// Returns score breakdown with severity-adaptive weights.
  static ScoreBreakdown score(
    HospitalModel hospital,
    Duration eta,
    EmergencyType emergencyType,
  ) {
    double wEta = AppConstants.wEta;
    double wSpecialty = AppConstants.wSpecialty;
    double wCapacity = AppConstants.wCapacity;

    if (emergencyType.firestoreKey == 'cardiac' || emergencyType.firestoreKey == 'trauma') {
      wEta = 0.65;
      wSpecialty = 0.20;
      wCapacity = 0.15;
    } else if (emergencyType.firestoreKey == 'burns' || emergencyType.firestoreKey == 'respiratory') {
      wEta = 0.50;
      wSpecialty = 0.30;
      wCapacity = 0.20;
    } else {
      wEta = 0.45;
      wSpecialty = 0.25;
      wCapacity = 0.30;
    }

    // ETA score: inverse of minutes; +1 avoids division by zero
    final etaMinutes = eta.inSeconds / 60.0;
    final etaScore = 1.0 / (etaMinutes + 1);

    // Specialty match: 1.0 if hospital currently accepts this emergency type (has active capacity in that dept)
    final specialtyScore =
        hospital.emergencyTypesAccepted.contains(emergencyType.firestoreKey) ? 1.0 : 0.0;

    // Capacity score: 1 - load fraction (higher availability = higher score)
    final capacityScore = 1.0 - (hospital.currentLoad.clamp(0, 100) / 100.0);

    final total = (wEta * etaScore) +
        (wSpecialty * specialtyScore) +
        (wCapacity * capacityScore);

    return ScoreBreakdown(
      total: total,
      etaScore: etaScore,
      specialtyScore: specialtyScore,
      capacityScore: capacityScore,
      maxWEta: wEta,
      maxWSpecialty: wSpecialty,
      maxWCapacity: wCapacity,
    );
  }

  /// Plain-English reasoning string shown on each hospital card.
  static String reasoningString(
    HospitalModel hospital,
    Duration eta,
    EmergencyType emergencyType,
    int rank,
    List<({HospitalModel hospital, Duration eta})> allCandidates,
  ) {
    final etaMin = eta.inMinutes;
    final specialtyMatch =
        hospital.emergencyTypesAccepted.contains(emergencyType.firestoreKey);

    if (rank == 1) {
      // Build contextual comparison with 2nd-best
      final parts = <String>[];
      if (allCandidates.length > 1) {
        final second = allCandidates[1];
        final etaDiff = second.eta.inMinutes - etaMin;
        if (etaDiff > 0) {
          parts.add('${etaDiff} min closer than nearest alternative');
        }
      }
      if (specialtyMatch) {
        parts.add('accepts ${emergencyType.label.toLowerCase()} cases');
      }
      parts.add('${100 - hospital.currentLoad}% capacity available');
      return 'Selected: ${parts.join(', ')}.';
    } else if (rank == 2) {
      final reason = specialtyMatch
          ? 'Has ${emergencyType.label} capability'
          : 'Higher availability';
      return '$reason; ${etaMin} min ETA, ${100 - hospital.currentLoad}% free.';
    } else {
      return 'Backup option: ${etaMin} min ETA, ${hospital.currentLoad}% current load.';
    }
  }
}
