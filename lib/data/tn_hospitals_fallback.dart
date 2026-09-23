import 'package:latlong2/latlong.dart';
import 'models/hospital_model.dart';

/// A robust fallback list of major hospitals across Tamil Nadu districts.
/// Used ONLY when the live Overpass API is completely unreachable.
class TNHospitalsFallback {
  TNHospitalsFallback._();

  static List<HospitalModel> get hospitals => _hospitals;

  static final List<HospitalModel> _hospitals = [
    // Chennai
    HospitalModel(
      id: 'tn_chennai_rggh',
      name: 'Rajiv Gandhi Government General Hospital (RGGGH)',
      location: const LatLng(13.0827, 80.2707),
      specialties: ['general', 'trauma', 'cardiac', 'burns', 'respiratory'],
      bedCapacity: 2700,
      currentLoad: 80,
      emergencyTypesAccepted: ['general', 'trauma', 'cardiac', 'burns', 'respiratory'],
    ),
    HospitalModel(
      id: 'tn_chennai_apollo',
      name: 'Apollo Hospitals Greams Road',
      location: const LatLng(13.0620, 80.2520),
      specialties: ['cardiac', 'trauma', 'respiratory', 'general'],
      bedCapacity: 500,
      currentLoad: 65,
      emergencyTypesAccepted: ['cardiac', 'trauma', 'respiratory', 'general'],
    ),
    // Madurai
    HospitalModel(
      id: 'tn_madurai_grh',
      name: 'Government Rajaji Hospital (GRH)',
      location: const LatLng(9.9195, 78.1190),
      specialties: ['trauma', 'cardiac', 'burns', 'respiratory', 'general'],
      bedCapacity: 2800,
      currentLoad: 72,
      emergencyTypesAccepted: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    ),
    HospitalModel(
      id: 'tn_madurai_meenakshi',
      name: 'Meenakshi Mission Hospital',
      location: const LatLng(9.9252, 78.1198),
      specialties: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
      bedCapacity: 600,
      currentLoad: 45,
      emergencyTypesAccepted: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    ),
    // Coimbatore
    HospitalModel(
      id: 'tn_coimbatore_cmch',
      name: 'Coimbatore Medical College Hospital (CMCH)',
      location: const LatLng(10.9995, 76.9660),
      specialties: ['general', 'trauma', 'cardiac', 'respiratory'],
      bedCapacity: 1500,
      currentLoad: 68,
      emergencyTypesAccepted: ['general', 'trauma', 'cardiac', 'respiratory'],
    ),
    HospitalModel(
      id: 'tn_coimbatore_kmch',
      name: 'Kovai Medical Center and Hospital (KMCH)',
      location: const LatLng(11.0400, 77.0270),
      specialties: ['general', 'trauma', 'cardiac'],
      bedCapacity: 1000,
      currentLoad: 55,
      emergencyTypesAccepted: ['general', 'trauma', 'cardiac'],
    ),
    // Trichy
    HospitalModel(
      id: 'tn_trichy_mgh',
      name: 'Mahatma Gandhi Memorial Government Hospital',
      location: const LatLng(10.8037, 78.6811),
      specialties: ['general', 'trauma', 'respiratory'],
      bedCapacity: 1200,
      currentLoad: 60,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory'],
    ),
    // Tirunelveli
    HospitalModel(
      id: 'tn_tirunelveli_mch',
      name: 'Tirunelveli Medical College Hospital',
      location: const LatLng(8.7139, 77.7479),
      specialties: ['general', 'trauma', 'respiratory'],
      bedCapacity: 1100,
      currentLoad: 70,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory'],
    ),
    // Vellore
    HospitalModel(
      id: 'tn_vellore_cmc',
      name: 'Christian Medical College (CMC) Vellore',
      location: const LatLng(12.9250, 79.1320),
      specialties: ['general', 'trauma', 'cardiac', 'burns', 'respiratory'],
      bedCapacity: 2800,
      currentLoad: 85,
      emergencyTypesAccepted: ['general', 'trauma', 'cardiac', 'burns', 'respiratory'],
    ),
    // Virudhunagar (Near KARE)
    HospitalModel(
      id: 'tn_virudhunagar_gh',
      name: 'Government Hospital Virudhunagar',
      location: const LatLng(9.5855, 77.9525),
      specialties: ['general', 'trauma', 'respiratory'],
      bedCapacity: 250,
      currentLoad: 62,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory', 'cardiac'],
    ),
    HospitalModel(
      id: 'tn_virudhunagar_chettinad',
      name: 'Chettinad Super Speciality Hospital',
      location: const LatLng(9.5800, 77.9600),
      specialties: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
      bedCapacity: 250,
      currentLoad: 50,
      emergencyTypesAccepted: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    ),
  ];
}
