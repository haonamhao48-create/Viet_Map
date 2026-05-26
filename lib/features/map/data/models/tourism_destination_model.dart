class TourismDestinationModel {
  final int id;
  final String name;
  final String province;
  final String description;
  final List<String> keywords;
  final double latitude;
  final double longitude;

  const TourismDestinationModel({
    required this.id,
    required this.name,
    required this.province,
    required this.description,
    required this.keywords,
    this.latitude = 0,
    this.longitude = 0,
  });

  factory TourismDestinationModel.fromJson(Map<String, dynamic> json) {
    return TourismDestinationModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      keywords: (json['keywords'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
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