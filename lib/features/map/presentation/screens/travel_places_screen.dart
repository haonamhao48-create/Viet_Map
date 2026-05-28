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
    return Scaffold(
      backgroundColor: const Color(0xFFEFF9F8),
      appBar: AppBar(
        title: Text(widget.isCommuneMode ? 'Bản đồ xã/phường ${widget.province.displayName}' : 'Bản đồ phượt ${widget.province.displayName}'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<_TravelMapData>(
        future: _mapDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
            );
          }

          final mapData = snapshot.data;
          final places = mapData?.places ?? [];
          final communes = mapData?.communes ?? [];

          if (places.isEmpty) {
            return Center(
              child: Text(
                'Chưa có địa điểm phượt cho ${widget.province.displayName}',
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
      ),
    );
  }
}

class _PlacesSidePanel extends StatelessWidget {
  const _PlacesSidePanel({
    required this.province,
    required this.places,
    required this.selectedPlace,
    required this.routePlaces,
    required this.onPlaceSelected,
    required this.onRouteToggle,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final TourismDestinationModel? selectedPlace;
  final ValueChanged<TourismDestinationModel> onPlaceSelected;
  final List<TourismDestinationModel> routePlaces;
  final ValueChanged<TourismDestinationModel> onRouteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Địa điểm phượt',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    province.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${places.length} địa điểm nổi bật',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final place = places[index];
                  final isSelected = selectedPlace?.name == place.name;

                  final isInRoute = routePlaces.any((item) => item.name == place.name);

                  return _PlaceListTile(
                    index: index + 1,
                    place: place,
                    isSelected: isSelected,
                    isInRoute: isInRoute,
                    onTap: () {
                      onPlaceSelected(place);
                    },
                    onRouteToggle: () {
                      onRouteToggle(place);
                    },
                  );
                },
                childCount: places.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceListTile extends StatelessWidget {
  const _PlaceListTile({
    required this.index,
    required this.place,
    required this.isSelected,
    required this.isInRoute,
    required this.onTap,
    required this.onRouteToggle,
  });

  final int index;
  final TourismDestinationModel place;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isInRoute;
  final VoidCallback onRouteToggle;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? Colors.teal : Colors.transparent;
    final backgroundColor = isSelected
        ? Colors.teal.withValues(alpha: 0.10)
        : const Color(0xFFF5FAFA);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.teal,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (place.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          place.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (place.keywords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: place.keywords.take(3).map((keyword) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                keyword,
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: isInRoute ? 'Bỏ khỏi lộ trình' : 'Thêm vào lộ trình',
                  onPressed: onRouteToggle,
                  icon: Icon(
                    isInRoute ? Icons.remove_road_rounded : Icons.add_road_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPlaceDetailPanel extends StatelessWidget {
  const _SelectedPlaceDetailPanel({
    required this.place,
    required this.isInRoute,
    required this.routePlaces,
    required this.onRouteToggle,
    required this.onRemoveRoutePlace,
    required this.onClearRoute,
  });

  final TourismDestinationModel? place;
  final bool isInRoute;
  final List<TourismDestinationModel> routePlaces;
  final VoidCallback? onRouteToggle;
  final ValueChanged<TourismDestinationModel> onRemoveRoutePlace;
  final VoidCallback onClearRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: place == null
                  ? Text(
                'Chọn một địa điểm trên bản đồ hoặc trong danh sách để xem chi tiết.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlaceDetail(place: place!),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRouteToggle,
                      icon: Icon(
                        isInRoute
                            ? Icons.remove_road_rounded
                            : Icons.add_road_rounded,
                      ),
                      label: Text(
                        isInRoute
                            ? 'Bỏ khỏi lộ trình'
                            : 'Thêm vào lộ trình',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lộ trình phượt',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (routePlaces.isNotEmpty)
                    TextButton(
                      onPressed: onClearRoute,
                      child: const Text('Xóa tất cả'),
                    ),
                ],
              ),
            ),
          ),
          if (routePlaces.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FAFA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Chưa có địa điểm nào trong lộ trình. Hãy thêm vài điểm muốn ghé.',
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final routePlace = routePlaces[index];

                    return _RoutePlaceTile(
                      index: index + 1,
                      place: routePlace,
                      onRemove: () {
                        onRemoveRoutePlace(routePlace);
                      },
                    );
                  },
                  childCount: routePlaces.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutePlaceTile extends StatelessWidget {
  const _RoutePlaceTile({
    required this.index,
    required this.place,
    required this.onRemove,
  });

  final int index;
  final TourismDestinationModel place;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.orange,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              place.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Xóa khỏi lộ trình',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

const List<Offset> _bubblePositions = [
  Offset(0.07, 0.16),
  Offset(0.55, 0.12),
  Offset(0.12, 0.55),
  Offset(0.60, 0.50),
  Offset(0.36, 0.78),
];

class _DetailedProvincePainter extends CustomPainter {
  const _DetailedProvincePainter({
    required this.province,
    required this.communes,
    required this.isCommuneMode,
    required this.selectedCommuneName,
    required this.scaledCommunePaths,
    required this.scaledProvincePath,
    required this.combinedBounds,
  });

  final ProvinceModel province;
  final List<_CommuneArea> communes;
  final bool isCommuneMode;
  final String? selectedCommuneName;
  final Map<String, Path> scaledCommunePaths;
  final Path scaledProvincePath;
  final Rect? combinedBounds;
  
  Color _colorForCommune(String communeName, Color provinceColor) {
    final hash = communeName.hashCode;
    final hue = (hash * 137.5) % 360.0;
    return HSVColor.fromAHSV(1.0, hue, 0.45, 0.95).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (communes.isEmpty || scaledCommunePaths.isEmpty) {
      return;
    }

    final provinceColor = _colorForRegion(province.macroRegion);
    
    if (isCommuneMode) {
      for (final commune in communes) {
        final path = scaledCommunePaths[commune.name];
        if (path == null) continue;
        
        final isSelectedCommune = commune.name == selectedCommuneName;
        final communeColor = _colorForCommune(commune.name, provinceColor);
        
        final fillPaint = Paint()
          ..color = isSelectedCommune
              ? Colors.black.withValues(alpha: 0.70)
              : communeColor.withValues(alpha: 0.65)
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = isSelectedCommune ? Colors.black : Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelectedCommune ? 3 : 1.2;

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
      }
    } else {
      final fillPaint = Paint()
        ..color = provinceColor.withValues(alpha: 0.52)
        ..style = PaintingStyle.fill;
      canvas.drawPath(scaledProvincePath, fillPaint);
    }

    final outerBorderPaint = Paint()
      ..color = provinceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawPath(scaledProvincePath, outerBorderPaint);

    if (combinedBounds == null) return;

    if (!isCommuneMode) {
      _drawProvinceLabel(
        canvas,
        combinedBounds!.center,
        province.displayName,
        provinceColor,
      );
    }
  }

  void _drawProvinceLabel(
      Canvas canvas,
      Offset center,
      String text,
      Color color,
      ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 260);

    final padding = const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 10,
    );

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 20),
        width: textPainter.width + padding.horizontal,
        height: textPainter.height + padding.vertical,
      ),
      const Radius.circular(999),
    );

    final paint = Paint()..color = color.withValues(alpha: 0.95);

    canvas.drawRRect(rect, paint);

    textPainter.paint(
      canvas,
      Offset(
        rect.left + padding.left,
        rect.top + padding.top / 2,
      ),
    );
  }

  void _drawCommuneLabel(
      Canvas canvas,
      Offset center,
      String text,
      ) {
    final cleanText = text
        .replaceAll('Phường ', '')
        .replaceAll('Xã ', '')
        .replaceAll('Thị trấn ', '')
        .trim();

    if (cleanText.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: cleanText,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 90);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      ),
      const Radius.circular(6),
    );

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9);

    canvas.drawRRect(rect, backgroundPaint);

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  Color _colorForRegion(String region) {
    switch (region) {
      case 'northern_midlands':
        return const Color(0xFF4C8BF5);
      case 'red_river_delta':
        return const Color(0xFF11A579);
      case 'central_coast':
        return const Color(0xFFF39C35);
      case 'central_highlands':
        return const Color(0xFF9B6D3F);
      case 'southeast':
        return const Color(0xFFE14ECA);
      case 'mekong_delta':
        return const Color(0xFF0D9488);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  bool shouldRepaint(covariant _DetailedProvincePainter oldDelegate) {
    return oldDelegate.province != province ||
        oldDelegate.communes != communes ||
        oldDelegate.isCommuneMode != isCommuneMode ||
        oldDelegate.selectedCommuneName != selectedCommuneName ||
        oldDelegate.scaledCommunePaths != scaledCommunePaths;
  }
}

class _PlaceBubble extends StatelessWidget {
  const _PlaceBubble({
    required this.index,
    required this.place,
    required this.isSelected,
    required this.onTap,
    required this.isInRoute,
    required this.onRouteToggle,
  });

  final int index;
  final TourismDestinationModel place;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isInRoute;
  final VoidCallback onRouteToggle;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: place.description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.teal.withValues(alpha: 0.55),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isSelected ? Colors.white : Colors.teal,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: isSelected ? Colors.teal : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    place.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceDetail extends StatelessWidget {
  const _PlaceDetail({
    required this.place,
  });

  final TourismDestinationModel place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.place_rounded,
          color: Colors.teal,
          size: 36,
        ),
        const SizedBox(height: 12),
        Text(
          place.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          place.province,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.teal,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Mô tả',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          place.description.isEmpty
              ? 'Chưa có mô tả cho địa điểm này.'
              : place.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.45,
          ),
        ),
        if (place.keywords.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Từ khóa',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: place.keywords.map((keyword) {
              return Chip(
                label: Text(keyword),
                backgroundColor: Colors.teal.withValues(alpha: 0.10),
                labelStyle: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _CommuneDetail extends StatelessWidget {
  const _CommuneDetail({
    required this.commune,
  });

  final _CommuneArea commune;

  String _formatNumber(num? value) {
    if (value == null) return '—';

    final text = value.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            commune.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            commune.type.isEmpty ? 'Khu vực hành chính' : commune.type,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.teal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CommuneInfoChip(
                label: 'Diện tích',
                value: commune.areaKm2 == null
                    ? '—'
                    : '${commune.areaKm2!.toStringAsFixed(2)} km²',
              ),
              _CommuneInfoChip(
                label: 'Dân số',
                value: commune.population == null ? '—' : '${_formatNumber(commune.population)} người',
              ),
              _CommuneInfoChip(
                label: 'Mật độ',
                value: commune.density == null ? '—' : '${_formatNumber(commune.density)} người/km²',
              ),
            ],
          ),
          if (commune.capital.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Trụ sở / trung tâm',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(commune.capital),
          ],
          if (commune.predecessors.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Tiền thân',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              commune.predecessors,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommuneInfoChip extends StatelessWidget {
  const _CommuneInfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.teal.withValues(alpha: 0.10),
      labelStyle: const TextStyle(
        color: Colors.teal,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TravelMapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFEAF6FF),
          Color(0xFFF8FCFC),
          Color(0xFFDDF3F1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.08)
      ..strokeWidth = 1;

    const gridGap = 120.0;

    for (double x = 0; x <= size.width; x += gridGap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y <= size.height; y += gridGap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CommunesSidePanel extends StatefulWidget {
  const _CommunesSidePanel({
    super.key,
    required this.province,
    required this.communes,
    required this.selectedCommune,
    required this.onCommuneSelected,
  });

  final ProvinceModel province;
  final List<_CommuneArea> communes;
  final _CommuneArea? selectedCommune;
  final ValueChanged<_CommuneArea> onCommuneSelected;

  @override
  State<_CommunesSidePanel> createState() => _CommunesSidePanelState();
}

class _CommunesSidePanelState extends State<_CommunesSidePanel> {
  // Track selected name locally to avoid rebuilding the entire list
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.selectedCommune?.name;
  }

  @override
  void didUpdateWidget(_CommunesSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCommune?.name != _selectedName) {
      _selectedName = widget.selectedCommune?.name;
    }
  }

  void _handleTap(_CommuneArea commune) {
    setState(() {
      _selectedName = commune.name;
    });
    widget.onCommuneSelected(commune);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết Xã/Phường',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.province.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.communes.length} đơn vị hành chính',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final commune = widget.communes[index];
                  final isSelected = _selectedName == commune.name;
                  return RepaintBoundary(
                    child: _CommuneListTile(
                      key: ValueKey(commune.name),
                      index: index + 1,
                      commune: commune,
                      isSelected: isSelected,
                      onTap: () => _handleTap(commune),
                    ),
                  );
                },
                childCount: widget.communes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommuneListTile extends StatelessWidget {
  const _CommuneListTile({
    super.key,
    required this.index,
    required this.commune,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final _CommuneArea commune;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? Colors.teal : Colors.transparent;
    final backgroundColor = isSelected
        ? Colors.teal.withValues(alpha: 0.10)
        : const Color(0xFFF5FAFA);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected ? Colors.teal : Colors.grey.shade400,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    commune.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.teal.shade900 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class _CommuneLabel {
//   const _CommuneLabel({
//     required this.name,
//     required this.center,
//   });
//
//   final String name;
//   final Offset center;
// }