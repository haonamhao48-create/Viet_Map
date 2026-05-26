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

class _ProvinceTravelMap extends StatefulWidget {
  const _ProvinceTravelMap({
    required this.province,
    required this.places,
    required this.communes,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;

  @override
  State<_ProvinceTravelMap> createState() => _ProvinceTravelMapState();
}

class _ProvinceTravelMapState extends State<_ProvinceTravelMap> {
  TourismDestinationModel? _selectedPlace;
  final List<TourismDestinationModel> _routePlaces = [];
  _CommuneArea? _selectedCommune;
  bool _showPlacesOnMap = true;

  @override
  void initState() {
    super.initState();
    _selectedPlace = widget.places.isEmpty ? null : widget.places.first;
  }

  void _selectPlace(TourismDestinationModel place) {
    setState(() {
      _selectedPlace = place;
    });
  }

  void _selectCommune(_CommuneArea commune) {
    setState(() {
      _selectedCommune = commune;
    });
  }

  void _toggleRoutePlace(TourismDestinationModel place) {
    setState(() {
      final existingIndex = _routePlaces.indexWhere(
            (item) => item.name == place.name,
      );

      if (existingIndex >= 0) {
        _routePlaces.removeAt(existingIndex);
      } else {
        _routePlaces.add(place);
      }

      _selectedPlace = place;
    });
  }

  void _removeRoutePlace(TourismDestinationModel place) {
    setState(() {
      _routePlaces.removeWhere((item) => item.name == place.name);
    });
  }

  void _clearRoute() {
    setState(() {
      _routePlaces.clear();
    });
  }

  bool _isInRoute(TourismDestinationModel place) {
    return _routePlaces.any((item) => item.name == place.name);
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlaces = widget.places.take(5).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;

        if (isWide) {
          return Row(
            children: [
              SizedBox(
                width: 360,
                child: _PlacesSidePanel(
                  province: widget.province,
                  places: visiblePlaces,
                  selectedPlace: _selectedPlace,
                  routePlaces: _routePlaces,
                  onPlaceSelected: _selectPlace,
                  onRouteToggle: _toggleRoutePlace,
                ),
              ),
              Expanded(
                child: _TravelMapView(
                  province: widget.province,
                  places: visiblePlaces,
                  communes: widget.communes,
                  selectedPlace: _selectedPlace,
                  selectedCommune: _selectedCommune,
                  routePlaces: _routePlaces,
                  showPlacesOnMap: _showPlacesOnMap,
                  onPlaceSelected: _selectPlace,
                  onRouteToggle: _toggleRoutePlace,
                  onCommuneSelected: _selectCommune,
                  onTogglePlacesOnMap: () {
                    setState(() {
                      _showPlacesOnMap = !_showPlacesOnMap;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 360,
                child: _SelectedPlaceDetailPanel(
                  place: _selectedPlace,
                  isInRoute: _selectedPlace == null
                      ? false
                      : _isInRoute(_selectedPlace!),
                  routePlaces: _routePlaces,
                  onRouteToggle: _selectedPlace == null
                      ? null
                      : () => _toggleRoutePlace(_selectedPlace!),
                  onRemoveRoutePlace: _removeRoutePlace,
                  onClearRoute: _clearRoute,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: _TravelMapView(
                province: widget.province,
                places: visiblePlaces,
                communes: widget.communes,
                selectedPlace: _selectedPlace,
                selectedCommune: _selectedCommune,
                routePlaces: _routePlaces,
                showPlacesOnMap: _showPlacesOnMap,
                onPlaceSelected: _selectPlace,
                onRouteToggle: _toggleRoutePlace,
                onCommuneSelected: _selectCommune,
                onTogglePlacesOnMap: () {
                  setState(() {
                    _showPlacesOnMap = !_showPlacesOnMap;
                  });
                },
              ),
            ),
            SizedBox(
              height: 260,
              child: _PlacesSidePanel(
                province: widget.province,
                places: visiblePlaces,
                selectedPlace: _selectedPlace,
                routePlaces: _routePlaces,
                onPlaceSelected: _selectPlace,
                onRouteToggle: _toggleRoutePlace,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TravelMapView extends StatelessWidget {
  const _TravelMapView({
    required this.province,
    required this.places,
    required this.communes,
    required this.selectedPlace,
    required this.selectedCommune,
    required this.routePlaces,
    required this.onPlaceSelected,
    required this.onRouteToggle,
    required this.onCommuneSelected,
    required this.showPlacesOnMap,
    required this.onTogglePlacesOnMap,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;
  final TourismDestinationModel? selectedPlace;
  final ValueChanged<TourismDestinationModel> onPlaceSelected;
  final List<TourismDestinationModel> routePlaces;
  final ValueChanged<TourismDestinationModel> onRouteToggle;
  final _CommuneArea? selectedCommune;
  final ValueChanged<_CommuneArea> onCommuneSelected;
  final bool showPlacesOnMap;
  final VoidCallback onTogglePlacesOnMap;

  _CommuneArea? _communeAtPosition({
    required Offset position,
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

    if (allPoints.isEmpty) return null;

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

    for (final commune in communes.reversed) {
      for (final polygon in commune.polygons) {
        final path = Path()..fillType = PathFillType.evenOdd;

        for (final ring in polygon) {
          if (ring.length < 3) continue;

          final first = project(ring.first);
          path.moveTo(first.dx, first.dy);

          for (final point in ring.skip(1)) {
            final projected = project(point);
            path.lineTo(projected.dx, projected.dy);
          }

          path.close();
        }

        if (path.contains(position)) {
          return commune;
        }
      }
    }

    return null;
  }

  _MapProjection? _createProjection({
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

    if (allPoints.isEmpty) return null;

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

    return _MapProjection(
      minLon: minLon,
      maxLat: maxLat,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              final commune = _communeAtPosition(
                position: details.localPosition,
                constraints: constraints,
                communes: communes,
              );

              if (commune != null) {
                onCommuneSelected(commune);

                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (_) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: _CommuneDetail(commune: commune),
                    );
                  },
                );
              }
            },
        child: Stack(
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
                  selectedCommuneName: selectedCommune?.name,
                ),
              ),
            ),
            // ..._buildCommuneLabelWidgets(
            //   constraints: constraints,
            //   communes: communes,
            // ),


            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onTogglePlacesOnMap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          showPlacesOnMap
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          showPlacesOnMap ? 'Ẩn địa điểm' : 'Hiện địa điểm',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (showPlacesOnMap)
              ...List.generate(places.length, (index) {
                final place = places[index];

                final isSelected = selectedPlace?.name == place.name;
                final isInRoute = routePlaces.any((item) => item.name == place.name);

                Offset point;

                final hasValidLatLng =
                    place.latitude != 0 &&
                        place.longitude != 0;

                final projection = _createProjection(
                  constraints: constraints,
                  communes: communes,
                );

                if (hasValidLatLng && projection != null) {
                  point = projection.project(
                    _MapPoint(
                      longitude: place.longitude,
                      latitude: place.latitude,
                    ),
                  );
                } else {
                  final fallbackPosition =
                  _bubblePositions[index % _bubblePositions.length];

                  point = Offset(
                    constraints.maxWidth * fallbackPosition.dx,
                    constraints.maxHeight * fallbackPosition.dy,
                  );
                }

                return Positioned(
                  left: point.dx - 18,
                  top: point.dy - 18,
                  child: _PlaceBubble(
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
                  ),
                );
              }),
          ],
        ),
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

    return labels;
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
    required this.selectedCommuneName,
  });

  final ProvinceModel province;
  final List<_CommuneArea> communes;
  final String? selectedCommuneName;

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

    // final communeLabels = <_CommuneLabel>[];

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

        final isSelectedCommune = commune.name == selectedCommuneName;

        final selectedFillPaint = Paint()
          ..color = isSelectedCommune
              ? Colors.orange.withValues(alpha: 0.70)
              : provinceColor.withValues(alpha: 0.52)
          ..style = PaintingStyle.fill;

        final selectedBorderPaint = Paint()
          ..color = isSelectedCommune ? Colors.orange : Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelectedCommune ? 3 : 1.2;

        canvas.drawPath(path, selectedFillPaint);
        canvas.drawPath(path, selectedBorderPaint);

        // final communeBounds = path.getBounds();
        //
        // if (communeBounds.width > 35 && communeBounds.height > 18) {
        //   communeLabels.add(
        //     _CommuneLabel(
        //       name: commune.name,
        //       center: communeBounds.center,
        //     ),
        //   );
        // }
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

    // debugPrint('Commune labels: ${communeLabels.length}');
    //
    // for (final label in communeLabels) {
    //   _drawCommuneLabel(
    //     canvas,
    //     label.center,
    //     label.name,
    //   );
    // }
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
        oldDelegate.communes != communes ||
        oldDelegate.selectedCommuneName != selectedCommuneName;
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
                value: _formatNumber(commune.population),
              ),
              _CommuneInfoChip(
                label: 'Mật độ',
                value: _formatNumber(commune.density),
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

class _MapPoint {
  const _MapPoint({
    required this.longitude,
    required this.latitude,
  });

  final double longitude;
  final double latitude;
}

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

// class _CommuneLabel {
//   const _CommuneLabel({
//     required this.name,
//     required this.center,
//   });
//
//   final String name;
//   final Offset center;
// }