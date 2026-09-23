import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

/// A completely offline Natural Language Processing (NLP) engine for Smart Dispatching.
/// Detects emergency types, severity, and victim count from raw dispatcher text.
class OfflineNLPEngine {
  OfflineNLPEngine._();
  
  static final OfflineNLPEngine _instance = OfflineNLPEngine._();

  /// Segregates the raw dispatcher input into structured intent data.
  DispatchIntent parseInput(String input) {
    final lower = input.toLowerCase();
    
    // 1. Detect Emergency Type via Keyword Weighting & Stemming
    EmergencyType bestType = EmergencyType.general;
    int maxScore = 0;
    
    final Map<EmergencyType, List<String>> keywords = {
      EmergencyType.cardiac: ['heart', 'cardiac', 'arrest', 'chest pain', 'breathing', 'stroke', 'attack', 'pulse'],
      EmergencyType.trauma: ['accident', 'crash', 'bleeding', 'hit', 'fall', 'fracture', 'broken', 'head injury', 'trauma'],
      EmergencyType.burns: ['fire', 'burn', 'burnt', 'explosion', 'chemical', 'scald', 'flame'],
      EmergencyType.respiratory: ['asthma', 'choking', 'copd', 'breath', 'lung', 'suffocating', 'smoke'],
    };

    keywords.forEach((type, words) {
      int score = 0;
      for (final word in words) {
        if (lower.contains(word)) score += 2;
      }
      if (score > maxScore) {
        maxScore = score;
        bestType = type;
      }
    });

    // 2. Detect Severity
    bool isCritical = false;
    final criticalWords = ['massive', 'severe', 'unconscious', 'not breathing', 'critical', 'fatal', 'huge', 'unresponsive'];
    for (final word in criticalWords) {
      if (lower.contains(word)) {
        isCritical = true;
        break;
      }
    }

    // 3. Extract Victim Count (Regex)
    int victimCount = 1;
    final RegExp numberRegex = RegExp(r'\b(\d+)\s*(victims|people|workers|injured|persons|patients|burnt)\b');
    final match = numberRegex.firstMatch(lower);
    if (match != null && match.group(1) != null) {
      victimCount = int.tryParse(match.group(1)!) ?? 1;
    } else {
      // Look for written numbers
      if (lower.contains('two ')) victimCount = 2;
      if (lower.contains('three ')) victimCount = 3;
      if (lower.contains('four ')) victimCount = 4;
      if (lower.contains('five ')) victimCount = 5;
    }

    return DispatchIntent(
      emergencyType: bestType,
      isCritical: isCritical,
      victimCount: victimCount,
      originalText: input,
    );
  }
}

class DispatchIntent {
  final EmergencyType emergencyType;
  final bool isCritical;
  final int victimCount;
  final String originalText;

  const DispatchIntent({
    required this.emergencyType,
    required this.isCritical,
    required this.victimCount,
    required this.originalText,
  });

  @override
  String toString() {
    return 'Intent(Type: \${emergencyType.label}, Critical: $isCritical, Victims: $victimCount)';
  }
}

final nlpEngineProvider = Provider<OfflineNLPEngine>((ref) {
  // We use the singleton pattern here since it has no state
  return OfflineNLPEngine._instance;
});
