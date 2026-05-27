part of 'travel_places_screen.dart';

class _ProvinceTravelMap extends StatefulWidget {
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
  final bool isCommuneMode; // added

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
              if (widget.isCommuneMode)
                SizedBox(
                  width: 360,
                  child: _selectedCommune == null
                      ? Container(
                          color: Colors.white,
                          child: const Center(
                            child: Text('Chọn một xã/phường để xem chi tiết'),
                          ),
                        )
                      : _CommuneDetail(commune: _selectedCommune!),
                )
              else
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
            SizedBox(
              height: 260,
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
          ],
        );
      },
    );
  }
}

class _TravelMapView extends StatefulWidget {
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

  static final Map<String, Map<String, dynamic>> _pathsCache = {};

  final List<Offset> _bubblePositions = const [
    Offset(0.2, 0.2), Offset(0.3, 0.7), Offset(0.7, 0.3),
    Offset(0.8, 0.8), Offset(0.5, 0.2), Offset(0.8, 0.5),
    Offset(0.2, 0.8), Offset(0.5, 0.8), Offset(0.2, 0.5),
    Offset(0.9, 0.2),
  ];
  
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
    
    final cacheKey = '${widget.province.displayName}_${size.width}x${size.height}';
    if (_pathsCache.containsKey(cacheKey)) {
      final cached = _pathsCache[cacheKey]!;
      _scaledCommunePaths = cached['communePaths'];
      _scaledProvincePath = cached['provincePath'];
      _combinedBounds = cached['bounds'];
      _projection = cached['projection'];
      _lastSize = size;
      return;
    }
    
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
    
    _pathsCache[cacheKey] = {
      'communePaths': Map<String, Path>.from(_scaledCommunePaths),
      'provincePath': _scaledProvincePath,
      'bounds': _combinedBounds,
      'projection': _projection,
    };
    
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

            if (widget.showPlacesOnMap && !widget.isCommuneMode)
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
