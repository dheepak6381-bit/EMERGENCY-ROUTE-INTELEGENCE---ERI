import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../data/models/incident_log_model.dart';
import '../../../../data/services/firestore_service.dart';

/// Provider that streams the last 10 incident audit logs from Firestore.
final incidentLogsStreamProvider = StreamProvider<List<IncidentLogModel>>((ref) {
  return FirestoreService().incidentLogsStream(limit: 10);
});

/// Provider to toggle visibility of the audit log panel.
final auditLogVisibleProvider = StateProvider<bool>((ref) => false);

/// Read-only "Recent Dispatches" panel that streams audit logs from Firestore.
///
/// Follows the same collapse/expand pattern as [SimulationPanel].
class AuditLogPanel extends ConsumerWidget {
  const AuditLogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(incidentLogsStreamProvider);

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
                    color: AppColors.accentCyan,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RECENT DISPATCHES',
                  style: GoogleFonts.inter(
                    color: AppColors.accentCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => ref.read(auditLogVisibleProvider.notifier).state = false,
                  child: const Icon(Icons.close, color: AppColors.textTertiary, size: 16),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderDefault),

          // Log entries
          Padding(
            padding: const EdgeInsets.all(12),
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No dispatches logged yet',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: logs.map((log) => _LogEntry(log: log)).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentCyan,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Could not load logs',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }
}

class _LogEntry extends StatelessWidget {
  final IncidentLogModel log;
  const _LogEntry({required this.log});

  @override
  Widget build(BuildContext context) {
    final timeStr = '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            // Time
            Text(
              timeStr,
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),

            // Emergency type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _badgeColor(log.emergencyType).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _badgeColor(log.emergencyType).withOpacity(0.5),
                ),
              ),
              child: Text(
                log.emergencyType.toUpperCase(),
                style: GoogleFonts.inter(
                  color: _badgeColor(log.emergencyType),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Hospital name
            Expanded(
              child: Text(
                log.dispatchedHospitalName,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),

            // ETA
            Text(
              '${log.etaMinutes.round()} min',
              style: GoogleFonts.inter(
                color: AppColors.accentCyan,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _badgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cardiac':
        return AppColors.badgeCardiac;
      case 'trauma':
        return AppColors.badgeTrauma;
      case 'burns':
        return AppColors.badgeBurns;
      case 'respiratory':
        return AppColors.badgeRespiratory;
      default:
        return AppColors.badgeGeneral;
    }
  }
}
