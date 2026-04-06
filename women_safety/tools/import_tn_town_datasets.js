/*
  Bulk import Tamil Nadu town safety datasets into Firestore.

  Usage:
    1) npm init -y
    2) npm install firebase-admin
    3) set GOOGLE_APPLICATION_CREDENTIALS=<path to service-account.json>
    4) node tools/import_tn_town_datasets.js data/tn_town_safety_dataset_template.json
*/

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const COLLECTION = 'tn_town_safety_datasets';

function normalizeTownName(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, '_');
}

function asNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function normalizeRisk(value) {
  const normalized = String(value || 'LOW').trim().toUpperCase();
  if (normalized === 'HIGH' || normalized === 'MEDIUM' || normalized === 'LOW') {
    return normalized;
  }
  return 'LOW';
}

function validateTownRecord(record, index) {
  const errors = [];
  if (!record || typeof record !== 'object') {
    errors.push(`Record ${index}: must be an object`);
    return errors;
  }

  if (!record.town || !String(record.town).trim()) {
    errors.push(`Record ${index}: town is required`);
  }

  if (asNumber(record.latitude) === null || asNumber(record.longitude) === null) {
    errors.push(`Record ${index}: latitude and longitude are required numeric fields`);
  }

  if (!Array.isArray(record.riskyAreas)) {
    errors.push(`Record ${index}: riskyAreas must be an array`);
  }

  if (!Array.isArray(record.policeStations)) {
    errors.push(`Record ${index}: policeStations must be an array`);
  }

  return errors;
}

function normalizeDatasetRecord(record) {
  const latitude = asNumber(record.latitude);
  const longitude = asNumber(record.longitude);

  const riskyAreas = (record.riskyAreas || []).map((area) => ({
    name: String(area.name || '').trim(),
    latitude: asNumber(area.latitude),
    longitude: asNumber(area.longitude),
    risk: normalizeRisk(area.risk),
    reason: String(area.reason || '').trim(),
  })).filter((area) => area.name && area.latitude !== null && area.longitude !== null);

  const policeStations = (record.policeStations || []).map((station) => ({
    name: String(station.name || '').trim(),
    latitude: asNumber(station.latitude),
    longitude: asNumber(station.longitude),
    type: String(station.type || 'Police Station').trim(),
    contact: String(station.contact || '+91 100').trim(),
  })).filter((station) => station.name && station.latitude !== null && station.longitude !== null);

  const governmentSources = (record.governmentSources || []).map((source) => ({
    name: String(source.name || '').trim(),
    url: String(source.url || '').trim(),
    dataset: String(source.dataset || '').trim(),
    integrationMode: String(source.integrationMode || 'curated_snapshot').trim(),
  })).filter((source) => source.name);

  return {
    town: String(record.town || '').trim(),
    latitude,
    longitude,
    center: new admin.firestore.GeoPoint(latitude, longitude),
    riskyAreas,
    policeStations,
    governmentSources,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function run() {
  const argPath = process.argv[2];
  if (!argPath) {
    throw new Error('Provide dataset JSON path. Example: node tools/import_tn_town_datasets.js data/tn_town_safety_dataset_template.json');
  }

  const datasetPath = path.resolve(process.cwd(), argPath);
  if (!fs.existsSync(datasetPath)) {
    throw new Error(`Dataset file not found: ${datasetPath}`);
  }

  const raw = fs.readFileSync(datasetPath, 'utf8');
  const payload = JSON.parse(raw);

  if (!Array.isArray(payload)) {
    throw new Error('Dataset JSON must be an array of town records');
  }

  const allErrors = [];
  payload.forEach((record, index) => {
    allErrors.push(...validateTownRecord(record, index));
  });

  if (allErrors.length > 0) {
    throw new Error(`Validation failed:\n${allErrors.join('\n')}`);
  }

  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }

  const db = admin.firestore();
  const batch = db.batch();

  let count = 0;
  for (const record of payload) {
    const normalizedTown = normalizeTownName(record.town);
    const docRef = db.collection(COLLECTION).doc(normalizedTown);
    const normalized = normalizeDatasetRecord(record);
    batch.set(docRef, normalized, { merge: true });
    count += 1;
  }

  await batch.commit();
  console.log(`Imported ${count} Tamil Nadu town records into ${COLLECTION}`);
}

run().catch((err) => {
  console.error('Import failed:', err.message);
  process.exit(1);
});
