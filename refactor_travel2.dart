import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/screens/travel_places_screen.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // We want to fix _TravelMapViewState, _communeAtPosition, _createProjection, and _DetailedProvincePainter.
  // Because the previous patch messed up, we will find the class _TravelMapViewState and replace it.

  final startIdx = content.indexOf('class _TravelMapViewState extends State<_TravelMapView> {');
  final endIdx = content.indexOf('class _TravelMapBackgroundPainter extends CustomPainter {');
  
  if (startIdx != -1 && endIdx != -1) {
    final oldState = content.substring(startIdx, endIdx);
    
    final newState = '''class _TravelMapViewState extends State<_TravelMapView> {
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
''';
    
    content = content.replaceRange(startIdx, endIdx, newState);
  }

  // Also replace _DetailedProvincePainter to ensure it matches
  final startPainterIdx = content.indexOf('class _DetailedProvincePainter extends CustomPainter {');
  final endPainterIdx = content.indexOf('class _TravelMapBackgroundPainter extends CustomPainter {');
  
  if (startPainterIdx != -1 && endPainterIdx != -1) {
    final newPainter = '''class _DetailedProvincePainter extends CustomPainter {
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
    content = content.replaceRange(startPainterIdx, endPainterIdx, newPainter);
  }

  file.writeAsStringSync(content);
  print('Done rewriting components');
}
