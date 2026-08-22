import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';

/// The current incident location selected by the dispatcher.
/// Starts at KARE campus; updated when user taps map or searches.
class IncidentState {
  final LatLng location;
  final String locationName;
  final bool isSet;

  const IncidentState({
    required this.location,
    required this.locationName,
    required this.isSet,
  });

  static IncidentState get initial => const IncidentState(
        location: AppConstants.kareLocation,
        locationName: AppConstants.kareLocationName,
        isSet: true,
      );

  IncidentState copyWith({
    LatLng? location,
    String? locationName,
    bool? isSet,
  }) =>
      IncidentState(
        location: location ?? this.location,
        locationName: locationName ?? this.locationName,
        isSet: isSet ?? this.isSet,
      );
}

class IncidentNotifier extends StateNotifier<IncidentState> {
  IncidentNotifier() : super(IncidentState.initial);

  void setLocation(LatLng location, {String? name}) {
    state = state.copyWith(
      location: location,
      locationName: name ?? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
      isSet: true,
    );
  }

  void reset() {
    state = IncidentState.initial;
  }
}

final incidentProvider =
    StateNotifierProvider<IncidentNotifier, IncidentState>(
  (ref) => IncidentNotifier(),
);

/// Currently selected emergency type
final emergencyTypeProvider =
    StateProvider<EmergencyType>((ref) => EmergencyType.general);
