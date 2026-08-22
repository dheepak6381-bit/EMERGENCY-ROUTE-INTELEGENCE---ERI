/**
 * ERI Firestore Seed Script
 * Seeds 6 hospitals near Kalasalingam Academy of Research and Education,
 * Krishnankoil, Tamil Nadu + 3 road condition segments.
 *
 * Run once: node scripts/seed_firestore.js
 * Requires: npm install firebase-admin
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

// ── Firebase Admin Init ────────────────────────────────────────────────────
// Option 1: Use service account key (download from Firebase Console > Settings > Service Accounts)
// Uncomment and set path:
// const serviceAccount = require('./serviceAccountKey.json');
// initializeApp({ credential: cert(serviceAccount) });

// Option 2: Use environment variable GOOGLE_APPLICATION_CREDENTIALS
// Set env var to path of service account key file
initializeApp({
  projectId: 'eri-ambulance',
});

const db = getFirestore();

// ── Hospital Data ─────────────────────────────────────────────────────────
// 6 real hospitals near Krishnankoil, Tamil Nadu
const hospitals = [
  {
    id: 'kare_hospital',
    name: 'KARE Hospital & Research Centre',
    lat: 9.4158,
    lng: 77.7063,
    specialties: ['general', 'respiratory'],
    bed_capacity: 300,
    current_load: 42,
    emergency_types_accepted: ['general', 'respiratory'],
    last_updated: Timestamp.now(),
  },
  {
    id: 'govt_krishnankoil',
    name: 'Government Hospital Krishnankoil',
    lat: 9.4238,
    lng: 77.7195,
    specialties: ['general', 'cardiac'],
    bed_capacity: 150,
    current_load: 65,
    emergency_types_accepted: ['general', 'cardiac'],
    last_updated: Timestamp.now(),
  },
  {
    id: 'aruna_sivakasi',
    name: 'Aruna Multi-Specialty Hospital, Sivakasi',
    lat: 9.4534,
    lng: 77.7984,
    specialties: ['cardiac', 'trauma', 'burns', 'general'],
    bed_capacity: 250,
    current_load: 38,
    emergency_types_accepted: ['cardiac', 'trauma', 'burns', 'general'],
    last_updated: Timestamp.now(),
  },
  {
    id: 'govt_virudhunagar',
    name: 'Govt. District HQ Hospital, Virudhunagar',
    lat: 9.5874,
    lng: 77.9614,
    specialties: ['cardiac', 'trauma', 'general', 'respiratory'],
    bed_capacity: 500,
    current_load: 78,
    emergency_types_accepted: ['trauma', 'general', 'respiratory'],
    last_updated: Timestamp.now(),
  },
  {
    id: 'meenakshi_mission',
    name: 'Meenakshi Mission Hospital, Madurai',
    lat: 9.9279,
    lng: 78.1198,
    specialties: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    bed_capacity: 750,
    current_load: 55,
    emergency_types_accepted: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    last_updated: Timestamp.now(),
  },
  {
    id: 'govt_rajaji',
    name: 'Govt. Rajaji Hospital, Madurai',
    lat: 9.9155,
    lng: 78.1151,
    specialties: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    bed_capacity: 2000,
    current_load: 85,
    emergency_types_accepted: ['cardiac', 'burns', 'respiratory', 'general'],
    last_updated: Timestamp.now(),
  },
];

// ── Road Condition Data ────────────────────────────────────────────────────
// 3 key road segments near KARE
const roadConditions = [
  {
    id: 'seg_nh44_krishnankoil',
    segment_id: 'NH44 near Krishnankoil',
    status: 'clear',
    center_lat: 9.4200,
    center_lng: 77.7150,
    bounds: [
      { lat: 9.4180, lng: 77.7100 },
      { lat: 9.4220, lng: 77.7200 },
    ],
    reported_at: Timestamp.now(),
    note: '',
  },
  {
    id: 'seg_srivilliputhur_rd',
    segment_id: 'Srivilliputhur–Rajapalayam Road',
    status: 'clear',
    center_lat: 9.4350,
    center_lng: 77.7400,
    bounds: [
      { lat: 9.4300, lng: 77.7300 },
      { lat: 9.4400, lng: 77.7500 },
    ],
    reported_at: Timestamp.now(),
    note: '',
  },
  {
    id: 'seg_virudhunagar_bypass',
    segment_id: 'Virudhunagar Bypass',
    status: 'clear',
    center_lat: 9.5700,
    center_lng: 77.9400,
    bounds: [
      { lat: 9.5600, lng: 77.9300 },
      { lat: 9.5800, lng: 77.9500 },
    ],
    reported_at: Timestamp.now(),
    note: '',
  },
];

// ── Seed Function ──────────────────────────────────────────────────────────
async function seed() {
  console.log('🌱 Seeding Firestore for ERI — eri-ambulance project...\n');

  // Seed hospitals
  const hospitalBatch = db.batch();
  for (const hospital of hospitals) {
    const { id, ...data } = hospital;
    const ref = db.collection('hospitals').doc(id);
    hospitalBatch.set(ref, data, { merge: true });
    console.log(`  ✅ Hospital: ${data.name} (load: ${data.current_load}%)`);
  }
  await hospitalBatch.commit();
  console.log(`\n✅ ${hospitals.length} hospitals seeded.\n`);

  // Seed road conditions
  const condBatch = db.batch();
  for (const cond of roadConditions) {
    const { id, ...data } = cond;
    const ref = db.collection('road_conditions').doc(id);
    condBatch.set(ref, data, { merge: true });
    console.log(`  ✅ Road segment: ${data.segment_id} (${data.status})`);
  }
  await condBatch.commit();
  console.log(`\n✅ ${roadConditions.length} road conditions seeded.\n`);

  console.log('🚀 Seeding complete! Open Firebase Console to verify:');
  console.log('   https://console.firebase.google.com/project/eri-ambulance/firestore\n');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
