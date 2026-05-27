import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/screens/travel_places_screen.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // Step 1: Replace _TravelMapView from StatelessWidget to StatefulWidget
  content = content.replaceFirst(
'''class _TravelMapView extends StatelessWidget {
  const _TravelMapView({
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
  final VoidCallback onTogglePlacesOnMap;''',
'''class _TravelMapView extends StatefulWidget {
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
    
    for (final commune in widget.communes) {
      final path = Path()..fillType = PathFillType.evenOdd;
      
      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          if (ring.isEmpty) continue;
          
          final firstPoint = ring.first;
          final firstX = (firstPoint.longitude - _minLon) / _lonRange * size.width;
          final firstY = size.height - (firstPoint.latitude - _minLat) / _latRange * size.height;
          
          path.moveTo(firstX, firstY);
          _scaledProvincePath.moveTo(firstX, firstY);
          
          for (final point in ring.skip(1)) {
            final x = (point.longitude - _minLon) / _lonRange * size.width;
            final y = size.height - (point.latitude - _minLat) / _latRange * size.height;
            path.lineTo(x, y);
            _scaledProvincePath.lineTo(x, y);
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
''');

  // Step 2: Replace _communeAtPosition logic in _TravelMapViewState
  content = content.replaceFirst(
'''  _CommuneArea? _communeAtPosition({
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

    Offset project(_MapPoint point) {
      final x = (point.longitude - minLon) / lonRange * size.width;
      final y = size.height - (point.latitude - minLat) / latRange * size.height;
      return Offset(x, y);
    }

    for (final commune in communes) {
      final path = Path()..fillType = PathFillType.evenOdd;

      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          if (ring.isEmpty) continue;

          final first = project(ring.first);
          path.moveTo(first.dx, first.dy);

          for (final point in ring.skip(1)) {
            final projected = project(point);
            path.lineTo(projected.dx, projected.dy);
          }

          path.close();
        }
      }

      if (path.contains(position)) {
        return commune;
      }
    }

    return null;
  }''',
'''  _CommuneArea? _communeAtPosition(Offset position) {
    if (_lastSize == null) return null;
    
    for (final commune in widget.communes) {
      final path = _scaledCommunePaths[commune.name];
      if (path != null && path.contains(position)) {
        return commune;
      }
    }
    return null;
  }''');

  // Step 3: Replace build method in _TravelMapViewState
  content = content.replaceFirst(
'''  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: isCommuneMode ? (details) {
              final commune = _communeAtPosition(
                position: details.localPosition,
                constraints: constraints,
                communes: communes,
              );

              if (commune != null) {
                onCommuneSelected(commune);
              }
            } : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DetailedProvincePainter(
                  province: province,
                  communes: communes,
                  isCommuneMode: isCommuneMode,
                  selectedCommuneName: selectedCommune?.name,
                ),
              ),
            ),
            if (showPlacesOnMap && !isCommuneMode)
              ...places.map((place) {
                return _PlaceMarker(
                  place: place,
                  constraints: constraints,
                  communes: communes,
                  isSelected: selectedPlace == place,
                  isInRoute: routePlaces.contains(place),
                  onTap: () => onPlaceSelected(place),
                );
              }),
          ],
        ),
        );
      },
    );
  }
}''',
'''  @override
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
            if (widget.showPlacesOnMap && !widget.isCommuneMode)
              ...widget.places.map((place) {
                return _PlaceMarker(
                  place: place,
                  constraints: constraints,
                  communes: widget.communes, // Pass it down, though _PlaceMarker might need optimization too!
                  isSelected: widget.selectedPlace == place,
                  isInRoute: widget.routePlaces.contains(place),
                  onTap: () => widget.onPlaceSelected(place),
                );
              }),
          ],
        ),
        );
      },
    );
  }
}''');

  // Step 4: Update _DetailedProvincePainter
  content = content.replaceFirst(
'''class _DetailedProvincePainter extends CustomPainter {
  const _DetailedProvincePainter({
    required this.province,
    required this.communes,
    required this.isCommuneMode,
    required this.selectedCommuneName,
  });

  final ProvinceModel province;
  final List<_CommuneArea> communes;
  final bool isCommuneMode;
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

    final bounds = _calculateBounds(allPoints);

    final lngRange = math.max(bounds.maxLng - bounds.minLng, 0.01);
    final latRange = math.max(bounds.maxLat - bounds.minLat, 0.01);

    Offset project(_MapPoint point) {
      final x = (point.longitude - bounds.minLng) / lngRange * size.width;
      final y = size.height -
          (point.latitude - bounds.minLat) / latRange * size.height;
      return Offset(x, y);
    }

    final provinceColor = _colorForRegion(province.macroRegion);
    final outerBorderPaint = Paint()
      ..color = provinceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final allCommunePath = Path()..fillType = PathFillType.evenOdd;
    Rect? combinedBounds;

    // final communeLabels = <_CommuneLabel>[];

    for (final commune in communes) {
      final path = Path()..fillType = PathFillType.evenOdd;

      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          if (ring.isEmpty) continue;

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

        if (isCommuneMode) {
          final communeColor = _colorForCommune(commune.name, provinceColor);
          
          final selectedFillPaint = Paint()
            ..color = isSelectedCommune
                ? Colors.black.withValues(alpha: 0.70)
                : communeColor.withValues(alpha: 0.65)
            ..style = PaintingStyle.fill;

          final selectedBorderPaint = Paint()
            ..color = isSelectedCommune ? Colors.black : Colors.white.withValues(alpha: 0.95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelectedCommune ? 3 : 1.2;

          canvas.drawPath(path, selectedFillPaint);
          canvas.drawPath(path, selectedBorderPaint);
        }
      }
    }

    if (!isCommuneMode) {
      final fillPaint = Paint()
        ..color = provinceColor.withValues(alpha: 0.52)
        ..style = PaintingStyle.fill;
      canvas.drawPath(allCommunePath, fillPaint);
    }

    canvas.drawPath(allCommunePath, outerBorderPaint);

    if (combinedBounds == null) return;

    if (!isCommuneMode) {
      _drawProvinceLabel(
        canvas,
        combinedBounds!.center,
        province.displayName,
        provinceColor,
      );
    }

    // debugPrint('Commune labels: \${communeLabels.length}');
    //
    // for (final label in communeLabels) {
    //   _drawCommuneLabel(
    //     canvas,
    //     label.center,
    //     label.name,
    //   );
    // }
  }''',
'''class _DetailedProvincePainter extends CustomPainter {
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
  }''');

  // Step 5: Update _PlaceMarker to not recalculate bounds!
  content = content.replaceFirst(
'''class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({
    required this.place,
    required this.constraints,
    required this.communes,
    required this.isSelected,
    required this.isInRoute,
    required this.onTap,
  });

  final TourismDestinationModel place;
  final BoxConstraints constraints;
  final List<_CommuneArea> communes;
  final bool isSelected;
  final bool isInRoute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final allPoints = <_MapPoint>[];

    for (final commune in communes) {
      for (final polygon in commune.polygons) {
        for (final ring in polygon) {
          allPoints.addAll(ring);
        }
      }
    }

    if (allPoints.isEmpty) return const SizedBox();

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

    final x = (place.longitude - minLon) / lonRange * size.width;
    final y = size.height - (place.latitude - minLat) / latRange * size.height;''',
'''class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({
    required this.place,
    required this.constraints,
    required this.communes,
    required this.isSelected,
    required this.isInRoute,
    required this.onTap,
  });

  final TourismDestinationModel place;
  final BoxConstraints constraints;
  final List<_CommuneArea> communes;
  final bool isSelected;
  final bool isInRoute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (communes.isEmpty) return const SizedBox();

    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;

    // This is still calculating per marker, but we can do a quick calc without deep points array if we just cache min/max lon. 
    // Actually for PlaceMarker it's better to just do this loop quickly.
    for (final commune in communes) {
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
    }

    final lonRange = math.max(maxLon - minLon, 0.01);
    final latRange = math.max(maxLat - minLat, 0.01);

    final size = Size(
      constraints.maxWidth,
      constraints.maxHeight,
    );

    final x = (place.longitude - minLon) / lonRange * size.width;
    final y = size.height - (place.latitude - minLat) / latRange * size.height;''');

  file.writeAsStringSync(content);
}
