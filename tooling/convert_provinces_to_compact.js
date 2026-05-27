const fs = require('fs');

const sourcePath = 'assets/geo/vietnam_complete.geojson';
const targetPath = 'assets/data/provinces_compact.json';

let text = fs.readFileSync(sourcePath, 'utf8');

for (const [oldValue, newValue] of [
  [': NaN', ': null'],
  [':NaN', ':null'],
  ['[NaN', '[null'],
  [', NaN', ', null'],
  [',NaN', ',null'],
]) {
  text = text.split(oldValue).join(newValue);
}

const data = JSON.parse(text);

const round = (value, digits) => Number(Number(value ?? 0).toFixed(digits));
const roundPoint = (point) => [round(point?.[0], 5), round(point?.[1], 5)];

const normalizePolygons = (geometry) => {
  const type = geometry?.type ?? '';
  const coordinates = geometry?.coordinates;
  if (!Array.isArray(coordinates)) {
    return [];
  }

  const polygons = type === 'Polygon' ? [coordinates] : coordinates;
  return polygons.map((polygon) =>
    (Array.isArray(polygon) ? polygon : []).map((ring) =>
      (Array.isArray(ring) ? ring : []).map(roundPoint),
    ),
  );
};

const rows = (data.features || []).map((feature) => {
  const properties = feature.properties || {};

  return [
    String(properties.id ?? ''),
    String(properties.ten ?? ''),
    String(properties.type ?? ''),
    String(properties.ten_short ?? ''),
    String(properties.shapeName ?? ''),
    String(properties.macro_region ?? ''),
    round(properties.area_km2, 2),
    Number(properties.population ?? 0),
    round(properties.density, 2),
    round(properties.centroid_lon, 5),
    round(properties.centroid_lat, 5),
    properties.capital ?? null,
    properties.predecessors ?? null,
    properties.is_archipelago === true,
    normalizePolygons(feature.geometry || {}),
  ];
});

fs.writeFileSync(targetPath, JSON.stringify(rows));

console.log(
  `Wrote ${rows.length} provinces to ${targetPath} (${fs.statSync(targetPath).size} bytes)`,
);
