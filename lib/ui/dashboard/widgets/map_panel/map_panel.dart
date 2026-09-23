import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/incident_provider.dart';
import '../../../../providers/routing_provider.dart';
import '../../../../providers/hospital_provider.dart';
import '../../../../data/services/nominatim_service.dart';
import '../../../../data/models/road_condition_model.dart';
import 'dart:ui';

class MapPanel extends ConsumerStatefulWidget {
  const MapPanel({super.key});

  @override
  ConsumerState<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends ConsumerState<MapPanel>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final NominatimService _nominatim = NominatimService();

  List<LatLng> _animatedRoutePoints = [];
  AnimationController? _routeAnimController;
  Timer? _routeTimer;
  List<NominatimResult> _searchResults = [];
  bool _isSearching = false;

  // Ambulance tracking
  LatLng? _ambulanceLocation;
  int _ambulanceIndex = 0;
  Timer? _ambulanceTimer;
  String? _rerouteReason;

  @override
  void dispose() {
    _routeAnimController?.dispose();
    _routeTimer?.cancel();
    _ambulanceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startRouteAnimation(List<LatLng> points) {
    _routeTimer?.cancel();
    setState(() {
      _animatedRoutePoints = [];
    });

    final total = points.length;
    if (total == 0) return;

    int index = 0;
    const duration = AppConstants.routeDrawDuration;
    final intervalMs = duration.inMilliseconds / total;

    _routeTimer = Timer.periodic(
      Duration(milliseconds: intervalMs.ceil()),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        index++;
        if (index >= total) {
          setState(() => _animatedRoutePoints = List.from(points));
          timer.cancel();
        } else {
          setState(() =>
              _animatedRoutePoints = points.sublist(0, index));
        }
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _nominatim.search(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _startAmbulance(List<LatLng> points, bool isReroute) {
    _ambulanceTimer?.cancel();
    if (points.isEmpty) return;

    if (!isReroute || _ambulanceLocation == null) {
      _ambulanceLocation = points.first;
      _ambulanceIndex = 0;
    } else {
      // Find closest point on new route to snap to
      _ambulanceIndex = _findClosestIndex(points, _ambulanceLocation!);
    }

    _ambulanceTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_ambulanceIndex < points.length - 1) {
        setState(() {
          _ambulanceIndex++;
          _ambulanceLocation = points[_ambulanceIndex];
        });
      } else {
        timer.cancel(); // arrived
        setState(() {
           _rerouteReason = "Arrived at destination";
        });
        Future.delayed(const Duration(seconds: 3), () {
           if (mounted) setState(() => _rerouteReason = null);
        });
      }
    });
  }

  int _findClosestIndex(List<LatLng> points, LatLng target) {
    int bestIndex = 0;
    double minD = double.infinity;
    const distCalc = Distance();
    for (int i = 0; i < points.length; i++) {
      double d = distCalc.as(LengthUnit.Meter, points[i], target);
      if (d < minD) {
        minD = d;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  @override
  Widget build(BuildContext context) {
    final incident = ref.watch(incidentProvider);
    final routing = ref.watch(routingProvider);
    final conditions = ref.watch(roadConditionsStreamProvider).valueOrNull ?? [];

    // Watch route changes and animate
    ref.listen(routingProvider, (prev, next) {
      final route = next.selectedRoute;
      if (route != null && route.points.length > 1) {
        bool isReroute = false;
        if (prev?.selectedRoute != null && prev!.selectedRoute!.points != route.points) {
           isReroute = true;
           if (next.rankedHospitals.isNotEmpty) {
               setState(() {
                 _rerouteReason = "Rerouting: ${next.rankedHospitals.first.reasoning}";
               });
               Future.delayed(const Duration(seconds: 4), () {
                 if (mounted) setState(() => _rerouteReason = null);
               });
           }
        }
        
        _startRouteAnimation(route.points);
        _startAmbulance(route.points, isReroute);
        
        // Pan map to show route
        if (route.points.isNotEmpty && !isReroute) {
          final bounds = LatLngBounds.fromPoints(route.points);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(60),
            ),
          );
        }
      }
    });

    final activeConditions =
        conditions.where((c) => !c.isClear).toList();

    return Stack(
      children: [
        // ── Base Map ──────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: AppConstants.kareLocation,
            initialZoom: AppConstants.defaultZoom,
            onTap: (tapPosition, latLng) {
              ref.read(incidentProvider.notifier).setLocation(latLng);
              setState(() => _searchResults = []);
              ref.read(routingProvider.notifier).computeRoutes();
            },
          ),
          children: [
            // OSM Tiles (free, no API key)
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              userAgentPackageName: AppConstants.osmUserAgent,
              tileBuilder: _darkTileBuilder,
            ),

            // Road condition overlays (dashed red)
            if (activeConditions.isNotEmpty)
              PolylineLayer(
                polylines: activeConditions.map((c) {
                  if (c.bounds.length < 2) return null;
                  return Polyline(
                    points: c.bounds,
                    color: AppColors.statusRed.withValues(alpha: 0.8),
                    strokeWidth: 6,
                    pattern: StrokePattern.dashed(segments: [10, 6]),
                  );
                }).whereType<Polyline>().toList(),
              ),

            // Animated route polyline
            if (_animatedRoutePoints.length > 1)
              PolylineLayer(
                polylines: [
                  // Outer Glow
                  Polyline(
                    points: _animatedRoutePoints,
                    color: AppColors.accentCyan.withOpacity(0.3),
                    strokeWidth: 16.0,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  // Inner Glow
                  Polyline(
                    points: _animatedRoutePoints,
                    color: AppColors.accentCyan.withOpacity(0.6),
                    strokeWidth: 8.0,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  // Core
                  Polyline(
                    points: _animatedRoutePoints,
                    color: Colors.white,
                    strokeWidth: 3.5,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),

            // Hospital markers
            MarkerLayer(
              markers: _buildHospitalMarkers(routing),
            ),

            // Incident marker
            MarkerLayer(
              markers: [
                Marker(
                  point: incident.location,
                  width: 44,
                  height: 44,
                  child: _IncidentMarker(),
                ),
                if (ref.watch(secondaryIncidentProvider) != null)
                  Marker(
                    point: ref.watch(secondaryIncidentProvider)!.location,
                    width: 44,
                    height: 44,
                    child: _IncidentMarker(isSecondary: true),
                  ),
              ],
            ),

            // Secondary Route (faded)
            if (routing.secondaryRoute != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routing.secondaryRoute!.points,
                    color: AppColors.textTertiary.withOpacity(0.5),
                    strokeWidth: 4.0,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                    pattern: StrokePattern.dashed(segments: [8, 6]),
                  ),
                ],
              ),

            // Ambulance marker (Mid-Transit)
            if (_ambulanceLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _ambulanceLocation!,
                    width: 140,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: _AmbulanceMarker(reason: _rerouteReason),
                  ),
                ],
              ),
          ],
        ),

        // ── Search Box ────────────────────────────────────────────────────
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgPanel,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderDefault),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search incident location...',
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textTertiary, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textSecondary, size: 18),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentCyan,
                                  ),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                      onChanged: _performSearch,
                    ),
                  ),
                ),
              ),

              // Search results dropdown
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgPanel.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    children: _searchResults.take(5).map((r) {
                      return InkWell(
                        onTap: () {
                          ref
                              .read(incidentProvider.notifier)
                              .setLocation(r.location, name: r.displayName);
                          _searchController.text = r.displayName
                              .split(',')
                              .first;
                          setState(() => _searchResults = []);
                          _mapController.move(r.location, 13);
                          ref.read(routingProvider.notifier).computeRoutes();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: AppColors.accentCyan),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  r.displayName,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),

        // ── Route Info Badge (bottom left) ────────────────────────────────
        if (routing.selectedRoute != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: _RouteBadge(route: routing.selectedRoute!),
          ),

        // ── Road Condition Tooltips (bottom right) ────────────────────────
        if (activeConditions.isNotEmpty)
          Positioned(
            bottom: 16,
            right: 16,
            child: _RoadConditionBanner(conditions: activeConditions),
          ),
      ],
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.98, 0.98), duration: 800.ms, curve: Curves.easeOutCirc);
  }

  List<Marker> _buildHospitalMarkers(RoutingState routing) {
    final markers = <Marker>[];
    for (final rh in routing.rankedHospitals) {
      final hospital = rh.hospital;
      final isTop = rh.rank == 1;
      markers.add(
        Marker(
          point: hospital.location,
          width: isTop ? 48 : 36,
          height: isTop ? 48 : 36,
          child: Tooltip(
            message:
                '${hospital.name}\nETA: ${rh.route.etaLabel}\nLoad: ${hospital.currentLoad}%',
            child: _HospitalMarker(
              rank: rh.rank,
              isTop: isTop,
              load: hospital.currentLoad,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _darkTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.2126, -0.7152, -0.0722, 0, 255,
        -0.2126, -0.7152, -0.0722, 0, 255,
        -0.2126, -0.7152, -0.0722, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }
}

class _IncidentMarker extends StatelessWidget {
  final bool isSecondary;
  const _IncidentMarker({this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    final color = isSecondary ? AppColors.statusAmber : AppColors.statusRed;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse effect
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scaleXY(begin: 1.0, end: 1.5, duration: 1500.ms, curve: Curves.easeInOut)
         .fade(begin: 0.8, end: 0.0, duration: 1500.ms),

        // Core marker
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.4),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.emergency, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

class _HospitalMarker extends StatelessWidget {
  final int rank;
  final bool isTop;
  final int load;

  const _HospitalMarker({
    required this.rank,
    required this.isTop,
    required this.load,
  });

  Color get _loadColor {
    if (load < 50) return AppColors.statusGreen;
    if (load < 80) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  @override
  Widget build(BuildContext context) {
    Widget marker = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isTop ? AppColors.accentBlue : AppColors.bgCard,
        border: Border.all(
          color: isTop ? AppColors.accentCyan : _loadColor,
          width: isTop ? 2.5 : 1.5,
        ),
        boxShadow: isTop
            ? [
                BoxShadow(
                  color: AppColors.accentCyan.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: isTop ? 16 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    if (isTop) {
      marker = marker.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.15, duration: 1000.ms, curve: Curves.easeInOutSine)
          .boxShadow(
            begin: BoxShadow(color: AppColors.accentCyan.withOpacity(0.4), blurRadius: 10, spreadRadius: 2),
            end: BoxShadow(color: AppColors.accentCyan.withOpacity(0.8), blurRadius: 20, spreadRadius: 6),
            duration: 1000.ms,
          );
    } else {
      marker = marker.animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.05, duration: 1500.ms, curve: Curves.easeInOut);
    }

    return marker;
  }
}

class _RouteBadge extends StatelessWidget {
  final dynamic route; // RouteResult

  const _RouteBadge({required this.route});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route, color: AppColors.accentCyan, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                  fontSize: 11,
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

class _RoadConditionBanner extends StatelessWidget {
  final List<RoadConditionModel> conditions;

  const _RoadConditionBanner({required this.conditions});

  @override
  Widget build(BuildContext context) {
    final latest = conditions.first;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusRed.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber, color: AppColors.statusRed, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              latest.note.isNotEmpty
                  ? latest.note
                  : '${latest.statusLabel}: ${latest.segmentId}',
              style: GoogleFonts.inter(
                color: AppColors.statusRed,
                fontSize: 11,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbulanceMarker extends StatelessWidget {
  final String? reason;
  const _AmbulanceMarker({this.reason});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (reason != null)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCyan.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              reason!,
              style: GoogleFonts.inter(
                color: AppColors.bgScaffold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.5, end: 0),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.local_shipping, color: AppColors.bgScaffold, size: 14),
          ),
        ),
      ],
    );
  }
}

