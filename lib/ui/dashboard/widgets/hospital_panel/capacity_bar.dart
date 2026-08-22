import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/color_palette.dart';

class CapacityBar extends StatelessWidget {
  final int load; // 0-100

  const CapacityBar({super.key, required this.load});

  Color get _barColor {
    if (load < 50) return AppColors.statusGreen;
    if (load < 80) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  String get _label {
    if (load < 50) return 'LOW';
    if (load < 80) return 'MED';
    return 'HIGH';
  }

  @override
  Widget build(BuildContext context) {
    final clampedLoad = load.clamp(0, 100);
    final color = _barColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CAPACITY',
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                '$clampedLoad% used · $_label',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bgScaffold.withOpacity(0.5),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.borderDefault, width: 0.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedLoad / 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.6),
                    color,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
