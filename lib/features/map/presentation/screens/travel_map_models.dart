// ignore_for_file: unused_element
part of 'travel_places_screen.dart';

/// Data class chứa kết quả load bản đồ (places + communes).
class _TravelMapData {
  const _TravelMapData({
    required this.places,
    required this.communes,
  });

  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;
}

/// Dữ liệu một xã/phường (từ GeoJSON).
class _CommuneArea {
  const _CommuneArea({
    required this.name,
    required this.type,
    required this.areaKm2,
    required this.population,
    required this.density,
    required this.capital,
    required this.predecessors,
    required this.polygons,
  });

  final String name;
  final String type;
  final double? areaKm2;
  final double? population;
  final double? density;
  final String capital;
  final String predecessors;

  /// MultiPolygon -> Polygon -> Ring -> Point
  final List<List<List<_MapPoint>>> polygons;
}

/// Một toạ độ địa lý (lon/lat).
class _MapPoint {
  const _MapPoint({
    required this.longitude,
    required this.latitude,
  });

  final double longitude;
  final double latitude;
}

/// Ánh xạ toạ độ địa lý → pixel trên canvas.
class _MapProjection {
  const _MapProjection({
    required this.minLon,
    required this.maxLat,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  final double minLon;
  final double maxLat;
  final double scale;
  final double offsetX;
  final double offsetY;

  Offset project(_MapPoint point) {
    final x = offsetX + ((point.longitude - minLon) * scale);
    final y = offsetY + ((maxLat - point.latitude) * scale);
    return Offset(x, y);
  }
}
