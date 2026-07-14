import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/high_school_model.dart';

class RouteInfo {
  final double distanceKm;
  final double durationMinutes;
  final String startName;
  final String endName;

  RouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
    required this.startName,
    required this.endName,
  });
}

class RouteData {
  final List<LatLng> points;
  final RouteInfo? info;

  RouteData({required this.points, this.info});
}

final startSchoolProvider = StateProvider<HighSchoolModel?>((ref) => null);
final endSchoolProvider = StateProvider<HighSchoolModel?>((ref) => null);

final routeDataProvider = FutureProvider<RouteData>((ref) async {
  final start = ref.watch(startSchoolProvider);
  final end = ref.watch(endSchoolProvider);

  if (start == null || end == null) {
    return RouteData(points: const []);
  }

  final url = 'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson';

  debugPrint('OSRM Route Query: $url');

  try {
    final client = HttpClient();
    // Set a timeout of 5 seconds
    client.connectionTimeout = const Duration(seconds: 5);
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('User-Agent', 'vn_map_app/1.0');
    
    final response = await request.close();
    if (response.statusCode != 200) {
      debugPrint('OSRM HTTP Error: ${response.statusCode}');
      return RouteData(points: const []);
    }

    final responseBody = await response.transform(utf8.decoder).join();
    final data = jsonDecode(responseBody) as Map<String, dynamic>;

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      debugPrint('OSRM Route not found');
      return RouteData(points: const []);
    }

    final route = routes[0] as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final legs = route['legs'] as List<dynamic>?;

    if (geometry == null || legs == null || legs.isEmpty) {
      return RouteData(points: const []);
    }

    final coordinates = geometry['coordinates'] as List<dynamic>?;
    if (coordinates == null) {
      return RouteData(points: const []);
    }

    final points = coordinates.map((coord) {
      final list = coord as List<dynamic>;
      // OSM coordinates are [lon, lat]
      return LatLng(list[1].toDouble(), list[0].toDouble());
    }).toList();

    final leg = legs[0] as Map<String, dynamic>;
    final distance = (leg['distance'] as num).toDouble(); // meters
    final duration = (leg['duration'] as num).toDouble(); // seconds

    final info = RouteInfo(
      distanceKm: distance / 1000.0,
      durationMinutes: duration / 60.0,
      startName: start.tenTruong,
      endName: end.tenTruong,
    );

    return RouteData(points: points, info: info);
  } catch (e) {
    debugPrint('Error fetching route: $e');
    return RouteData(points: const []);
  }
});

final routePointsProvider = FutureProvider<List<LatLng>>((ref) async {
  final data = await ref.watch(routeDataProvider.future);
  return data.points;
});

final routeInfoProvider = Provider<RouteInfo?>((ref) {
  final dataAsync = ref.watch(routeDataProvider);
  return dataAsync.valueOrNull?.info;
});
