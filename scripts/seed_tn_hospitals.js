/**
 * Fetch all hospitals in Tamil Nadu using Overpass API and seed them to Firestore.
 * Run: node scripts/seed_tn_hospitals.js
 */

const PROJECT_ID = 'eri-ambulance';
const API_KEY = 'AIzaSyANzlDkcRjPNzo6VLvwmS6S3zpMNVYD_Gk';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// We will fetch up to 100 hospitals to prevent too much map clutter, but they will be distributed across TN.
const OVERPASS_URL = 'https://overpass-api.de/api/interpreter';
const OVERPASS_QUERY = `
  [out:json];
  area["name"="Tamil Nadu"]->.searchArea;
  node["amenity"="hospital"](area.searchArea);
  out 100;
`;

const ALL_SPECIALTIES = ['cardiac', 'trauma', 'burns', 'respiratory', 'general'];

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function getRandomSpecialties() {
  const count = getRandomInt(1, 4);
  const shuffled = ALL_SPECIALTIES.sort(() => 0.5 - Math.random());
  const selected = shuffled.slice(0, count);
  if (!selected.includes('general')) selected.push('general');
  return selected;
}

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

async function seed() {
  console.log('Fetching hospitals in Tamil Nadu from Overpass API...');
  const url = OVERPASS_URL + '?data=' + encodeURIComponent(OVERPASS_QUERY);
  const res = await fetch(url, {
    method: 'GET',
    headers: {
      'Accept': 'application/json',
      'User-Agent': 'ERI_App/1.0'
    }
  });
  
  if (!res.ok) {
    const text = await res.text();
    throw new Error('Failed to fetch from Overpass API: ' + text);
  }

  const data = await res.json();
  const nodes = data.elements.filter(e => e.type === 'node' && e.tags && e.tags.name);
  console.log(`Found ${nodes.length} hospitals with names.`);

  for (let i = 0; i < nodes.length; i++) {
    const node = nodes[i];
    const id = `tn_hosp_${node.id}`;
    const name = node.tags.name;
    const specialties = getRandomSpecialties();
    
    // Simulate some hospitals being at capacity for certain emergencies
    const emergencyTypesAccepted = [...specialties];
    if (Math.random() > 0.7 && emergencyTypesAccepted.length > 1) {
      emergencyTypesAccepted.pop(); // Remove one specialty from accepted
    }

    const hospitalData = {
      name: name,
      lat: node.lat,
      lng: node.lon,
      specialties: specialties,
      bed_capacity: getRandomInt(50, 1000),
      current_load: getRandomInt(20, 95),
      emergency_types_accepted: emergencyTypesAccepted,
    };

    try {
      await setDocument('hospitals', id, hospitalData);
      console.log(`✅ [${i+1}/${nodes.length}] Added ${name}`);
    } catch (err) {
      console.error(`❌ Failed to add ${name}:`, err.message);
    }
  }
  
  console.log('🚀 Seeding complete!');
}

seed().catch(console.error);
