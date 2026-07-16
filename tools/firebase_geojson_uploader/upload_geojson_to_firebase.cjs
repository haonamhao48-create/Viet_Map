
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
require('dotenv').config();

const admin = require('firebase-admin');

function fail(message) {
  console.error(`\n[ERROR] ${message}`);
  process.exit(1);
}

function normalizePath(p) {
  return path.resolve(process.cwd(), p);
}

function listGeoJsonFiles(dir) {
  if (!fs.existsSync(dir)) {
    fail(`Không tìm thấy thư mục: ${dir}`);
  }

  return fs
    .readdirSync(dir, { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith('.geojson'))
    .map((entry) => path.join(dir, entry.name))
    .sort();
}

function countCoordinatePairs(value) {
  if (!Array.isArray(value)) return 0;

  if (
    value.length >= 2 &&
    typeof value[0] === 'number' &&
    typeof value[1] === 'number'
  ) {
    return 1;
  }

  return value.reduce((sum, child) => sum + countCoordinatePairs(child), 0);
}

function getMetadata(geoJson, filePath) {
  if (
    !geoJson ||
    geoJson.type !== 'FeatureCollection' ||
    !Array.isArray(geoJson.features)
  ) {
    throw new Error('File không phải GeoJSON FeatureCollection hợp lệ');
  }

  const firstFeature = geoJson.features[0] ?? {};
  const properties = firstFeature.properties ?? {};
  const geometry = firstFeature.geometry ?? {};

  const code = String(
    properties.code ??
      firstFeature.id ??
      path.basename(filePath, path.extname(filePath))
  );

  return {
    code,
    name: properties.name ?? null,
    nameEn: properties.nameEn ?? null,
    fullName: properties.fullName ?? null,
    fullNameEn: properties.fullNameEn ?? null,
    codeName: properties.codeName ?? null,
    areaKm2: properties.areaKm2 ?? null,
    bbox: geoJson.bbox ?? firstFeature.bbox ?? null,
    featureCount: geoJson.features.length,
    geometryType: geometry.type ?? null,
    coordinatePointCount: countCoordinatePairs(geometry.coordinates),
  };
}

async function main() {
  const credentialPathRaw = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const bucketName = process.env.FIREBASE_STORAGE_BUCKET;

  if (!credentialPathRaw) {
    fail('Thiếu GOOGLE_APPLICATION_CREDENTIALS trong file .env');
  }

  if (!bucketName) {
    fail('Thiếu FIREBASE_STORAGE_BUCKET trong file .env');
  }

  const credentialPath = normalizePath(credentialPathRaw);
  if (!fs.existsSync(credentialPath)) {
    fail(`Không tìm thấy service account: ${credentialPath}`);
  }

  const sourceDir = normalizePath(
    process.env.GEOJSON_SOURCE_DIR ?? '../../assets/geojson'
  );
  const storagePrefix =
    process.env.GEOJSON_STORAGE_PREFIX ?? 'geojson/provinces';
  const collectionName =
    process.env.GEOJSON_FIRESTORE_COLLECTION ?? 'map_regions';

  const serviceAccount = JSON.parse(
    fs.readFileSync(credentialPath, 'utf8')
  );

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: bucketName,
  });

  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  const files = listGeoJsonFiles(sourceDir);
  if (files.length === 0) {
    fail(`Không có file .geojson trong: ${sourceDir}`);
  }

  console.log(`Nguồn: ${sourceDir}`);
  console.log(`Số file: ${files.length}`);
  console.log(`Storage prefix: ${storagePrefix}`);
  console.log(`Firestore collection: ${collectionName}\n`);

  let uploaded = 0;
  let failed = 0;

  for (const filePath of files) {
    const fileName = path.basename(filePath);

    try {
      const rawBuffer = fs.readFileSync(filePath);
      const geoJson = JSON.parse(rawBuffer.toString('utf8'));
      const metadata = getMetadata(geoJson, filePath);

      const storagePath = `${storagePrefix}/${fileName}`;
      const sha256 = crypto
        .createHash('sha256')
        .update(rawBuffer)
        .digest('hex');

      console.log(`[UPLOAD] ${fileName}`);

      await bucket.upload(filePath, {
        destination: storagePath,
        resumable: false,
        metadata: {
          contentType: 'application/geo+json',
          cacheControl: 'private,max-age=3600',
          metadata: {
            code: metadata.code,
            sha256,
          },
        },
      });

      await db.collection(collectionName).doc(metadata.code).set(
        {
          ...metadata,
          fileName,
          storagePath,
          byteSize: rawBuffer.length,
          sha256,
          version: sha256.slice(0, 12),
          active: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      uploaded += 1;
      console.log(
        `  OK: ${metadata.name ?? metadata.code} | ${rawBuffer.length} bytes | ${metadata.coordinatePointCount} điểm`
      );
    } catch (error) {
      failed += 1;
      console.error(`  FAIL: ${fileName}`);
      console.error(`  ${error.message}`);
    }
  }

  console.log('\n-----------------------------');
  console.log(`Hoàn tất: ${uploaded} file`);
  console.log(`Thất bại: ${failed} file`);

  if (failed > 0) process.exitCode = 1;
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
