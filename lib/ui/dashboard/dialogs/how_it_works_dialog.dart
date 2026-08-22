import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/color_palette.dart';

/// "How This Works" explainability dialog
/// Required by CIC26 rulebook section 13 — visible during technical defense
class HowItWorksDialog extends StatelessWidget {
  const HowItWorksDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.accentCyan, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'How ERI Works',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Emergency Route Intelligence — CIC26 Problem Statement #18',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 28, color: AppColors.borderDefault),

              // Section 1: Routing
              _Section(
                icon: Icons.route,
                title: '1. Live Routing Engine',
                color: AppColors.accentCyan,
                body:
                    'When you tap a location or hit DISPATCH, ERI calls the OpenRouteService Directions API '
                    'using the real road network — not straight-line distance. The route is drawn progressively '
                    'over ~900ms so it visibly appears "computed" rather than instantly snapping. '
                    'Any active road conditions (from Firestore) add a delay factor: '
                    'Congestion = +35% ETA, Construction = +20% ETA.',
              ),
              const SizedBox(height: 16),

              // Section 2: Hospital Scoring
              _Section(
                icon: Icons.local_hospital,
                title: '2. Hospital Ranking Formula',
                color: AppColors.accentBlue,
                body: 'Each hospital is scored using:\n\n'
                    '   Score = 0.50 × (1/ETA) + 0.30 × specialty_match + 0.20 × (1 − load/100)\n\n'
                    '• ETA (50%) — the single biggest factor. Faster = higher score.\n'
                    '• Specialty Match (30%) — 1.0 if hospital accepts the selected emergency type, else 0.\n'
                    '• Capacity (20%) — hospitals with lower current load score higher.\n\n'
                    'Real ETAs come from the ORS Matrix API — one API call returns travel times '
                    'to all hospitals simultaneously. Hospitals are then ranked and the top 3 shown.',
              ),
              const SizedBox(height: 16),

              // Section 3: Adaptive Re-routing
              _Section(
                icon: Icons.sync_alt,
                title: '3. Adaptive Re-routing',
                color: AppColors.statusAmber,
                body:
                    'Firestore streams run continuously. When road conditions or hospital loads change '
                    '(via the Ops Control panel or any external write), Flutter\'s Riverpod providers '
                    'automatically detect the change and recompute the full routing + ranking — '
                    'no page refresh. The status ticker shows exactly what changed and why.',
              ),
              const SizedBox(height: 16),

              // Section 4: Data sources
              _Section(
                icon: Icons.storage,
                title: '4. Data Sources',
                color: AppColors.statusGreen,
                body: '• Map tiles: OpenStreetMap (free, no credit card)\n'
                    '• Routing & ETAs: OpenRouteService API (free tier, real road network)\n'
                    '• Geocoding: Nominatim OSM (free, no key required)\n'
                    '• Hospital & road data: Firebase Firestore (Spark plan, free)\n'
                    '• Deployment: Firebase Hosting (Spark plan, free)',
              ),

              const Divider(height: 28, color: AppColors.borderDefault),

              // Footer
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.textTertiary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Weights (w1, w2, w3) are configurable in app_constants.dart',
                    style: GoogleFonts.inter(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String body;

  const _Section({
    required this.icon,
    required this.title,
    required this.color,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Text(
            body,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
