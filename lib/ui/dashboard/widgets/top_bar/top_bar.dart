import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../providers/incident_provider.dart';
import '../../../../providers/routing_provider.dart';
import '../../../../providers/ticker_provider.dart';
import '../../../../core/utils/offline_nlp_engine.dart';
import 'emergency_type_selector.dart';
import 'status_ticker.dart';
import '../../dialogs/how_it_works_dialog.dart';

import 'dart:ui';

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider);
    final routing = ref.watch(routingProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.bgTopBar.withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(color: AppColors.borderDefault),
            ),
          ),
          child: Row(
            children: [
          // ── Logo ─────────────────────────────────────────────────────────
          Flexible(
            flex: 0,
            child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/eri_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                if (MediaQuery.of(context).size.width > 600) ...[
                  Flexible(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'EMERGENCY ROUTE INTELLIGENCE',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Dispatcher Dashboard',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  ),
                ],
              ],
            ),
          ),
          ),

          Container(width: 1, color: AppColors.borderDefault),

          // ── NLP Smart Dispatch Input ───────────────────────────────────────
          Container(
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Smart Dispatch (e.g. "3 burnt in fire")',
                hintStyle: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accentBlue),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                prefixIcon: const Icon(Icons.psychology, size: 16, color: AppColors.accentBlue),
              ),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                
                // Run Offline NLP Engine
                final intent = ref.read(nlpEngineProvider).parseInput(value);
                
                // Update Emergency Type based on NLP intent
                ref.read(emergencyTypeProvider.notifier).state = intent.emergencyType;
                
                // Show notification ticker
                ref.read(tickerProvider.notifier).addEvent(
                  'NLP Segregation: Detected \${intent.emergencyType.label} (Victims: \${intent.victimCount}, Critical: \${intent.isCritical})'
                );
                
                // Auto-trigger the function pointer (routing computation)
                ref.read(routingProvider.notifier).computeRoutes();
              },
            ),
          ),

          Container(width: 1, color: AppColors.borderDefault),

          // ── Emergency Type Selector (Manual Override) ─────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: EmergencyTypeSelector(),
          ),

          Container(width: 1, color: AppColors.borderDefault),

          // ── Dispatch Button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: routing.isLoading
                      ? null
                      : () => ref.read(routingProvider.notifier).computeRoutes(),
                  icon: routing.isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 14),
                  label: Text(
                    routing.isLoading ? 'COMPUTING...' : 'DISPATCH',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (ref.watch(emergencyTypeProvider).urgencyFraming.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ref.watch(emergencyTypeProvider).urgencyFraming,
                    style: GoogleFonts.inter(
                      color: AppColors.statusAmber.withOpacity(0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ]
              ],
            ),
          ),

          // ── Status Ticker (expands to fill) ───────────────────────────────
          const Expanded(child: StatusTicker()),

          // ── Incident Location ─────────────────────────────────────────────
          Container(width: 1, color: AppColors.borderDefault),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            width: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INCIDENT LOCATION',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  incident.locationName,
                  style: GoogleFonts.inter(
                    color: AppColors.accentCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Container(width: 1, color: AppColors.borderDefault),

          // ── How it works ──────────────────────────────────────────────────
          Tooltip(
            message: 'How ERI works',
            child: IconButton(
              icon: const Icon(Icons.info_outline,
                  color: AppColors.textSecondary, size: 20),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const HowItWorksDialog(),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    ).animate().slideY(begin: -1, duration: 600.ms, curve: Curves.easeOutCirc).fadeIn();
  }
}
