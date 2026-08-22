import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../providers/ticker_provider.dart';

class StatusTicker extends ConsumerStatefulWidget {
  const StatusTicker({super.key});

  @override
  ConsumerState<StatusTicker> createState() => _StatusTickerState();
}

class _StatusTickerState extends ConsumerState<StatusTicker> {
  TickerEvent? _displayedEvent;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TickerEvent?>(latestTickerProvider, (prev, next) {
      if (next != null && next != prev) {
        setState(() {
          _displayedEvent = next;
          _visible = true;
        });
        // Auto-hide after 8 seconds
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) setState(() => _visible = false);
        });
      }
    });

    if (_displayedEvent == null) {
      return Center(
        child: Text(
          'System nominal — awaiting dispatch',
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final event = _displayedEvent!;
    final color =
        event.isWarning ? AppColors.statusAmber : AppColors.statusCyan;

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.message,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeLabel(event.timestamp),
              style: GoogleFonts.inter(
                color: color.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      )
          .animate(key: ValueKey(event.timestamp.millisecondsSinceEpoch))
          .slideX(begin: 0.3, end: 0, duration: 350.ms, curve: Curves.easeOut)
          .fadeIn(duration: 350.ms),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    return '${diff.inMinutes}m ago';
  }
}
