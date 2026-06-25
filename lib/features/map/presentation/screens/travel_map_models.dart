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
    required this.ma,
    required this.parentMa,
    required this.name,
    required this.type,
    required this.areaKm2,
    required this.population,
    required this.density,
    required this.capital,
    required this.predecessors,
    required this.polygons,
  });

  final String ma;
  final String parentMa;
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

class _CommuneGeographicBounds {
  const _CommuneGeographicBounds({
    required this.minLon,
    required this.maxLon,
    required this.minLat,
    required this.maxLat,
  });

  final double minLon;
  final double maxLon;
  final double minLat;
  final double maxLat;

  bool containsCoordinate(
    double latitude,
    double longitude, {
    double marginDegrees = 0.08,
  }) {
    return longitude >= minLon - marginDegrees &&
        longitude <= maxLon + marginDegrees &&
        latitude >= minLat - marginDegrees &&
        latitude <= maxLat + marginDegrees;
  }
}

_CommuneGeographicBounds geographicBoundsFor(_CommuneArea commune) {
  var minLon = double.infinity;
  var maxLon = double.negativeInfinity;
  var minLat = double.infinity;
  var maxLat = double.negativeInfinity;

  for (final polygon in commune.polygons) {
    for (final ring in polygon) {
      for (final point in ring) {
        minLon = math.min(minLon, point.longitude);
        maxLon = math.max(maxLon, point.longitude);
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
      }
    }
  }

  return _CommuneGeographicBounds(
    minLon: minLon,
    maxLon: maxLon,
    minLat: minLat,
    maxLat: maxLat,
  );
}

_MapPoint communeCentroid(_CommuneArea commune) {
  var sumLon = 0.0;
  var sumLat = 0.0;
  var count = 0;

  for (final polygon in commune.polygons) {
    for (final ring in polygon) {
      for (final point in ring) {
        sumLon += point.longitude;
        sumLat += point.latitude;
        count++;
      }
    }
  }

  if (count == 0) {
    return const _MapPoint(longitude: 0, latitude: 0);
  }

  return _MapPoint(
    longitude: sumLon / count,
    latitude: sumLat / count,
  );
}

bool pointInCommune(
  _CommuneArea commune,
  double longitude,
  double latitude,
) {
  for (final polygon in commune.polygons) {
    if (polygon.isEmpty) continue;
    if (_pointInRing(longitude, latitude, polygon.first)) {
      return true;
    }
  }
  return false;
}

bool _pointInRing(
  double longitude,
  double latitude,
  List<_MapPoint> ring,
) {
  if (ring.length < 3) {
    return false;
  }

  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = ring[i].longitude;
    final yi = ring[i].latitude;
    final xj = ring[j].longitude;
    final yj = ring[j].latitude;
    final intersects = ((yi > latitude) != (yj > latitude)) &&
        (longitude <
            (xj - xi) * (latitude - yi) / (yj - yi + 1e-15) + xi);
    if (intersects) {
      inside = !inside;
    }
  }
  return inside;
}

/// Toạ độ hiển thị trên bản đồ: dùng GPS thật nếu nằm trong polygon xã,
/// ngược lại đặt gần trọng tâm xã để pin không bị lệch ra ngoài vùng nền.
_MapPoint schoolDisplayPoint(
  HighSchoolModel school,
  _CommuneArea commune,
  int index,
) {
  if (school.hasValidCoordinates &&
      pointInCommune(commune, school.longitude, school.latitude)) {
    return _MapPoint(
      longitude: school.longitude,
      latitude: school.latitude,
    );
  }

  final centroid = communeCentroid(commune);
  final ring = (index ~/ 6) + 1;
  final spread = 0.0025 * ring;
  final angle = index * 1.15;
  return _MapPoint(
    longitude: centroid.longitude + math.cos(angle) * spread,
    latitude: centroid.latitude + math.sin(angle) * spread,
  );
}
