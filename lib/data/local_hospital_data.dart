import 'package:latlong2/latlong.dart';
import 'models/hospital_model.dart';

/// Hardcoded hospital data for the Virudhunagar / Madurai / Krishnankoil region.
/// Acts as fallback when Firestore is empty or unavailable.
/// All coordinates are approximate real locations.
class LocalHospitalData {
  LocalHospitalData._();

  static List<HospitalModel> get hospitals => _hospitals;

  static final List<HospitalModel> _hospitals = [
    HospitalModel(
      id: 'local_govt_virudhunagar',
      name: 'Govt Hospital Virudhunagar',
      location: const LatLng(9.5855, 77.9525),
      specialties: ['general', 'trauma', 'respiratory'],
      bedCapacity: 250,
      currentLoad: 62,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory', 'cardiac'],
    ),
    HospitalModel(
      id: 'local_meenakshi_mission',
      name: 'Meenakshi Mission Hospital',
      location: const LatLng(9.9252, 78.1198),
      specialties: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
      bedCapacity: 600,
      currentLoad: 45,
      emergencyTypesAccepted: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    ),
    HospitalModel(
      id: 'local_govt_rajaji',
      name: 'Govt Rajaji Hospital Madurai',
      location: const LatLng(9.9195, 78.1190),
      specialties: ['trauma', 'cardiac', 'burns', 'respiratory', 'general'],
      bedCapacity: 2800,
      currentLoad: 72,
      emergencyTypesAccepted: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    ),
    HospitalModel(
      id: 'local_apollo_madurai',
      name: 'Apollo Hospitals Madurai',
      location: const LatLng(9.9400, 78.1210),
      specialties: ['cardiac', 'trauma', 'respiratory', 'general'],
      bedCapacity: 200,
      currentLoad: 38,
      emergencyTypesAccepted: ['cardiac', 'trauma', 'respiratory', 'general'],
    ),
    HospitalModel(
      id: 'local_velammal_medical',
      name: 'Velammal Medical College Hospital',
      location: const LatLng(9.3750, 77.6825),
      specialties: ['general', 'trauma', 'respiratory'],
      bedCapacity: 350,
      currentLoad: 55,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory', 'cardiac'],
    ),
    HospitalModel(
      id: 'local_sivakasi_govt',
      name: 'Govt Hospital Sivakasi',
      location: const LatLng(9.4490, 77.7980),
      specialties: ['general', 'burns', 'trauma'],
      bedCapacity: 150,
      currentLoad: 40,
      emergencyTypesAccepted: ['general', 'burns', 'trauma'],
    ),
    HospitalModel(
      id: 'local_srivilliputtur_govt',
      name: 'Govt Hospital Srivilliputtur',
      location: const LatLng(9.5120, 77.6340),
      specialties: ['general', 'trauma'],
      bedCapacity: 120,
      currentLoad: 35,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory'],
    ),
    HospitalModel(
      id: 'local_rajapalayam_govt',
      name: 'Govt Hospital Rajapalayam',
      location: const LatLng(9.4525, 77.5560),
      specialties: ['general', 'trauma', 'respiratory'],
      bedCapacity: 180,
      currentLoad: 48,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory'],
    ),
    HospitalModel(
      id: 'local_kare_health_center',
      name: 'KARE Health Center',
      location: const LatLng(9.4155, 77.7060),
      specialties: ['general'],
      bedCapacity: 30,
      currentLoad: 20,
      emergencyTypesAccepted: ['general'],
    ),
    HospitalModel(
      id: 'local_vadipatti_phc',
      name: 'PHC Vadipatti',
      location: const LatLng(9.8690, 77.9610),
      specialties: ['general'],
      bedCapacity: 40,
      currentLoad: 30,
      emergencyTypesAccepted: ['general', 'respiratory'],
    ),
    HospitalModel(
      id: 'local_theni_govt',
      name: 'Govt Hospital Theni',
      location: const LatLng(10.0104, 77.4764),
      specialties: ['general', 'trauma', 'cardiac'],
      bedCapacity: 300,
      currentLoad: 58,
      emergencyTypesAccepted: ['general', 'trauma', 'cardiac', 'respiratory'],
    ),
    HospitalModel(
      id: 'local_dindigul_govt',
      name: 'Govt Hospital Dindigul',
      location: const LatLng(10.3624, 77.9695),
      specialties: ['general', 'trauma', 'respiratory'],
      bedCapacity: 400,
      currentLoad: 65,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory', 'cardiac'],
    ),
    HospitalModel(
      id: 'local_aruppukottai_gh',
      name: 'Govt Hospital Aruppukottai',
      location: const LatLng(9.5082, 78.0962),
      specialties: ['general', 'trauma'],
      bedCapacity: 100,
      currentLoad: 42,
      emergencyTypesAccepted: ['general', 'trauma'],
    ),
    HospitalModel(
      id: 'local_chettinad_hospital',
      name: 'Chettinad Super Speciality Hospital',
      location: const LatLng(9.5800, 77.9600),
      specialties: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
      bedCapacity: 250,
      currentLoad: 50,
      emergencyTypesAccepted: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    ),
    HospitalModel(
      id: 'local_sdh_sattur',
      name: 'Sub District Hospital Sattur',
      location: const LatLng(9.3525, 77.9180),
      specialties: ['general', 'trauma'],
      bedCapacity: 80,
      currentLoad: 38,
      emergencyTypesAccepted: ['general', 'trauma', 'respiratory'],
    ),
  ];
}
