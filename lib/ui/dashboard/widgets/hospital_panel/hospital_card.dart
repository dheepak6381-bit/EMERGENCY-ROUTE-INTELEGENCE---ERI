import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/route_result_model.dart';
import '../../../../core/utils/traffic_classifier.dart';
import 'capacity_bar.dart';

import 'dart:ui';

class HospitalCard extends StatefulWidget {
  final RankedHospital rankedHospital;
  final EmergencyType emergencyType;

  const HospitalCard({
    super.key,
    required this.rankedHospital,
    required this.emergencyType,
  });

  @override
  State<HospitalCard> createState() => _HospitalCardState();
}

class _HospitalCardState extends State<HospitalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final rh = widget.rankedHospital;
    final hospital = rh.hospital;
    final route = rh.route;
    final isTop = rh.rank == 1;
    final specialtyMatch =
        hospital.specialties.contains(widget.emergencyType.firestoreKey);
    final trafficColor = TrafficClassifier.color(route.trafficSeverity);

    // Stagger delay based on rank so they cascade in
    final delay = Duration(milliseconds: 100 * rh.rank);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgCardHover.withOpacity(0.7) : AppColors.bgCard.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTop
                    ? AppColors.accentBlue.withOpacity(0.8)
                    : AppColors.borderDefault.withOpacity(0.5),
                width: isTop ? 1.5 : 1,
              ),
              boxShadow: isTop
                  ? [
                      BoxShadow(
                        color: AppColors.accentBlue.withOpacity(0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            transform: _hovered ? (Matrix4.identity()..scale(1.02, 1.02)) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────────────────────────────────────
                  Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isTop
                              ? AppColors.accentBlue
                              : AppColors.bgScaffold,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isTop
                                ? AppColors.accentBlue
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${rh.rank}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Hospital name
                      Expanded(
                        child: Text(
                          hospital.name,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // ETA
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            route.etaLabel,
                            style: GoogleFonts.inter(
                              color: AppColors.accentCyan,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            route.distanceLabel,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Badges row ───────────────────────────────────────────────
                  Row(
                    children: [
                      // Traffic severity badge
                      _Badge(
                        label: TrafficClassifier.label(route.trafficSeverity),
                        color: trafficColor,
                        icon: Icons.traffic,
                      ),
                      const SizedBox(width: 6),

                      // Specialty match badge
                      _Badge(
                        label: specialtyMatch
                            ? widget.emergencyType.label
                            : 'No ${widget.emergencyType.label}',
                        color: specialtyMatch
                            ? AppColors.statusGreen
                            : AppColors.textTertiary,
                        icon: specialtyMatch
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                      ),

                      const Spacer(),

                      // Score indicator
                      Tooltip(
                        message: 'Composite score (ETA×50% + Specialty×30% + Capacity×20%)',
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: rh.score * 100),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              'Score: ${value.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Capacity Bar ─────────────────────────────────────────────
                  CapacityBar(load: hospital.currentLoad),

                  const SizedBox(height: 10),

                  // ── Reasoning String ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgScaffold.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.borderDefault.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: isTop
                              ? AppColors.accentBlue
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rh.reasoning,
                            style: GoogleFonts.inter(
                              color: isTop
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Road condition note ───────────────────────────────────────
                  if (route.hasCondition) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 12, color: AppColors.statusAmber),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            route.conditionNote!,
                            style: GoogleFonts.inter(
                              color: AppColors.statusAmber,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate()
     .fade(delay: delay, duration: const Duration(milliseconds: 400))
     .slideX(begin: 0.2, end: 0, delay: delay, curve: Curves.easeOutCubic);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
