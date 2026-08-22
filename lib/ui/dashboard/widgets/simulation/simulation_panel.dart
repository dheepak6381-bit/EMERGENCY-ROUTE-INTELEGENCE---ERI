import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../providers/simulation_provider.dart';
import '../../../../providers/hospital_provider.dart';
import '../../../../data/models/hospital_model.dart';
import '../../../../data/models/road_condition_model.dart';
import '../../../../data/services/osrm_service.dart';
import '../../../../providers/routing_provider.dart';

/// Simulation / Ops Control Panel
/// Styled as a real ops console — not an obvious "demo button"
class SimulationPanel extends ConsumerWidget {
  const SimulationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalsAsync = ref.watch(hospitalsStreamProvider);
    final conditionsAsync = ref.watch(roadConditionsStreamProvider);

    return Container(
      color: AppColors.bgScaffold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.statusAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'OPS CONTROL CENTER',
                  style: GoogleFonts.inter(
                    color: AppColors.statusAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () =>
                      ref.read(simulationProvider.notifier).resetAll(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.statusGreen.withOpacity(0.4)),
                    ),
                    child: Text(
                      'RESET ALL',
                      style: GoogleFonts.inter(
                        color: AppColors.statusGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderDefault),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hackathon Presets ────────────────────────────────────
                Text(
                  'SCENARIO PRESETS',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => ref.read(simulationProvider.notifier).simulateRushHour(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.accentCyan, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Simulate 6:15 PM Rush Hour',
                            style: GoogleFonts.inter(
                              color: AppColors.accentCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.play_arrow, color: AppColors.accentCyan, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Network Resilience ───────────────────────────────────
                Text(
                  'NETWORK RESILIENCE',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setState) {
                    final isFailing = OsrmService().simulateFailure;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          OsrmService().simulateFailure = !isFailing;
                        });
                        ref.read(routingProvider.notifier).computeRoutes();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isFailing ? AppColors.statusRed.withOpacity(0.1) : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isFailing ? AppColors.statusRed.withOpacity(0.4) : AppColors.borderDefault),
                        ),
                        child: Row(
                          children: [
                            Icon(isFailing ? Icons.wifi_off : Icons.wifi, color: isFailing ? AppColors.statusRed : AppColors.statusGreen, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isFailing ? 'OSRM Service: Offline' : 'OSRM Service: Online',
                                style: GoogleFonts.inter(
                                  color: isFailing ? AppColors.statusRed : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!isFailing)
                              const Icon(Icons.power_settings_new, color: AppColors.textTertiary, size: 16)
                            else
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: AppColors.statusRed, strokeWidth: 2),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // ── Road Conditions ──────────────────────────────────────
                Text(
                  'ROAD CONDITIONS',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                conditionsAsync.when(
                  data: (conditions) => Column(
                    children: conditions.map((cond) {
                      return _RoadConditionRow(condition: cond);
                    }).toList(),
                  ),
                  loading: () => const SizedBox(
                      height: 30,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accentCyan, strokeWidth: 2))),
                  error: (e, _) => Text('Error: $e',
                      style:
                          const TextStyle(color: AppColors.statusRed, fontSize: 11)),
                ),

                const SizedBox(height: 12),

                // ── Hospital Loads ───────────────────────────────────────
                Text(
                  'HOSPITAL LOAD OVERRIDE',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                hospitalsAsync.when(
                  data: (hospitals) => Column(
                    children: hospitals.take(3).map((h) {
                      return _HospitalLoadRow(hospital: h);
                    }).toList(),
                  ),
                  loading: () => const SizedBox(
                      height: 30,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accentCyan, strokeWidth: 2))),
                  error: (e, _) => Text('Error: $e',
                      style:
                          const TextStyle(color: AppColors.statusRed, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }
}

class _RoadConditionRow extends ConsumerStatefulWidget {
  final RoadConditionModel condition;
  const _RoadConditionRow({required this.condition});

  @override
  ConsumerState<_RoadConditionRow> createState() => _RoadConditionRowState();
}

class _RoadConditionRowState extends ConsumerState<_RoadConditionRow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cond = widget.condition;
    final isClear = cond.isClear;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isClear ? Icons.check_circle_outline : Icons.warning_amber,
            size: 13,
            color: isClear ? AppColors.statusGreen : AppColors.statusRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cond.segmentId,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_loading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  color: AppColors.statusAmber, strokeWidth: 2),
            )
          else if (isClear)
            Row(
              children: [
                _SmallButton(
                  label: 'BLOCK',
                  color: AppColors.statusRed,
                  onTap: () async {
                    setState(() => _loading = true);
                    await ref
                        .read(simulationProvider.notifier)
                        .blockRoadSegment(cond.id, cond.segmentId);
                    if (mounted) setState(() => _loading = false);
                  },
                ),
                const SizedBox(width: 4),
                _SmallButton(
                  label: 'CONGEST',
                  color: AppColors.statusAmber,
                  onTap: () async {
                    setState(() => _loading = true);
                    await ref
                        .read(simulationProvider.notifier)
                        .markRoadCongested(cond.id, cond.segmentId);
                    if (mounted) setState(() => _loading = false);
                  },
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.statusRed.withOpacity(0.4)),
              ),
              child: Text(
                cond.statusLabel.toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppColors.statusRed,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HospitalLoadRow extends ConsumerStatefulWidget {
  final HospitalModel hospital;
  const _HospitalLoadRow({required this.hospital});

  @override
  ConsumerState<_HospitalLoadRow> createState() => _HospitalLoadRowState();
}

class _HospitalLoadRowState extends ConsumerState<_HospitalLoadRow> {
  bool _loading = false;

  Color get _loadColor {
    final load = widget.hospital.currentLoad;
    if (load < 50) return AppColors.statusGreen;
    if (load < 80) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hospital;
    final isSpiked = h.currentLoad >= 90;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _loadColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              h.name.split(' ').take(3).join(' '),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${h.currentLoad}%',
            style: GoogleFonts.inter(
              color: _loadColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          if (_loading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  color: AppColors.statusAmber, strokeWidth: 2),
            )
          else if (!isSpiked)
            _SmallButton(
              label: 'SPIKE',
              color: AppColors.statusRed,
              onTap: () async {
                setState(() => _loading = true);
                await ref
                    .read(simulationProvider.notifier)
                    .spikeHospitalLoad(h);
                if (mounted) setState(() => _loading = false);
              },
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.statusRed.withOpacity(0.4)),
              ),
              child: Text(
                'OVERLOAD',
                style: GoogleFonts.inter(
                  color: AppColors.statusRed,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
