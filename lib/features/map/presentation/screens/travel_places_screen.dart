import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/datasources/tourism_local_datasource.dart';
import '../../data/models/province_model.dart';
import '../../data/models/tourism_destination_model.dart';

class TravelPlacesScreen extends StatefulWidget {
  const TravelPlacesScreen({
    super.key,
    required this.province,
  });

  final ProvinceModel province;

  @override
  State<TravelPlacesScreen> createState() => _TravelPlacesScreenState();
}

class _TravelPlacesScreenState extends State<TravelPlacesScreen> {
  late final Future<_TravelMapData> _mapDataFuture;

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
    final rawString = await rootBundle.loadString(
      'assets/geo/communes.geojson',
    );

    final fixedString = rawString.replaceAll(': NaN', ': null');

    final geoJson = jsonDecode(fixedString) as Map<String, dynamic>;
    final features = geoJson['features'] as List<dynamic>;

    final selectedProvince = _normalizeProvinceName(
      widget.province.displayName,
    );

    final result = <_CommuneArea>[];

    for (final feature in features) {
      final item = feature as Map<String, dynamic>;
      final properties = item['properties'] as Map<String, dynamic>;
      final geometry = item['geometry'] as Map<String, dynamic>;

      final parentName = properties['parent_ten']?.toString() ?? '';
      final normalizedParentName = _normalizeProvinceName(parentName);

      if (normalizedParentName != selectedProvince) {
        continue;
      }

      final communeName = properties['name']?.toString() ?? '';
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
          polygons: polygons,
        ),
      );
    }

    return result;
  }

  List<List<_MapPoint>> _parsePolygon(List<dynamic> polygon) {
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

  String _normalizeProvinceName(String value) {
    return value
        .toLowerCase()
        .replaceAll('tỉnh ', '')
        .replaceAll('thành phố ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF9F8),
      appBar: AppBar(
        title: Text('Bản đồ phượt ${widget.province.displayName}'),
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
          );
        },
      ),
    );
  }
}

class _ProvinceTravelMap extends StatelessWidget {
  const _ProvinceTravelMap({
    required this.province,
    required this.places,
    required this.communes,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;

  @override
  Widget build(BuildContext context) {
    final visiblePlaces = places.take(5).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TravelMapBackgroundPainter(),
              ),
            ),

            Positioned.fill(
              child: CustomPaint(
                painter: _DetailedProvincePainter(
                  province: province,
                  communes: communes,
                ),
              ),
            ),
            ..._buildCommuneLabelWidgets(
              constraints: constraints,
              communes: communes,
            ),

            ...List.generate(visiblePlaces.length, (index) {
              final place = visiblePlaces[index];
              final position = _bubblePositions[index];

              return Positioned(
                left: constraints.maxWidth * position.dx,
                top: constraints.maxHeight * position.dy,
                child: _PlaceBubble(
                  index: index + 1,
                  place: place,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  List<Widget> _buildCommuneLabelWidgets({
    required BoxConstraints constraints,
    required List<_CommuneArea> communes,
  }) {
    final allPoints = <_MapPoint>[];

    for (final commune in communes) {
      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          allPoints.addAll(ring);
        }
      }
    }

    if (allPoints.isEmpty) return [];

    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;

    for (final point in allPoints) {
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
    }

    final lonRange = math.max(maxLon - minLon, 0.01);
    final latRange = math.max(maxLat - minLat, 0.01);

    final size = Size(
      constraints.maxWidth,
      constraints.maxHeight,
    );

    final padding = math.min(size.width, size.height) * 0.14;
    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;

    final scale = math.min(
      usableWidth / lonRange,
      usableHeight / latRange,
    );

    final mapWidth = lonRange * scale;
    final mapHeight = latRange * scale;

    final offsetX = (size.width - mapWidth) / 2;
    final offsetY = (size.height - mapHeight) / 2;

    Offset project(_MapPoint point) {
      final x = offsetX + ((point.longitude - minLon) * scale);
      final y = offsetY + ((maxLat - point.latitude) * scale);
      return Offset(x, y);
    }

    final labels = <Widget>[];

    for (final commune in communes) {
      Rect? bounds;

      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          if (ring.length < 3) continue;

          final points = ring.map(project).toList();

          for (final point in points) {
            final rect = Rect.fromCenter(
              center: point,
              width: 1,
              height: 1,
            );

            bounds = bounds == null ? rect : bounds!.expandToInclude(rect);
          }
        }
      }

      if (bounds == null) continue;


      final cleanName = commune.name
          .replaceAll('Phường ', '')
          .replaceAll('Xã ', '')
          .replaceAll('Thị trấn ', '')
          .trim();

      if (cleanName.isEmpty) continue;

      labels.add(
        Positioned(
          left: bounds!.center.dx - 45,
          top: bounds!.center.dy - 12,
          child: IgnorePointer(
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Text(
                cleanName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      );
    }

    debugPrint('Widget commune labels: ${labels.length}');

    return labels;
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
  });

  final ProvinceModel province;
  final List<_CommuneArea> communes;

  @override
  void paint(Canvas canvas, Size size) {
    if (communes.isEmpty) {
      return;
    }

    final allPoints = <_MapPoint>[];

    for (final commune in communes) {
      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          allPoints.addAll(ring);
        }
      }
    }

    if (allPoints.isEmpty) return;

    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;

    for (final point in allPoints) {
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
    }

    final lonRange = math.max(maxLon - minLon, 0.01);
    final latRange = math.max(maxLat - minLat, 0.01);

    final padding = math.min(size.width, size.height) * 0.14;
    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;

    final scale = math.min(
      usableWidth / lonRange,
      usableHeight / latRange,
    );

    final mapWidth = lonRange * scale;
    final mapHeight = latRange * scale;

    final offsetX = (size.width - mapWidth) / 2;
    final offsetY = (size.height - mapHeight) / 2;

    Offset project(_MapPoint point) {
      final x = offsetX + ((point.longitude - minLon) * scale);
      final y = offsetY + ((maxLat - point.latitude) * scale);
      return Offset(x, y);
    }

    final provinceColor = _colorForRegion(province.macroRegion);

    final fillPaint = Paint()
      ..color = provinceColor.withValues(alpha: 0.52)
      ..style = PaintingStyle.fill;

    final communeBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final outerBorderPaint = Paint()
      ..color = provinceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    Rect? combinedBounds;
    final allCommunePath = Path()..fillType = PathFillType.evenOdd;

    final communeLabels = <_CommuneLabel>[];

    for (final commune in communes) {
      for (final polygon in commune.polygons) {
        final path = Path()..fillType = PathFillType.evenOdd;

        for (final ring in polygon) {
          if (ring.length < 3) continue;

          final first = project(ring.first);
          path.moveTo(first.dx, first.dy);
          allCommunePath.moveTo(first.dx, first.dy);

          for (final point in ring.skip(1)) {
            final projected = project(point);
            path.lineTo(projected.dx, projected.dy);
            allCommunePath.lineTo(projected.dx, projected.dy);
          }

          path.close();
          allCommunePath.close();
        }

        final bounds = path.getBounds();

        if (bounds == Rect.zero) continue;

        combinedBounds = combinedBounds == null
            ? bounds
            : combinedBounds!.expandToInclude(bounds);

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, communeBorderPaint);

        final communeBounds = path.getBounds();

        if (communeBounds.width > 35 && communeBounds.height > 18) {
          communeLabels.add(
            _CommuneLabel(
              name: commune.name,
              center: communeBounds.center,
            ),
          );
        }
      }
    }

    canvas.drawPath(allCommunePath, outerBorderPaint);

    if (combinedBounds == null) return;

    _drawProvinceLabel(
      canvas,
      combinedBounds!.center,
      province.displayName,
      provinceColor,
    );

    debugPrint('Commune labels: ${communeLabels.length}');

    for (final label in communeLabels) {
      _drawCommuneLabel(
        canvas,
        label.center,
        label.name,
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
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
        oldDelegate.communes != communes;
  }
}

class _PlaceBubble extends StatelessWidget {
  const _PlaceBubble({
    required this.index,
    required this.place,
  });

  final int index;
  final TourismDestinationModel place;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: place.description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (_) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: _PlaceDetail(place: place),
                );
              },
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.teal.withValues(alpha: 0.45),
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
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    place.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          place.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.4,
          ),
        ),
        if (place.keywords.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: place.keywords.map((keyword) {
              return Chip(label: Text(keyword));
            }).toList(),
          ),
        ],
      ],
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

class _TravelMapData {
  const _TravelMapData({
    required this.places,
    required this.communes,
  });

  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;
}

class _CommuneArea {
  const _CommuneArea({
    required this.name,
    required this.polygons,
  });

  final String name;

  /// MultiPolygon -> Polygon -> Ring -> Point
  final List<List<List<_MapPoint>>> polygons;
}

class _MapPoint {
  const _MapPoint({
    required this.longitude,
    required this.latitude,
  });

  final double longitude;
  final double latitude;
}

class _CommuneLabel {
  const _CommuneLabel({
    required this.name,
    required this.center,
  });

  final String name;
  final Offset center;
}