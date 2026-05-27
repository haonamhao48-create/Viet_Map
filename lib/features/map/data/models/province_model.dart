import '../../../../core/utils/text_normalizer.dart';
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
    required this.polygons,
    this.capital,
    this.predecessors,
  });

  factory ProvinceModel.fromCompactJsonRow(List<dynamic> row) {
    return ProvinceModel(
      id: _stringAt(row, 0),
      name: _stringAt(row, 1),
      type: _stringAt(row, 2),
      shortName: _stringAt(row, 3),
      shapeName: _stringAt(row, 4),
      macroRegion: _stringAt(row, 5),
      areaKm2: _toDouble(_valueAt(row, 6)),
      population: _toInt(_valueAt(row, 7)),
      density: _toDouble(_valueAt(row, 8)),
      centroidLon: _toDouble(_valueAt(row, 9)),
      centroidLat: _toDouble(_valueAt(row, 10)),
      capital: _nullableStringAt(row, 11),
      predecessors: _nullableStringAt(row, 12),
      isArchipelago: _valueAt(row, 13) == true,
      polygons: _parseCompactPolygons(_valueAt(row, 14)),
    );
  }

  String get displayName {
    if (shapeName.isNotEmpty) {
      return shapeName;
    }
    return name;
  }

  late final String normalizedDisplayName = TextNormalizer.normalizeVietnamese(
    displayName,
  );

  bool get isHoangSaArchipelago {
    return normalizedDisplayName.contains('hoang sa');
  }

  bool get isTruongSaArchipelago {
    return normalizedDisplayName.contains('truong sa');
  }

  bool get isDerivedArchipelago {
    return isArchipelago || isHoangSaArchipelago || isTruongSaArchipelago;
  }

  late final String normalizedSearchText = TextNormalizer.normalizeVietnamese(
    [displayName, name, shortName, type, capital ?? '', macroRegion].join(' '),
  );

  late final Set<String> normalizedProvinceKeys = {displayName, name, shortName}
      .map(TextNormalizer.normalizeProvinceKey)
      .where((value) => value.isNotEmpty)
      .toSet();

  static List<ProvincePolygon> _parseCompactPolygons(dynamic coordinates) {
    if (coordinates is! List) {
      return const [];
    }

    return coordinates
        .whereType<List>()
        .map(_polygonFromCoordinates)
        .toList(growable: false);
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

  static dynamic _valueAt(List<dynamic> row, int index) {
    if (index >= row.length) {
      return null;
    }

    return row[index];
  }

  static String _stringAt(List<dynamic> row, int index) {
    return _valueAt(row, index)?.toString() ?? '';
  }

  static String? _nullableStringAt(List<dynamic> row, int index) {
    final value = _valueAt(row, index);
    if (value == null) {
      return null;
    }

    final stringValue = value.toString();
    return stringValue.isEmpty ? null : stringValue;
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
