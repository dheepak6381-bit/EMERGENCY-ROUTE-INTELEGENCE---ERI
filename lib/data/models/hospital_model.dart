import 'dart:math';
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

  factory HospitalModel.fromOverpass(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    
    String name = tags['name'] ?? tags['name:en'] ?? '';
    if (name.isEmpty) {
      final bedsTemp = tags['beds'] != null ? (int.tryParse(tags['beds'].toString()) ?? 100) : 100;
      final osmIdStr = element['id'].toString();
      final suffix = osmIdStr.length > 4 ? osmIdStr.substring(osmIdStr.length - 4) : osmIdStr;
      
      if (bedsTemp >= 200) {
        name = 'General Hospital (OSM-$suffix)';
      } else if (bedsTemp <= 50) {
        name = 'Local Health Center (OSM-$suffix)';
      } else {
        name = 'Medical Center (OSM-$suffix)';
      }
    }
    
    // Parse coordinates (nodes have lat/lon, ways/relations have center)
    double lat = element['lat'] ?? element['center']?['lat'] ?? 0.0;
    double lon = element['lon'] ?? element['center']?['lon'] ?? 0.0;
    
    // Estimate beds if missing
    int beds = 100;
    if (tags['beds'] != null) {
      beds = int.tryParse(tags['beds'].toString()) ?? 100;
    } else {
      // Guess based on name
      final nameLower = name.toLowerCase();
      if (nameLower.contains('medical college') || nameLower.contains('general') || nameLower.contains('gh')) {
        beds = 500;
      } else if (nameLower.contains('clinic') || nameLower.contains('phc')) {
        beds = 20;
      }
    }
    
    // Simulate realistic occupancy between 30% and 90%
    // In a real app, this would query the hospital's private API.
    final rand = Random(element['id'].hashCode);
    int load = 30 + rand.nextInt(60);

    // Specialties
    List<String> specs = ['general'];
    if (tags['healthcare:speciality'] != null) {
      final sp = tags['healthcare:speciality'].toString().toLowerCase();
      if (sp.contains('cardio')) specs.add('cardiac');
      if (sp.contains('trauma') || sp.contains('accident')) specs.add('trauma');
      if (sp.contains('burns')) specs.add('burns');
      if (sp.contains('pulmon')) specs.add('respiratory');
    } else {
      // Add random specialties if it's a large hospital
      if (beds > 200) {
        specs.addAll(['trauma', 'cardiac', 'respiratory']);
      }
    }

    return HospitalModel(
      id: 'osm_${element['id']}',
      name: name,
      location: LatLng(lat, lon),
      specialties: specs,
      bedCapacity: beds,
      currentLoad: load,
      emergencyTypesAccepted: specs, // assume they accept what they specialize in
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

  /// Number of beds currently available (free).
  int get bedsAvailable =>
      (bedCapacity - (bedCapacity * currentLoad.clamp(0, 100) / 100)).round();

  /// Availability percentage (inverse of load).
  int get availabilityPercent => (100 - currentLoad.clamp(0, 100));

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HospitalModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
