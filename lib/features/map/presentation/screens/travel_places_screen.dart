import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/datasources/tourism_local_datasource.dart';
import '../../data/models/province_model.dart';
import '../../data/models/tourism_destination_model.dart';

part 'travel_map_models.dart';
part 'travel_map_view.dart';
part 'travel_map_painter.dart';
part 'travel_place_widgets.dart';
part 'travel_commune_widgets.dart';

class TravelPlacesScreen extends StatefulWidget {
  const TravelPlacesScreen({
    super.key,
    required this.province,
    this.isCommuneMode = false,
  });

  final ProvinceModel province;
  final bool isCommuneMode;

  @override
  State<TravelPlacesScreen> createState() => _TravelPlacesScreenState();
}

class _TravelPlacesScreenState extends State<TravelPlacesScreen> {
  late final Future<_TravelMapData> _mapDataFuture;

  static final Map<String, List<_CommuneArea>> _parsedCommunesCache = {};

  @override
  void initState() {
    super.initState();
    _mapDataFuture = _loadMapData();
  }

  Future<List<TourismDestinationModel>> _loadPlaces() async {
    final allPlaces = await TourismLocalDataSource().loadDestinations();

    final selectedProvince = _normalizeProvinceName(widget.province.displayName);

    return allPlaces.where((place) {
      final placeProvince = _normalizeProvinceName(place.province);
      return placeProvince == selectedProvince;
    }).toList(growable: false);
  }

  Future<_TravelMapData> _loadMapData() async {
    final places = await _loadPlaces();
    final communes = await _loadCommunes();

    return _TravelMapData(
      places: places,
      communes: communes,
    );
  }

  Future<List<_CommuneArea>> _loadCommunes() async {
    final selectedProvince = _normalizeProvinceName(widget.province.displayName);
    
    if (_parsedCommunesCache.containsKey(selectedProvince)) {
      return _parsedCommunesCache[selectedProvince]!;
    }

    final assetPath = 'assets/geo/provinces/$selectedProvince.geojson';
    
    try {
      final rawString = await rootBundle.loadString(assetPath);
      final parsed = await compute(_parseCommunesIsolate, rawString);
      _parsedCommunesCache[selectedProvince] = parsed;
      return parsed;
    } catch (e) {
      debugPrint('Không tìm thấy dữ liệu xã/phường cho ${widget.province.displayName}: $e');
      return [];
    }
  }

  static List<_CommuneArea> _parseCommunesIsolate(String rawString) {
    final fixedString = rawString.replaceAll(': NaN', ': null');
    final geoJson = jsonDecode(fixedString) as Map<String, dynamic>;
    final features = geoJson['features'] as List<dynamic>;

    final result = <_CommuneArea>[];

    for (final feature in features) {
      final item = feature as Map<String, dynamic>;
      final properties = item['properties'] as Map<String, dynamic>;
      final geometry = item['geometry'] as Map<String, dynamic>;

      final communeName =
          properties['ten']?.toString() ??
              properties['name']?.toString() ??
              '';
      final geometryType = geometry['type']?.toString() ?? '';
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final polygons = <List<List<_MapPoint>>>[];

      if (geometryType == 'Polygon') {
        final polygonRings = _parsePolygon(coordinates);
        polygons.add(polygonRings);
      } else if (geometryType == 'MultiPolygon') {
        for (final polygon in coordinates) {
          final polygonRings = _parsePolygon(polygon as List<dynamic>);
          polygons.add(polygonRings);
        }
      }

      result.add(
        _CommuneArea(
          name: communeName,
          type: properties['type']?.toString() ?? '',
          areaKm2: (properties['area_km2'] as num?)?.toDouble(),
          population: (properties['population'] as num?)?.toDouble(),
          density: (properties['density'] as num?)?.toDouble(),
          capital: properties['capital']?.toString() ?? '',
          predecessors: properties['predecessors']?.toString() ?? '',
          polygons: polygons,
        ),
      );
    }
    return result;
  }

  static List<List<_MapPoint>> _parsePolygon(List<dynamic> polygon) {
    final polygonRings = <List<_MapPoint>>[];

    for (final ring in polygon) {
      final points = <_MapPoint>[];

      for (final coordinate in ring as List<dynamic>) {
        final pair = coordinate as List<dynamic>;

        points.add(
          _MapPoint(
            longitude: (pair[0] as num).toDouble(),
            latitude: (pair[1] as num).toDouble(),
          ),
        );
      }

      polygonRings.add(points);
    }

    return polygonRings;
  }

  static const Map<String, String> _provinceFileMap = {
    // Special names that don't normalize cleanly
    'thủ đô hà nội': 'thu-do-ha-noi',
    'hà nội': 'thu-do-ha-noi',
    'hồ chí minh': 'ho-chi-minh',
    'thành phố hồ chí minh': 'ho-chi-minh',
    'đà nẵng': 'da-nang',
    'thành phố đà nẵng': 'da-nang',
    'cần thơ': 'can-tho',
    'thành phố cần thơ': 'can-tho',
    'hải phòng': 'hai-phong',
    'thành phố hải phòng': 'hai-phong',
    'huế': 'hue',
    'tỉnh huế': 'hue',
    'thừa thiên huế': 'hue',
    'bắc ninh': 'bac-ninh',
    'bắc kạn': 'bac-ninh',
    'cà mau': 'ca-mau',
    'cao bằng': 'cao-bang',
    'đắk lắk': 'dak-lak',
    'điện biên': 'dien-bien',
    'đồng nai': 'dong-nai',
    'đồng tháp': 'dong-thap',
    'gia lai': 'gia-lai',
    'hà tĩnh': 'ha-tinh',
    'khánh hòa': 'khanh-hoa',
    'lai châu': 'lai-chau',
    'lâm đồng': 'lam-dong',
    'lạng sơn': 'lang-son',
    'lào cai': 'lao-cai',
    'nghệ an': 'nghe-an',
    'ninh bình': 'ninh-binh',
    'phú thọ': 'phu-tho',
    'quảng ngãi': 'quang-ngai',
    'quảng ninh': 'quang-ninh',
    'quảng trị': 'quang-tri',
    'sơn la': 'son-la',
    'tây ninh': 'tay-ninh',
    'thái nguyên': 'thai-nguyen',
    'thanh hóa': 'thanh-hoa',
    'tuyên quang': 'tuyen-quang',
    'vĩnh long': 'vinh-long',
    'an giang': 'an-giang',
    'hưng yên': 'hung-yen',
  };

  String _normalizeProvinceName(String value) {
    final lower = value.toLowerCase().trim();

    // Check exact mapping first
    if (_provinceFileMap.containsKey(lower)) {
      return _provinceFileMap[lower]!;
    }

    // Strip prefix and check again
    String stripped = lower
        .replaceAll('thành phố ', '')
        .replaceAll('tỉnh ', '')
        .replaceAll('thủ đô ', '')
        .trim();

    if (_provinceFileMap.containsKey(stripped)) {
      return _provinceFileMap[stripped]!;
    }

    // Fallback: remove accents and hyphenate
    const Map<String, String> accents = {
      'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'đ': 'd',
      'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    };
    String s = stripped;
    accents.forEach((key, v) {
      s = s.replaceAll(key, v);
    });
    return s.replaceAll(RegExp(r'\s+'), '-');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TravelMapData>(
      future: _mapDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF9F8),
            appBar: AppBar(
              title: Text(widget.isCommuneMode ? 'Bản đồ xã/phường ${widget.province.displayName}' : 'Bản đồ phượt ${widget.province.displayName}'),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF9F8),
            appBar: AppBar(
              title: Text(widget.isCommuneMode ? 'Bản đồ xã/phường ${widget.province.displayName}' : 'Bản đồ phượt ${widget.province.displayName}'),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
            ),
          );
        }

        final mapData = snapshot.data;
        final places = mapData?.places ?? [];
        final communes = mapData?.communes ?? [];

        if (places.isEmpty && !widget.isCommuneMode) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF9F8),
            appBar: AppBar(
              title: Text('Bản đồ phượt ${widget.province.displayName}'),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Text(
                'Chưa có địa điểm phượt cho ${widget.province.displayName}',
              ),
            ),
          );
        }

        return _ProvinceTravelMap(
          province: widget.province,
          places: places,
          communes: communes,
          isCommuneMode: widget.isCommuneMode,
        );
      },
    );
  }
}
