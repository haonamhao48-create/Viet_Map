import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/screens/travel_places_screen.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // 1. Add isCommuneMode to TravelPlacesScreen
  content = content.replaceFirst(
'''class TravelPlacesScreen extends StatefulWidget {
  const TravelPlacesScreen({
    super.key,
    required this.province,
  });

  final ProvinceModel province;''',
'''class TravelPlacesScreen extends StatefulWidget {
  const TravelPlacesScreen({
    super.key,
    required this.province,
    this.isCommuneMode = false,
  });

  final ProvinceModel province;
  final bool isCommuneMode;'''
  );

  content = content.replaceFirst(
'''        title: Text('Bản đồ phượt \${widget.province.displayName}'),''',
'''        title: Text(widget.isCommuneMode ? 'Bản đồ xã/phường \${widget.province.displayName}' : 'Bản đồ phượt \${widget.province.displayName}'),'''
  );

  content = content.replaceFirst(
'''          return _ProvinceTravelMap(
            province: widget.province,
            places: places,
            communes: communes,
          );''',
'''          return _ProvinceTravelMap(
            province: widget.province,
            places: places,
            communes: communes,
            isCommuneMode: widget.isCommuneMode,
          );'''
  );

  // 2. Optimize _loadCommunes
  content = content.replaceFirst(
'''  Future<List<_CommuneArea>> _loadCommunes() async {
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
      }''',
'''  Future<List<_CommuneArea>> _loadCommunes() async {
    final assetPath = 'assets/geo/provinces/\${widget.province.id}.geojson';
    
    try {
      final rawString = await rootBundle.loadString(assetPath);
      final fixedString = rawString.replaceAll(': NaN', ': null');
      
      final geoJson = jsonDecode(fixedString) as Map<String, dynamic>;
      final features = geoJson['features'] as List<dynamic>;

      final result = <_CommuneArea>[];

      for (final feature in features) {
        final item = feature as Map<String, dynamic>;
        final properties = item['properties'] as Map<String, dynamic>;
        final geometry = item['geometry'] as Map<String, dynamic>;
'''
  );

  content = content.replaceFirst(
'''      result.add(
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
  }''',
'''      result.add(
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
  } catch (e) {
    debugPrint('Lỗi tải file commune: \$e');
    return [];
  }
}'''
  );

  // 3. Add isCommuneMode to _ProvinceTravelMap
  content = content.replaceFirst(
'''class _ProvinceTravelMap extends StatefulWidget {
  const _ProvinceTravelMap({
    required this.province,
    required this.places,
    required this.communes,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;''',
'''class _ProvinceTravelMap extends StatefulWidget {
  const _ProvinceTravelMap({
    super.key,
    required this.province,
    required this.places,
    required this.communes,
    required this.isCommuneMode,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;
  final bool isCommuneMode;'''
  );

  // 4. Update _ProvinceTravelMapState build to handle side panel and pass isCommuneMode
  content = content.replaceFirst(
'''            children: [
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
            ],''',
'''            children: [
              SizedBox(
                width: 360,
                child: widget.isCommuneMode
                  ? _CommunesSidePanel(
                      province: widget.province,
                      communes: widget.communes,
                      selectedCommune: _selectedCommune,
                      onCommuneSelected: _selectCommune,
                    )
                  : _PlacesSidePanel(
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
                  places: widget.isCommuneMode ? [] : visiblePlaces,
                  communes: widget.communes,
                  isCommuneMode: widget.isCommuneMode,
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
            ],'''
  );

  content = content.replaceFirst(
'''          child: _TravelMapView(
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
          ),''',
'''          child: _TravelMapView(
            province: widget.province,
            places: widget.isCommuneMode ? [] : visiblePlaces,
            communes: widget.communes,
            isCommuneMode: widget.isCommuneMode,
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
          ),'''
  );

  // 5. Rewrite _TravelMapView and _DetailedProvincePainter to use Geometry Cache
  final startTravelMapView = content.indexOf('class _TravelMapView extends StatelessWidget {');
  final endTravelMapView = content.indexOf('class _TravelMapBackgroundPainter extends CustomPainter {');
  
  if (startTravelMapView != -1 && endTravelMapView != -1) {
    final cachedImpl = '''class _TravelMapView extends StatefulWidget {
  const _TravelMapView({
    super.key,
    required this.province,
    required this.places,
    required this.communes,
    required this.isCommuneMode,
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
  final bool isCommuneMode;
  final TourismDestinationModel? selectedPlace;
  final ValueChanged<TourismDestinationModel> onPlaceSelected;
  final List<TourismDestinationModel> routePlaces;
  final ValueChanged<TourismDestinationModel> onRouteToggle;
  final _CommuneArea? selectedCommune;
  final ValueChanged<_CommuneArea> onCommuneSelected;
  final bool showPlacesOnMap;
  final VoidCallback onTogglePlacesOnMap;

  @override
  State<_TravelMapView> createState() => _TravelMapViewState();
}

class _TravelMapViewState extends State<_TravelMapView> {
  Size? _lastSize;
  _MapProjection? _projection;
  Map<String, Path> _scaledCommunePaths = {};
  Path _scaledProvincePath = Path();
  Rect? _combinedBounds;
  
  double _minLon = 0;
  double _maxLon = 0;
  double _minLat = 0;
  double _maxLat = 0;
  double _lonRange = 1;
  double _latRange = 1;
  
  @override
  void initState() {
    super.initState();
    _calculateBounds();
  }
  
  @override
  void didUpdateWidget(_TravelMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.communes != oldWidget.communes) {
      _calculateBounds();
      _lastSize = null; // force rebuild paths
    }
  }
  
  void _calculateBounds() {
    if (widget.communes.isEmpty) return;
    
    _minLon = double.infinity;
    _maxLon = double.negativeInfinity;
    _minLat = double.infinity;
    _maxLat = double.negativeInfinity;
    
    for (final commune in widget.communes) {
      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          for (final point in ring) {
             _minLon = math.min(_minLon, point.longitude);
             _maxLon = math.max(_maxLon, point.longitude);
             _minLat = math.min(_minLat, point.latitude);
             _maxLat = math.max(_maxLat, point.latitude);
          }
        }
      }
    }
    _lonRange = math.max(_maxLon - _minLon, 0.01);
    _latRange = math.max(_maxLat - _minLat, 0.01);
  }
  
  void _buildPathsIfNeeded(Size size) {
    if (_lastSize == size) return;
    
    _scaledCommunePaths.clear();
    _scaledProvincePath = Path()..fillType = PathFillType.evenOdd;
    _combinedBounds = null;
    
    if (widget.communes.isEmpty || size.width == 0 || size.height == 0) return;
    
    final padding = math.min(size.width, size.height) * 0.14;
    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;

    final scale = math.min(
      usableWidth / _lonRange,
      usableHeight / _latRange,
    );

    final mapWidth = _lonRange * scale;
    final mapHeight = _latRange * scale;

    final offsetX = (size.width - mapWidth) / 2;
    final offsetY = (size.height - mapHeight) / 2;
    
    _projection = _MapProjection(
      minLon: _minLon,
      maxLat: _maxLat,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
    );
    
    for (final commune in widget.communes) {
      final path = Path()..fillType = PathFillType.evenOdd;
      
      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          if (ring.isEmpty) continue;
          
          final first = _projection!.project(ring.first);
          path.moveTo(first.dx, first.dy);
          _scaledProvincePath.moveTo(first.dx, first.dy);
          
          for (final point in ring.skip(1)) {
            final projected = _projection!.project(point);
            path.lineTo(projected.dx, projected.dy);
            _scaledProvincePath.lineTo(projected.dx, projected.dy);
          }
          
          path.close();
          _scaledProvincePath.close();
        }
      }
      _scaledCommunePaths[commune.name] = path;
      
      final bounds = path.getBounds();
      if (bounds != Rect.zero) {
        _combinedBounds = _combinedBounds == null ? bounds : _combinedBounds!.expandToInclude(bounds);
      }
    }
    
    _lastSize = size;
  }
  
  _CommuneArea? _communeAtPosition(Offset position) {
    if (_lastSize == null) return null;
    
    for (final commune in widget.communes.reversed) {
      final path = _scaledCommunePaths[commune.name];
      if (path != null && path.contains(position)) {
        return commune;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _buildPathsIfNeeded(size);
        
        return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: widget.isCommuneMode ? (details) {
              final commune = _communeAtPosition(details.localPosition);
              if (commune != null) {
                widget.onCommuneSelected(commune);
              }
            } : null,
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
                  province: widget.province,
                  communes: widget.communes,
                  isCommuneMode: widget.isCommuneMode,
                  selectedCommuneName: widget.selectedCommune?.name,
                  scaledCommunePaths: _scaledCommunePaths,
                  scaledProvincePath: _scaledProvincePath,
                  combinedBounds: _combinedBounds,
                ),
              ),
            ),

            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: widget.onTogglePlacesOnMap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.showPlacesOnMap
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.showPlacesOnMap ? 'Ẩn địa điểm' : 'Hiện địa điểm',
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

            if (widget.showPlacesOnMap)
              ...List.generate(widget.places.length, (index) {
                final place = widget.places[index];

                final isSelected = widget.selectedPlace?.name == place.name;
                final isInRoute = widget.routePlaces.any((item) => item.name == place.name);

                Offset point;

                final hasValidLatLng =
                    place.latitude != 0 &&
                        place.longitude != 0;

                if (hasValidLatLng && _projection != null) {
                  point = _projection!.project(
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
                      widget.onPlaceSelected(place);
                    },
                    onRouteToggle: () {
                      widget.onRouteToggle(place);
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
}

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
    
    // Use Golden Angle algorithm for distinct hues
    final hue = (hash * 137.5) % 360.0;
    
    // We keep saturation and value relatively constant to match the app theme
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

  @override
  bool shouldRepaint(covariant _DetailedProvincePainter oldDelegate) {
    return oldDelegate.province != province ||
        oldDelegate.communes != communes ||
        oldDelegate.isCommuneMode != isCommuneMode ||
        oldDelegate.selectedCommuneName != selectedCommuneName ||
        oldDelegate.scaledCommunePaths != scaledCommunePaths;
  }
}
''';
    content = content.replaceRange(startTravelMapView, endTravelMapView, cachedImpl);
  }

  // Add _CommunesSidePanel
  content += '''
class _CommunesSidePanel extends StatelessWidget {
  const _CommunesSidePanel({
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
                    province.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\${communes.length} đơn vị hành chính',
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
                  final commune = communes[index];
                  final isSelected = selectedCommune?.name == commune.name;

                  return _CommuneListTile(
                    index: index + 1,
                    commune: commune,
                    isSelected: isSelected,
                    onTap: () => onCommuneSelected(commune),
                  );
                },
                childCount: communes.length,
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
                    '\$index',
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
''';

  file.writeAsStringSync(content);
}
