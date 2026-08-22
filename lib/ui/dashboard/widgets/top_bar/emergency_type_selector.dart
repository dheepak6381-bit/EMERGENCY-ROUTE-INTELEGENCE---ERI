import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/incident_provider.dart';
import '../../../../providers/routing_provider.dart';

class EmergencyTypeSelector extends ConsumerWidget {
  const EmergencyTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(emergencyTypeProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: EmergencyType.values.map((type) {
        final isSelected = current == type;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _TypeChip(
            type: type,
            isSelected: isSelected,
            onTap: () {
              ref.read(emergencyTypeProvider.notifier).state = type;
              // Recompute with new emergency type
              ref.read(routingProvider.notifier).computeRoutes();
            },
          ),
        );
      }).toList(),
    );
  }
}

class _TypeChip extends StatefulWidget {
  final EmergencyType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TypeChip> createState() => _TypeChipState();
}

class _TypeChipState extends State<_TypeChip> {
  bool _hovered = false;

  Color get _badgeColor {
    switch (widget.type) {
      case EmergencyType.cardiac:
        return AppColors.badgeCardiac;
      case EmergencyType.trauma:
        return AppColors.badgeTrauma;
      case EmergencyType.burns:
        return AppColors.badgeBurns;
      case EmergencyType.respiratory:
        return AppColors.badgeRespiratory;
      case EmergencyType.general:
        return AppColors.badgeGeneral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? _badgeColor.withOpacity(0.15)
                : isActive
                    ? AppColors.bgCard
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isSelected ? _badgeColor : AppColors.borderDefault,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.type.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                widget.type.label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: widget.isSelected ? _badgeColor : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
