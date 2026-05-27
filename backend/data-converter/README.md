# Viet Map Data Converter (Spring Boot)

Tool BE convert và **split** dữ liệu nặng trong `assets/`, giữ nguyên schema mà Flutter FE đang đọc. Không sửa code Flutter.

## Chức năng

1. **Tối ưu GeoJSON**
   - Douglas-Peucker simplify (JTS)
   - Làm tròn tọa độ (mặc định 6 chữ số thập phân)
   - Sửa `NaN` → `null`
2. **Giữ thuộc tính FE**
   - Tỉnh: `id`, `ten`, `type`, `ten_short`, `shapeName`, `macro_region`, `area_km2`, `population`, `density`, `centroid_lon/lat`, `capital`, `predecessors`, `is_archipelago`, …
   - Xã: `parent_ten`, `ten`, `type`, `area_km2`, `population`, `density`, `capital`, `predecessors`, …
3. **Split communes theo `parent_ma`**
   - `assets/geo/communes_by_province/{ma}.geojson`
   - `assets/geo/communes_by_province/manifest.json`
4. **Ghi đè file FE đang dùng** (có backup `.bak` trong `_backup/`)
   - `assets/geo/communes.geojson`
   - `assets/geo/vietnam_complete.geojson`
   - `assets/data/tourism_destinations.json`

## Chạy

```bash
cd backend/data-converter
mvn spring-boot:run
```

Gọi convert:

```bash
curl -X POST http://localhost:8088/api/convert/all
```

Hoặc từng phần:

```bash
curl -X POST http://localhost:8088/api/convert/communes
curl -X POST http://localhost:8088/api/convert/vietnam-complete
```

## API phụ (split)

```bash
curl http://localhost:8088/api/data/communes/manifest
curl http://localhost:8088/api/data/communes/01
```

## Cấu hình

`src/main/resources/application.yml`:

- `vietmap.converter.project-root`: thư mục gốc Flutter (mặc định `../..`)
- `vietmap.converter.simplify-tolerance`: độ simplify (mặc định `0.00008`)
- `vietmap.converter.coordinate-precision`: số chữ số tọa độ (mặc định `6`)

## Lưu ý

- FE hiện tại vẫn load `assets/geo/communes.geojson` (file merged đã tối ưu).
- Thư mục `communes_by_province/` dùng khi cần lazy-load theo tỉnh hoặc qua API BE.
