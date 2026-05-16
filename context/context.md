# VN Map App — Project Context

## 1. Project Overview

Project Name:

```txt
VN Map App
```

Project Goal:

Build a cross-platform Vietnamese administrative map application using Flutter.

Development roadmap:

```txt
Desktop App
→ Mobile App
→ Unified Cross-Platform Application
```

The application will support:

* Vietnam map visualization
* Province polygon rendering
* Province/city search
* Polygon click interaction
* Zoom / pan map navigation
* Information sidebar
* Heatmap / statistics
* Offline mode
* Responsive desktop/mobile layouts

---

# 2. Tech Stack

## Frontend

```txt
Flutter
```

## State Management

```txt
Riverpod
```

## Routing

```txt
GoRouter
```

## Map Rendering

Planned:

```txt
flutter_map
```

or:

```txt
syncfusion_flutter_maps
```

## Local Database

Planned:

```txt
SQLite
```

## Dataset

Dataset source:

[https://huggingface.co/datasets/tmquan/sapnhap-bando-vn](https://huggingface.co/datasets/tmquan/sapnhap-bando-vn)

Dataset includes:

```txt
provinces.geojson
communes.geojson
vietnam_complete.geojson
provinces.parquet
communes.parquet
committees.parquet
```

---

# 3. Project Architecture

Current folder structure:

```txt
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   └── router.dart
│
├── core/
│   ├── constants/
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│
├── features/
│   └── map/
│       ├── data/
│       │   ├── datasources/
│       │   └── models/
│       │
│       └── presentation/
│           ├── providers/
│           ├── screens/
│           └── widgets/
│
└── shared/
    └── widgets/
```

---

# 4. Asset Structure

```txt
assets/
│
├── geo/
│   ├── provinces.geojson
│   ├── communes.geojson
│   └── vietnam_complete.geojson
│
└── data/
    ├── provinces.parquet
    ├── communes.parquet
    └── committees.parquet
```

Current development phase only uses:

```txt
- provinces.geojson
```

Not rendering yet:

```txt
communes.geojson
```

because the dataset is very large and heavy.

---

# 5. Current Project Status

## Completed

### Phase 1 — Desktop Foundation

Completed:

* Flutter Windows Desktop setup
* Folder structure
* Riverpod setup
* GoRouter setup
* Theme setup
* Basic desktop layout
* Sidebar
* Placeholder map area

### Phase 2 — Dataset Integration

Completed:

* Full dataset download
* Asset setup
* GeoJSON loading with rootBundle
* GeoJSON parsing
* Province model
* Riverpod provider

Resolved issue:

```txt
NaN values inside GeoJSON
```

by replacing:

```txt
NaN → null
```

---

# 6. Next Goal

## Phase 3 — Real Map Rendering

Target flow:

```txt
GeoJSON
→ Parse polygons
→ Convert coordinates
→ Render polygons
→ Click interaction
```

Features to implement:

* Province polygon rendering
* Zoom / pan
* Hover effect
* Polygon click interaction
* Focus selected province

---

# 7. Architecture Rules

## Do not read JSON directly inside UI

Correct flow:

```txt
GeoJSON
→ DataSource
→ Repository
→ Provider
→ UI
```

## UI must not contain business logic

## Prepare architecture for mobile

Shared code location:

```txt
lib/
```

Avoid placing business logic inside:

```txt
windows/
android/
ios/
```

---

# 8. Long-Term Goals

The final application should support:

* Desktop
* Android
* iOS
* Offline GIS-lite features
* Search
* Statistics
* Heatmap
* Administrative timeline visualization
* Responsive layout
* Dark mode
* Multi-layer maps

---

# 9. Coding Rules

## Naming Convention

```txt
snake_case for files
PascalCase for classes
camelCase for variables
```

## Widget Structure

Preferred approach:

```txt
Small reusable widgets
```

## State Management

Only use:

```txt
Riverpod
```

## Routing

Only use:

```txt
GoRouter
```

---

# 10. Current UI Layout

Desktop layout:

```txt
┌───────────────────────────────┐
│ Sidebar      │ Map Area      │
│               │               │
│ Search        │ Placeholder   │
│ Province List │               │
└───────────────┴───────────────┘
```

---

# 11. Flutter Version

Project uses:

```txt
Dart SDK >=3.0.0 <4.0.0
```

---

# 12. Development Roadmap

```txt
Phase 1:
Desktop Foundation

Phase 2:
Dataset Integration

Phase 3:
Map Rendering

Phase 4:
Interaction + Search

Phase 5:
Mobile Layout

Phase 6:
Cross-platform Shared App

Phase 7:
Optimization + GIS Features
```
