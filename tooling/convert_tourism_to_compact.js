const fs = require('fs');

const sourcePath = 'assets/data/tourism_destinations.json';
const targetPath = 'assets/data/tourism_destinations_compact.json';

const data = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));

const round = (value, digits) => Number(Number(value ?? 0).toFixed(digits));

const rows = (Array.isArray(data) ? data : []).map((item) => [
  Number(item?.id ?? 0),
  String(item?.name ?? ''),
  String(item?.province ?? ''),
  String(item?.description ?? ''),
  Array.isArray(item?.keywords)
      ? item.keywords.map((keyword) => String(keyword ?? ''))
      : [],
  round(item?.latitude, 5),
  round(item?.longitude, 5),
]);

fs.writeFileSync(targetPath, JSON.stringify(rows));

console.log(
  `Wrote ${rows.length} destinations to ${targetPath} (${fs.statSync(targetPath).size} bytes)`,
);
