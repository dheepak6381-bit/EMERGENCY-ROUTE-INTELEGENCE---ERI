import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../providers/routing_provider.dart';
import '../../../../providers/incident_provider.dart';
import 'hospital_card.dart';

class HospitalPanel extends ConsumerWidget {
  final ScrollController? scrollController;
  
  const HospitalPanel({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routing = ref.watch(routingProvider);
    final emergencyType = ref.watch(emergencyTypeProvider);

    if (routing.isLoading) {
      return ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return Container(
            height: 130,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.bgScaffold, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(width: 10),
                    Container(width: 120, height: 14, color: AppColors.bgScaffold),
                    const Spacer(),
                    Container(width: 40, height: 18, color: AppColors.bgScaffold),
                  ],
                ),
                const SizedBox(height: 16),
                Container(width: 180, height: 12, color: AppColors.bgScaffold),
                const Spacer(),
                Container(width: double.infinity, height: 6, decoration: BoxDecoration(color: AppColors.bgScaffold, borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 1200.ms, color: Colors.white12)
           .animate()
           .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 100))
           .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
        },
      );
    }

    if (routing.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.statusRed, size: 36),
              const SizedBox(height: 12),
              Text(
                routing.error!,
                style: GoogleFonts.inter(
                  color: AppColors.statusRed,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!routing.hasComputed || routing.rankedHospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital_outlined,
                color: AppColors.textTertiary, size: 40),
            const SizedBox(height: 12),
            Text(
              'Select incident location\nand tap DISPATCH',
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      children: [
        if (routing.secondaryRankedHospitals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'PRIMARY INCIDENT',
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ...routing.rankedHospitals.asMap().entries.map((entry) {
          final index = entry.key;
          final rh = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HospitalCard(
              rankedHospital: rh,
              emergencyType: emergencyType,
            )
                .animate(key: ValueKey('primary_${rh.hospital.id}_${rh.rank}'))
                .fadeIn(delay: Duration(milliseconds: index * 100), duration: 300.ms)
                .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
          );
        }),
        if (routing.secondaryRankedHospitals.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderDefault),
          const SizedBox(height: 12),
          Text(
            'SECONDARY INCIDENT',
            style: GoogleFonts.inter(
              color: AppColors.statusAmber,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...routing.secondaryRankedHospitals.asMap().entries.map((entry) {
            final index = entry.key;
            final rh = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HospitalCard(
                rankedHospital: rh,
                emergencyType: emergencyType,
              )
                  .animate(key: ValueKey('secondary_${rh.hospital.id}_${rh.rank}'))
                  .fadeIn(delay: Duration(milliseconds: index * 100), duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
            );
          }),
        ],
      ],
    );
  }
}
