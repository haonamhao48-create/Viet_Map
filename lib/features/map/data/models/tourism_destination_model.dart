import '../../../../core/utils/text_normalizer.dart';

class TourismDestinationModel {
  final int id;
  final String name;
  final String province;
  final String description;
  final List<String> keywords;
  final double latitude;
  final double longitude;

  TourismDestinationModel({
    required this.id,
    required this.name,
    required this.province,
    required this.description,
    required this.keywords,
    this.latitude = 0,
    this.longitude = 0,
  });

  factory TourismDestinationModel.fromCompactJsonRow(List<dynamic> row) {
    return TourismDestinationModel(
      id: _toInt(_valueAt(row, 0)),
      name: _valueAt(row, 1)?.toString() ?? '',
      province: _valueAt(row, 2)?.toString() ?? '',
      description: _valueAt(row, 3)?.toString() ?? '',
      keywords: (_valueAt(row, 4) as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      latitude: _toDouble(_valueAt(row, 5)),
      longitude: _toDouble(_valueAt(row, 6)),
    );
  }

  late final String normalizedProvinceKey =
      TextNormalizer.normalizeProvinceKey(province);

  static dynamic _valueAt(List<dynamic> row, int index) {
    if (index >= row.length) {
      return null;
    }

    return row[index];
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
