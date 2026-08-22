import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/color_palette.dart';
import '../../providers/hospital_provider.dart';
import '../../providers/routing_provider.dart';
import '../../providers/simulation_provider.dart';
import '../../providers/incident_provider.dart';
import 'widgets/top_bar/top_bar.dart';
import 'widgets/map_panel/map_panel.dart';
import 'widgets/hospital_panel/hospital_panel.dart';
import 'widgets/simulation/simulation_panel.dart';
import 'widgets/bottom_bar/metrics_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _initialComputeDone = false;

  @override
  void initState() {
    super.initState();
    // Attempt first compute after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routingProvider.notifier).computeRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to hospital stream — auto-compute when data first arrives
    ref.listen(hospitalsStreamProvider, (prev, next) {
      next.whenData((hospitals) {
        ref.read(simulationProvider.notifier).captureBaseline(hospitals);
        // If hospitals just loaded and we haven't computed yet, compute now
        if (!_initialComputeDone && hospitals.isNotEmpty) {
          _initialComputeDone = true;
          ref.read(routingProvider.notifier).computeRoutes(hospitalsOverride: hospitals);
        }
      });
    });

    // Re-compute when road conditions change
    ref.listen(roadConditionsStreamProvider, (prev, next) {
      if (prev?.valueOrNull != null && next.valueOrNull != null) {
        ref.read(routingProvider.notifier).computeRoutes();
      }
    });

    final showSimPanel = ref.watch(simulationPanelVisibleProvider);

    return Scaffold(
      backgroundColor: AppColors.bgScaffold,
      body: Column(
        children: [
          // ── Top Bar ─────────────────────────────────────────────────────
          const TopBar(),

          // ── Main Content ─────────────────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                
                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Map Panel (60%) ────────────────────────────────────────
                      const Expanded(
                        flex: 60,
                        child: MapPanel(),
                      ),

                      // ── Right Panel (40%) ──────────────────────────────────────
                      Container(
                        width: 380,
                        decoration: const BoxDecoration(
                          color: AppColors.bgPanel,
                          border: Border(
                            left: BorderSide(color: AppColors.borderDefault),
                          ),
                        ),
                        child: _SidePanelContent(showSimPanel: showSimPanel),
                      ),
                    ],
                  );
                } else {
                  return Stack(
                    children: [
                      const Positioned.fill(
                        child: MapPanel(),
                      ),
                      _MobileBottomSheet(showSimPanel: showSimPanel),
                    ],
                  );
                }
              },
            ),
          ),

          // ── Bottom Metrics Bar ────────────────────────────────────────────
          if (MediaQuery.of(context).size.width > 900)
            const MetricsBar(),
        ],
      ),
    );
  }
}

class _SidePanelContent extends StatelessWidget {
  final bool showSimPanel;
  const _SidePanelContent({required this.showSimPanel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RightPanelHeader(),
        const Divider(height: 1, color: AppColors.borderDefault),
        const Expanded(child: HospitalPanel()),
        if (showSimPanel) ...[
          const Divider(height: 1, color: AppColors.borderDefault),
          const SimulationPanel(),
        ],
      ],
    );
  }
}

class _MobileBottomSheet extends StatelessWidget {
  final bool showSimPanel;
  const _MobileBottomSheet({required this.showSimPanel});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgPanel.withOpacity(0.95), // Glassmorphism!
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppColors.borderDefault.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _RightPanelHeader(),
              const Divider(height: 1, color: AppColors.borderDefault),
              Expanded(
                child: HospitalPanel(scrollController: scrollController),
              ),
              if (showSimPanel) ...[
                const Divider(height: 1, color: AppColors.borderDefault),
                const SimulationPanel(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RightPanelHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSim = ref.watch(simulationPanelVisibleProvider);
    final routing = ref.watch(routingProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: routing.isLoading
                  ? AppColors.statusAmber
                  : AppColors.statusGreen,
              boxShadow: [
                BoxShadow(
                  color: (routing.isLoading
                          ? AppColors.statusAmber
                          : AppColors.statusGreen)
                      .withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'HOSPITAL RANKING',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          // Ops Control toggle
          Tooltip(
            message: showSim ? 'Hide Ops Control' : 'Open Ops Control',
            child: InkWell(
              onTap: () => ref
                  .read(simulationPanelVisibleProvider.notifier)
                  .state = !showSim,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: showSim
                      ? AppColors.accentBlue.withOpacity(0.15)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: showSim
                        ? AppColors.accentBlue
                        : AppColors.borderDefault,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 13,
                      color: showSim
                          ? AppColors.accentBlue
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'OPS',
                      style: GoogleFonts.inter(
                        color: showSim
                            ? AppColors.accentBlue
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
