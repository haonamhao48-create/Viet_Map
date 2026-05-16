import 'geo_point.dart';
import 'province_polygon.dart';

class ProvinceModel {
  final String id;
  final String name;
  final String type;
  final String shortName;
  final String shapeName;
  final String macroRegion;
  final double areaKm2;
  final int population;
  final double density;
  final double centroidLon;
  final double centroidLat;
  final String? capital;
  final String? predecessors;
  final bool isArchipelago;
  final Map<String, dynamic> geometry;
  final List<ProvincePolygon> polygons;

  ProvinceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.shortName,
    required this.shapeName,
    required this.macroRegion,
    required this.areaKm2,
    required this.population,
    required this.density,
    required this.centroidLon,
    required this.centroidLat,
    required this.isArchipelago,
    required this.geometry,
    required this.polygons,
    this.capital,
    this.predecessors,
  });

  factory ProvinceModel.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;

    return ProvinceModel(
      id: properties['id']?.toString() ?? '',
      name: properties['ten']?.toString() ?? '',
      type: properties['type']?.toString() ?? '',
      shortName: properties['ten_short']?.toString() ?? '',
      shapeName: properties['shapeName']?.toString() ?? '',
      macroRegion: properties['macro_region']?.toString() ?? '',
      areaKm2: _toDouble(properties['area_km2']),
      population: _toInt(properties['population']),
      density: _toDouble(properties['density']),
      centroidLon: _toDouble(properties['centroid_lon']),
      centroidLat: _toDouble(properties['centroid_lat']),
      capital: properties['capital']?.toString(),
      predecessors: properties['predecessors']?.toString(),
      isArchipelago: properties['is_archipelago'] == true,
      geometry: geometry,
      polygons: _parsePolygons(geometry),
    );
  }

  String get displayName {
    if (shapeName.isNotEmpty) {
      return shapeName;
    }
    return name;
  }

  bool get isDerivedArchipelago {
    return isArchipelago ||
        displayName.contains('Hoàng Sa') ||
        displayName.contains('Trường Sa') ||
        displayName.contains('Hoang Sa') ||
        displayName.contains('Truong Sa');
  }

  static List<ProvincePolygon> _parsePolygons(Map<String, dynamic> geometry) {
    final type = geometry['type']?.toString() ?? '';
    final coordinates = geometry['coordinates'];

    if (coordinates is! List) {
      return const [];
    }

    switch (type) {
      case 'Polygon':
        return [_polygonFromCoordinates(coordinates)];
      case 'MultiPolygon':
        return coordinates
            .whereType<List>()
            .map(_polygonFromCoordinates)
            .toList(growable: false);
      default:
        return const [];
    }
  }

  static ProvincePolygon _polygonFromCoordinates(List coordinates) {
    final rings = coordinates
        .whereType<List>()
        .map(
          (ring) => ring
              .whereType<List>()
              .map(
                (point) => GeoPoint(
                  longitude: _coordinateValue(point, 0),
                  latitude: _coordinateValue(point, 1),
                ),
              )
              .toList(growable: false),
        )
        .where((ring) => ring.length >= 3)
        .toList(growable: false);

    return ProvincePolygon(rings: rings);
  }

  static double _coordinateValue(List point, int index) {
    if (index >= point.length) {
      return 0;
    }

    return _toDouble(point[index]);
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }
}
