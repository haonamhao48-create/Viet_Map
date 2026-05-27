part of 'travel_places_screen.dart';

/// Widget layout chính: ghép sidebar + bản đồ + detail panel.
class _ProvinceTravelMap extends StatefulWidget {
  const _ProvinceTravelMap({
    required this.province,
    required this.places,
    required this.communes,
    required this.isCommuneMode,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;
  final bool isCommuneMode;

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
      if (_selectedPlace?.name == place.name) {
        _selectedPlace = null;
      } else {
        _selectedPlace = place;
        _selectedCommune = null; // Clear commune selection
      }
    });
    // Đóng drawer nếu đang mở
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Scaffold.of(context).closeDrawer();
    }
  }

  void _selectCommune(_CommuneArea commune) {
    setState(() {
      if (_selectedCommune?.name == commune.name) {
         _selectedCommune = null;
      } else {
        _selectedCommune = commune;
        _selectedPlace = null; // Clear place selection
      }
    });
    // Đóng drawer nếu đang mở
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Scaffold.of(context).closeDrawer();
    }
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
    final visiblePlaces = _showPlacesOnMap ? widget.places : <TourismDestinationModel>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final appBar = AppBar(
          title: Text(widget.isCommuneMode ? 'Bản đồ xã/phường ${widget.province.displayName}' : 'Bản đồ phượt ${widget.province.displayName}'),
          backgroundColor: Colors.white,
          elevation: 0,
        );

        if (isWide) {
          // Desktop mode
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: appBar,
            body: Row(
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
                        : _CommuneDetail(
                            commune: _selectedCommune!,
                          ),
                  )
                else
                  SizedBox(
                    width: 360,
                    child: _selectedPlace == null
                        ? _PlacesSidePanel(
                            province: widget.province,
                            places: visiblePlaces,
                            selectedPlace: _selectedPlace,
                            routePlaces: _routePlaces,
                            onPlaceSelected: _selectPlace,
                            onRouteToggle: _toggleRoutePlace,
                          )
                        : Column(
                            children: [
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedPlace = null;
                                        });
                                      },
                                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                      label: const Text('Quay lại danh sách'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _SelectedPlaceDetailPanel(
                                  place: _selectedPlace,
                                  isInRoute: _isInRoute(_selectedPlace!),
                                  routePlaces: _routePlaces,
                                  onRouteToggle: () => _toggleRoutePlace(_selectedPlace!),
                                  onRemoveRoutePlace: _removeRoutePlace,
                                  onClearRoute: _clearRoute,
                                ),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
          );
        }

        // Mobile mode
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: appBar,
          drawer: Drawer(
            child: _TravelMobileDrawer(
              province: widget.province,
              places: visiblePlaces,
              communes: widget.communes,
              isCommuneMode: widget.isCommuneMode,
              selectedPlace: _selectedPlace,
              selectedCommune: _selectedCommune,
              routePlaces: _routePlaces,
              onPlaceSelected: (place) {
                _selectPlace(place);
                Navigator.of(context).pop(); // Đóng drawer
              },
              onCommuneSelected: (commune) {
                _selectCommune(commune);
                Navigator.of(context).pop(); // Đóng drawer
              },
              onRouteToggle: _toggleRoutePlace,
              onRemoveRoutePlace: _removeRoutePlace,
              onClearRoute: _clearRoute,
              onClearSelection: () {
                setState(() {
                  _selectedPlace = null;
                  _selectedCommune = null;
                });
              },
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: _TravelMapView(
                  province: widget.province,
                  places: widget.isCommuneMode ? [] : visiblePlaces,
                  communes: widget.communes,
                  isCommuneMode: widget.isCommuneMode,
                  selectedPlace: _selectedPlace,
                  selectedCommune: _selectedCommune,
                  routePlaces: _routePlaces,
                  showPlacesOnMap: _showPlacesOnMap,
                  onPlaceSelected: (place) {
                    _selectPlace(place);
                  },
                  onRouteToggle: _toggleRoutePlace,
                  onCommuneSelected: (commune) {
                     _selectCommune(commune);
                  },
                  onTogglePlacesOnMap: () {
                    setState(() {
                      _showPlacesOnMap = !_showPlacesOnMap;
                    });
                  },
                ),
              ),
              if (_selectedPlace != null || _selectedCommune != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _TravelMobileSelectionPopup(
                    isCommuneMode: widget.isCommuneMode,
                    selectedPlace: _selectedPlace,
                    selectedCommune: _selectedCommune,
                    routePlaces: _routePlaces,
                    onRouteToggle: _toggleRoutePlace,
                    onRemoveRoutePlace: _removeRoutePlace,
                    onClearRoute: _clearRoute,
                    onClose: () {
                      setState(() {
                        _selectedPlace = null;
                        _selectedCommune = null;
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget vẽ bản đồ tương tác + markers địa điểm.
class _TravelMapView extends StatefulWidget {
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

  // Fallback positions for places without GPS coordinates
  static const List<Offset> _fallbackPositions = [
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
      _lastSize = null;
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
      _scaledCommunePaths = cached['communePaths'] as Map<String, Path>;
      _scaledProvincePath = cached['provincePath'] as Path;
      _combinedBounds = cached['bounds'] as Rect?;
      _projection = cached['projection'] as _MapProjection?;
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

    final scale = math.min(usableWidth / _lonRange, usableHeight / _latRange);
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
        _combinedBounds = _combinedBounds == null
            ? bounds
            : _combinedBounds!.expandToInclude(bounds);
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
          onTapUp: widget.isCommuneMode
              ? (details) {
                  final commune = _communeAtPosition(details.localPosition);
                  if (commune != null) {
                    widget.onCommuneSelected(commune);
                  }
                }
              : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: const _TravelMapBackgroundPainter(),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                            widget.showPlacesOnMap
                                ? 'Ẩn địa điểm'
                                : 'Hiện địa điểm',
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
                  final isSelected =
                      widget.selectedPlace?.name == place.name;
                  final isInRoute = widget.routePlaces
                      .any((item) => item.name == place.name);

                  final Offset point;
                  final hasValidLatLng =
                      place.latitude != 0 && place.longitude != 0;

                  if (hasValidLatLng && _projection != null) {
                    point = _projection!.project(
                      _MapPoint(
                        longitude: place.longitude,
                        latitude: place.latitude,
                      ),
                    );
                  } else {
                    final fallback =
                        _fallbackPositions[index % _fallbackPositions.length];
                    point = Offset(
                      constraints.maxWidth * fallback.dx,
                      constraints.maxHeight * fallback.dy,
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
                      onTap: () => widget.onPlaceSelected(place),
                      onRouteToggle: () => widget.onRouteToggle(place),
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

class _TravelMobileDrawer extends StatelessWidget {
  const _TravelMobileDrawer({
    required this.province,
    required this.places,
    required this.communes,
    required this.isCommuneMode,
    required this.selectedPlace,
    required this.selectedCommune,
    required this.routePlaces,
    required this.onPlaceSelected,
    required this.onCommuneSelected,
    required this.onRouteToggle,
    required this.onRemoveRoutePlace,
    required this.onClearRoute,
    required this.onClearSelection,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;
  final bool isCommuneMode;
  final TourismDestinationModel? selectedPlace;
  final _CommuneArea? selectedCommune;
  final List<TourismDestinationModel> routePlaces;
  final ValueChanged<TourismDestinationModel> onPlaceSelected;
  final ValueChanged<_CommuneArea> onCommuneSelected;
  final ValueChanged<TourismDestinationModel> onRouteToggle;
  final ValueChanged<TourismDestinationModel> onRemoveRoutePlace;
  final VoidCallback onClearRoute;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      children: [
        // Drawer Header (Title)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Text(
            isCommuneMode ? 'Danh sách xã/phường' : 'Danh sách địa điểm',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final child = isCommuneMode
        ? _CommunesSidePanel(
            province: province,
            communes: communes,
            selectedCommune: selectedCommune,
            onCommuneSelected: onPlaceSelectedWrapperForCommunes,
          )
        : _PlacesSidePanel(
            province: province,
            places: places,
            selectedPlace: selectedPlace,
            routePlaces: routePlaces,
            onPlaceSelected: onPlaceSelected,
            onRouteToggle: onRouteToggle,
          );
              
    return SafeArea(
      child: Column(
        children: [
          header,
          Expanded(child: child),
        ],
      ),
    );
  }

  void onPlaceSelectedWrapperForCommunes(_CommuneArea commune) {
    onCommuneSelected(commune);
  }
}

class _TravelMobileSelectionPopup extends StatelessWidget {
  const _TravelMobileSelectionPopup({
    required this.isCommuneMode,
    required this.selectedPlace,
    required this.selectedCommune,
    required this.routePlaces,
    required this.onRouteToggle,
    required this.onRemoveRoutePlace,
    required this.onClearRoute,
    required this.onClose,
  });

  final bool isCommuneMode;
  final TourismDestinationModel? selectedPlace;
  final _CommuneArea? selectedCommune;
  final List<TourismDestinationModel> routePlaces;
  final ValueChanged<TourismDestinationModel> onRouteToggle;
  final ValueChanged<TourismDestinationModel> onRemoveRoutePlace;
  final VoidCallback onClearRoute;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.48,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiết lựa chọn',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Flexible(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: isCommuneMode
                  ? (selectedCommune != null
                      ? _CommuneDetail(commune: selectedCommune!)
                      : const SizedBox.shrink())
                  : (selectedPlace != null
                      ? _SelectedPlaceDetailPanel(
                          place: selectedPlace,
                          isInRoute: routePlaces.any((item) => item.name == selectedPlace!.name),
                          routePlaces: routePlaces,
                          onRouteToggle: () => onRouteToggle(selectedPlace!),
                          onRemoveRoutePlace: onRemoveRoutePlace,
                          onClearRoute: onClearRoute,
                        )
                      : const SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }
}
