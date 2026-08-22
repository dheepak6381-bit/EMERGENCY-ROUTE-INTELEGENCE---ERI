import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../providers/routing_provider.dart';
import '../../../../providers/hospital_provider.dart';

class MetricsBar extends ConsumerWidget {
  const MetricsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routing = ref.watch(routingProvider);
    final hospitalsAsync = ref.watch(hospitalsStreamProvider);
    final conditionsAsync = ref.watch(roadConditionsStreamProvider);

    final hospitals = hospitalsAsync.valueOrNull ?? [];
    final conditions = conditionsAsync.valueOrNull ?? [];
    final activeConditions = conditions.where((c) => !c.isClear).length;

    final avgLoad = hospitals.isEmpty
        ? 0
        : (hospitals.map((h) => h.currentLoad).reduce((a, b) => a + b) /
                hospitals.length)
            .round();

    final topEta = routing.rankedHospitals.isNotEmpty
        ? routing.rankedHospitals.first.route.etaLabel
        : '--';

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.bgTopBar,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _Metric(
            label: 'BEST ETA',
            value: topEta,
            valueColor: AppColors.accentCyan,
          ),
          _Divider(),
          _Metric(
            label: 'HOSPITALS RANKED',
            value: '${routing.rankedHospitals.length}',
            valueColor: AppColors.textPrimary,
          ),
          _Divider(),
          _Metric(
            label: 'AVG LOAD',
            value: '$avgLoad%',
            valueColor: avgLoad < 50
                ? AppColors.statusGreen
                : avgLoad < 80
                    ? AppColors.statusAmber
                    : AppColors.statusRed,
          ),
          _Divider(),
          _Metric(
            label: 'ACTIVE CONDITIONS',
            value: '$activeConditions',
            valueColor: activeConditions > 0
                ? AppColors.statusRed
                : AppColors.statusGreen,
          ),
          _Divider(),
          _Metric(
            label: 'SYSTEM',
            value: routing.isLoading ? 'COMPUTING' : 'NOMINAL',
            valueColor: routing.isLoading
                ? AppColors.statusAmber
                : AppColors.statusGreen,
          ),
          const Spacer(),
          // Attribution
          Text(
            '© OpenStreetMap contributors | ERI v1.0 · CIC26',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _Metric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.borderDefault,
    );
  }
}
