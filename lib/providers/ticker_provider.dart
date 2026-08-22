import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticker event — shown in the status bar at top of dashboard.
class TickerEvent {
  final String message;
  final bool isWarning; // true = orange/red, false = cyan (improvement)
  final DateTime timestamp;

  const TickerEvent({
    required this.message,
    required this.isWarning,
    required this.timestamp,
  });
}

class TickerNotifier extends StateNotifier<List<TickerEvent>> {
  TickerNotifier() : super([]);

  void addEvent(String message, {bool isWarning = true}) {
    final event = TickerEvent(
      message: message,
      isWarning: isWarning,
      timestamp: DateTime.now(),
    );
    state = [event, ...state.take(4)]; // keep last 5
  }

  void clearAll() => state = [];
}

final tickerProvider =
    StateNotifierProvider<TickerNotifier, List<TickerEvent>>(
  (ref) => TickerNotifier(),
);

/// Latest ticker event (for the animated top bar)
final latestTickerProvider = Provider<TickerEvent?>((ref) {
  final events = ref.watch(tickerProvider);
  return events.isEmpty ? null : events.first;
});
