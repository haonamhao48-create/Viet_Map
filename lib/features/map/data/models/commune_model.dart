import 'geo_point.dart';
import 'province_polygon.dart'; // We can reuse ProvincePolygon or rename it to generic MapPolygon, but reusing is fine.

class CommuneModel {
  final String id;
  final String ma;
  final String name;
  final String type;
  final String parentMa;
  final String parentTen;
  final double areaKm2;
  final double population;
  final double density;
  final List<ProvincePolygon> polygons;
  final Map<String, dynamic> rawProperties;

  CommuneModel({
    required this.id,
    required this.ma,
    required this.name,
    required this.type,
    required this.parentMa,
    required this.parentTen,
    required this.areaKm2,
    required this.population,
    required this.density,
    required this.polygons,
    required this.rawProperties,
  });

  factory CommuneModel.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};

    return CommuneModel(
      id: properties['id']?.toString() ?? properties['ma']?.toString() ?? '',
      ma: properties['ma']?.toString() ?? '',
      name: properties['ten']?.toString() ?? '',
      type: properties['type']?.toString() ?? '',
      parentMa: properties['parent_ma']?.toString() ?? '',
      parentTen: properties['parent_ten']?.toString() ?? '',
      areaKm2: _toDouble(properties['area_km2']),
      population: _toDouble(properties['population']),
      density: _toDouble(properties['density']),
      polygons: _parseGeometry(geometry),
      rawProperties: properties,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }

  static List<ProvincePolygon> _parseGeometry(Map<String, dynamic> geometry) {
    final type = geometry['type']?.toString();
    final coordinates = geometry['coordinates'];

    if (coordinates is! List) return const [];

    if (type == 'Polygon') {
      return [_polygonFromCoordinates(coordinates)];
    } else if (type == 'MultiPolygon') {
      return coordinates
          .whereType<List>()
          .map(_polygonFromCoordinates)
          .toList(growable: false);
    }

    return const [];
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
    if (index >= point.length) return 0;
    return _toDouble(point[index]);
  }
}
