import 'geo_point.dart';

class ProvincePolygon {
  const ProvincePolygon({required this.rings});

  final List<List<GeoPoint>> rings;
}
