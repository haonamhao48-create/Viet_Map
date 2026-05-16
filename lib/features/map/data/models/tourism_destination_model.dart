class TourismDestinationModel {
  final int id;
  final String name;
  final String province;
  final String description;
  final List<String> keywords;

  const TourismDestinationModel({
    required this.id,
    required this.name,
    required this.province,
    required this.description,
    required this.keywords,
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
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
