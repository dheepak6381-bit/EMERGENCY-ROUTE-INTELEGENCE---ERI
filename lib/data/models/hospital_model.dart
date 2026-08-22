import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Firestore document model for hospitals/{id}
class HospitalModel {
  final String id;
  final String name;
  final LatLng location;
  final List<String> specialties;
  final int bedCapacity;
  final int currentLoad; // 0-100 percentage
  final List<String> emergencyTypesAccepted;
  final DateTime? lastUpdated;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.location,
    required this.specialties,
    required this.bedCapacity,
    required this.currentLoad,
    required this.emergencyTypesAccepted,
    this.lastUpdated,
  });

  factory HospitalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Hospital',
      location: LatLng(
        (data['lat'] as num?)?.toDouble() ?? 0.0,
        (data['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      specialties: List<String>.from(data['specialties'] ?? []),
      bedCapacity: (data['bed_capacity'] as num?)?.toInt() ?? 100,
      currentLoad: (data['current_load'] as num?)?.toInt() ?? 50,
      emergencyTypesAccepted:
          List<String>.from(data['emergency_types_accepted'] ?? []),
      lastUpdated: (data['last_updated'] as Timestamp?)?.toDate(),
    );
  }

  HospitalModel copyWith({int? currentLoad}) {
    return HospitalModel(
      id: id,
      name: name,
      location: location,
      specialties: specialties,
      bedCapacity: bedCapacity,
      currentLoad: currentLoad ?? this.currentLoad,
      emergencyTypesAccepted: emergencyTypesAccepted,
      lastUpdated: lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HospitalModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
