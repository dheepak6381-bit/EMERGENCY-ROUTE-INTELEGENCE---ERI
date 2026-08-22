/**
 * ERI Firestore Seed Script — REST API version
 * Uses Firebase REST API with the web API key (no service account needed)
 * 
 * Run: node scripts/seed_rest.js
 * No additional packages needed — uses built-in fetch (Node 18+)
 */

const PROJECT_ID = 'eri-ambulance';
const API_KEY = 'AIzaSyANzlDkcRjPNzo6VLvwmS6S3zpMNVYD_Gk';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ── Helpers ───────────────────────────────────────────────────────────────

function toFirestoreValue(value) {
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: value.toString() };
    return { doubleValue: value };
  }
  if (typeof value === 'boolean') return { booleanValue: value };
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map(toFirestoreValue)
      }
    };
  }
  if (value && typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { nullValue: null };
}

function toFirestoreDoc(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (k === 'last_updated' || k === 'reported_at') {
      fields[k] = { timestampValue: new Date().toISOString() };
    } else {
      fields[k] = toFirestoreValue(v);
    }
  }
  return { fields };
}

async function setDocument(collection, docId, data) {
  const url = `${BASE_URL}/${collection}/${docId}?key=${API_KEY}`;
  const body = JSON.stringify(toFirestoreDoc(data));
  
  const response = await fetch(url, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body,
  });
  
  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Failed to write ${collection}/${docId}: ${response.status} ${err}`);
  }
  return response.json();
}

// ── Hospital Data ─────────────────────────────────────────────────────────
const hospitals = [
  {
    id: 'kare_hospital',
    data: {
      name: 'KARE Hospital & Research Centre',
      lat: 9.4158,
      lng: 77.7063,
      specialties: ['general', 'respiratory'],
      bed_capacity: 300,
      current_load: 42,
      emergency_types_accepted: ['general', 'respiratory'],
    }
  },
  {
    id: 'govt_krishnankoil',
    data: {
      name: 'Government Hospital Krishnankoil',
      lat: 9.4238,
      lng: 77.7195,
      specialties: ['general', 'cardiac'],
      bed_capacity: 150,
      current_load: 65,
      emergency_types_accepted: ['general', 'cardiac'],
    }
  },
  {
    id: 'aruna_sivakasi',
    data: {
      name: 'Aruna Multi-Specialty Hospital, Sivakasi',
      lat: 9.4534,
      lng: 77.7984,
      specialties: ['cardiac', 'trauma', 'burns', 'general'],
      bed_capacity: 250,
      current_load: 38,
      emergency_types_accepted: ['cardiac', 'trauma', 'burns', 'general'],
    }
  },
  {
    id: 'govt_virudhunagar',
    data: {
      name: 'Govt. District HQ Hospital, Virudhunagar',
      lat: 9.5874,
      lng: 77.9614,
      specialties: ['cardiac', 'trauma', 'general', 'respiratory'],
      bed_capacity: 500,
      current_load: 78,
      emergency_types_accepted: ['trauma', 'general', 'respiratory'], // Cannot accept cardiac due to load
    }
  },
  {
    id: 'meenakshi_mission',
    data: {
      name: 'Meenakshi Mission Hospital, Madurai',
      lat: 9.9279,
      lng: 78.1198,
      specialties: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
      bed_capacity: 750,
      current_load: 55,
      emergency_types_accepted: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
    }
  },
  {
    id: 'govt_rajaji',
    data: {
      name: 'Govt. Rajaji Hospital, Madurai',
      lat: 9.9155,
      lng: 78.1151,
      specialties: ['cardiac', 'trauma', 'burns', 'respiratory', 'general'],
      bed_capacity: 2000,
      current_load: 85,
      emergency_types_accepted: ['cardiac', 'burns', 'respiratory', 'general'], // Trauma full
    }
  },
];

// ── Road Condition Data ────────────────────────────────────────────────────
const roadConditions = [
  {
    id: 'seg_nh44_krishnankoil',
    data: {
      segment_id: 'NH44 near Krishnankoil',
      status: 'clear',
      center_lat: 9.4200,
      center_lng: 77.7150,
      bounds: [
        { lat: 9.4180, lng: 77.7100 },
        { lat: 9.4220, lng: 77.7200 },
      ],
      note: '',
    }
  },
  {
    id: 'seg_srivilliputhur_rd',
    data: {
      segment_id: 'Srivilliputhur-Rajapalayam Road',
      status: 'clear',
      center_lat: 9.4350,
      center_lng: 77.7400,
      bounds: [
        { lat: 9.4300, lng: 77.7300 },
        { lat: 9.4400, lng: 77.7500 },
      ],
      note: '',
    }
  },
  {
    id: 'seg_virudhunagar_bypass',
    data: {
      segment_id: 'Virudhunagar Bypass',
      status: 'clear',
      center_lat: 9.5700,
      center_lng: 77.9400,
      bounds: [
        { lat: 9.5600, lng: 77.9300 },
        { lat: 9.5800, lng: 77.9500 },
      ],
      note: '',
    }
  },
];

// ── Main Seed ─────────────────────────────────────────────────────────────
async function seed() {
  console.log('\n🌱 ERI Firestore Seed — eri-ambulance\n');
  console.log('📍 Seeding hospitals near Krishnankoil, Tamil Nadu...\n');

  for (const h of hospitals) {
    try {
      await setDocument('hospitals', h.id, h.data);
      console.log(`  ✅ ${h.data.name} (${h.data.current_load}% load)`);
    } catch (e) {
      console.error(`  ❌ Failed: ${h.data.name}`, e.message);
    }
  }

  console.log('\n🛣️  Seeding road conditions...\n');
  for (const r of roadConditions) {
    try {
      await setDocument('road_conditions', r.id, r.data);
      console.log(`  ✅ ${r.data.segment_id} (${r.data.status})`);
    } catch (e) {
      console.error(`  ❌ Failed: ${r.data.segment_id}`, e.message);
    }
  }

  console.log('\n🚀 Seeding complete!');
  console.log('   Verify at: https://console.firebase.google.com/project/eri-ambulance/firestore\n');
}

seed().catch(console.error);
