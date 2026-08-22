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
}

// Specialties to randomly assign if not specified
const allSpecialties = ['general', 'cardiac', 'trauma', 'burns', 'respiratory'];

function getRandomSpecialties() {
  const specs = new Set(['general']);
  const numExtra = Math.floor(Math.random() * 3) + 1;
  for (let i = 0; i < numExtra; i++) {
    const randomSpec = allSpecialties[Math.floor(Math.random() * allSpecialties.length)];
    specs.add(randomSpec);
  }
  return Array.from(specs);
}

async function fetchAndSeed() {
  console.log('🌍 Fetching all hospitals in Tamil Nadu from Overpass API...');
  
  const query = `
    [out:json][timeout:60];
    area["name"="Tamil Nadu"]["admin_level"="4"]->.searchArea;
    (
      node["amenity"="hospital"](area.searchArea);
      way["amenity"="hospital"](area.searchArea);
      relation["amenity"="hospital"](area.searchArea);
    );
    out center;
  `;

  try {
    const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`;
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'ERI Ambulance Fetcher/1.0',
        'Accept': '*/*'
      }
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Overpass API failed: ${response.statusText}\n${errText}`);
    }

    const data = await response.json();
    const elements = data.elements || [];
    
    console.log(`✅ Found ${elements.length} hospitals in Tamil Nadu.`);
    if (elements.length === 0) return;

    console.log(`🚀 Seeding ${elements.length} hospitals to Firestore using REST API...`);
    
    let totalSeeded = 0;
    
    // We cannot easily delete all docs via REST without a complex query, 
    // so we will just overwrite or add new ones. Overwriting is fine!

    // Batch them using Promise.all in chunks of 50 to avoid overloading the REST API
    const chunkSize = 50;
    for (let i = 0; i < elements.length; i += chunkSize) {
      const chunk = elements.slice(i, i + chunkSize);
      
      const promises = chunk.map(async (el) => {
        const lat = el.lat || el.center?.lat;
        const lon = el.lon || el.center?.lon;
        if (!lat || !lon) return;

        const name = el.tags?.name || el.tags?.['name:en'] || 'Unnamed Hospital';
        const id = `tn_hosp_${el.id}`;
        
        const bedCapacity = Math.floor(Math.random() * 750) + 50;
        const loadPercent = Math.floor(Math.random() * 55) + 40;
        const specialties = getRandomSpecialties();

        const hospitalData = {
          name,
          lat,
          lng: lon,
          specialties,
          bed_capacity: bedCapacity,
          current_load: loadPercent,
          emergency_types_accepted: specialties,
          last_updated: new Date().toISOString(),
        };

        await setDocument('hospitals', id, hospitalData);
      });

      await Promise.all(promises);
      totalSeeded += chunk.length;
      console.log(`  ...seeded ${totalSeeded}/${elements.length}`);
    }

    console.log(`\n🎉 Successfully seeded ${totalSeeded} hospitals across Tamil Nadu!`);
    process.exit(0);

  } catch (err) {
    console.error('❌ Failed to seed:', err);
    process.exit(1);
  }
}

fetchAndSeed();
