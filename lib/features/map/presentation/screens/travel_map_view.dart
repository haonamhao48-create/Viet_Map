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
  HighSchoolModel? _selectedSchool;
  List<HighSchoolModel> _schools = const [];
  bool _loadingSchools = false;
  bool _schoolsChecked = false;
  bool _showPlacesOnMap = true;
  bool _showSchoolsOnMap = true;
  bool _schoolMapMode = false;

  final _highSchoolDataSource = HighSchoolFirestoreDataSource();

  @override
  void initState() {
    super.initState();
    _selectedPlace = null;
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
        _selectedSchool = null;
        _schools = const [];
        _schoolsChecked = false;
        _schoolMapMode = false;
      } else {
        _selectedCommune = commune;
        _selectedPlace = null;
        _selectedSchool = null;
        _schools = const [];
        _schoolsChecked = false;
        _schoolMapMode = false;
      }
    });

    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Scaffold.of(context).closeDrawer();
    }

    if (_selectedCommune != null) {
      _loadSchools(_selectedCommune!);
    }
  }

  Future<void> _enterSchoolMapMode() async {
    final commune = _selectedCommune;
    if (commune == null || _schools.isEmpty) return;

    setState(() {
      _schoolMapMode = true;
      _selectedSchool = null;
    });
  }

  void _exitSchoolMapMode() {
    setState(() {
      _schoolMapMode = false;
      _selectedSchool = null;
    });
  }

  List<_CommuneArea> get _mapCommunes {
    if (_schoolMapMode && _selectedCommune != null) {
      return [_selectedCommune!];
    }
    return widget.communes;
  }

  Future<void> _loadSchools(_CommuneArea commune) async {
    setState(() => _loadingSchools = true);

    try {
      final schools = await _highSchoolDataSource.getByCommuneCode(commune.ma);
      if (!mounted || _selectedCommune?.ma != commune.ma) {
        return;
      }
      setState(() => _schools = schools);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách trường: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingSchools = false;
          _schoolsChecked = true;
        });
      }
    }
  }

  void _selectSchool(HighSchoolModel school) {
    setState(() {
      _selectedSchool = school;
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
    final visiblePlaces = _showPlacesOnMap ? widget.places : <TourismDestinationModel>[];
    final mapPlaces = widget.isCommuneMode ? const <TourismDestinationModel>[] : widget.places;

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
                if (widget.isCommuneMode && !_schoolMapMode)
                  SizedBox(
                    width: 300,
                    child: _CommunesSidePanel(
                      province: widget.province,
                      communes: widget.communes,
                      selectedCommune: _selectedCommune,
                      onCommuneSelected: _selectCommune,
                    ),
                  ),
                Expanded(
                  child: _TravelMapView(
                    province: widget.province,
                    places: mapPlaces,
                    communes: _mapCommunes,
                    isCommuneMode: widget.isCommuneMode,
                    schoolMapMode: _schoolMapMode,
                    selectedPlace: _selectedPlace,
                    selectedCommune: _selectedCommune,
                    routePlaces: _routePlaces,
                    schools: _schools,
                    selectedSchool: _selectedSchool,
                    showPlacesOnMap: _showPlacesOnMap,
                    showSchoolsOnMap: _showSchoolsOnMap,
                    onPlaceSelected: _selectPlace,
                    onRouteToggle: _toggleRoutePlace,
                    onCommuneSelected: _selectCommune,
                    onSchoolSelected: _selectSchool,
                    onExitSchoolMapMode: _exitSchoolMapMode,
                    onTogglePlacesOnMap: () {
                      setState(() {
                        _showPlacesOnMap = !_showPlacesOnMap;
                      });
                    },
                    onToggleSchoolsOnMap: () {
                      setState(() {
                        _showSchoolsOnMap = !_showSchoolsOnMap;
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
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  widget.isCommuneMode && !_schoolMapMode
                                      ? 'Chọn xã/phường trên bản đồ hoặc trong danh sách bên trái.'
                                      : 'Chọn một xã/phường để xem chi tiết',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ),
                            ),
                          )
                        : _CommuneDetail(
                            commune: _selectedCommune!,
                            schoolMapMode: _schoolMapMode,
                            schools: _schools,
                            selectedSchool: _selectedSchool,
                            isLoadingSchools: _loadingSchools,
                            schoolsChecked: _schoolsChecked,
                            onViewSchools: _enterSchoolMapMode,
                            onExitSchoolMap: _exitSchoolMapMode,
                            onSchoolSelected: _selectSchool,
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
                  _schoolMapMode = false;
                  _schools = const [];
                  _schoolsChecked = false;
                });
              },
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: _TravelMapView(
                  province: widget.province,
                  places: mapPlaces,
                  communes: _mapCommunes,
                  isCommuneMode: widget.isCommuneMode,
                  schoolMapMode: _schoolMapMode,
                  selectedPlace: _selectedPlace,
                  selectedCommune: _selectedCommune,
                  routePlaces: _routePlaces,
                  schools: _schools,
                  selectedSchool: _selectedSchool,
                  showPlacesOnMap: _showPlacesOnMap,
                  showSchoolsOnMap: _showSchoolsOnMap,
                  onPlaceSelected: (place) {
                    _selectPlace(place);
                  },
                  onRouteToggle: _toggleRoutePlace,
                  onCommuneSelected: (commune) {
                    _selectCommune(commune);
                  },
                  onSchoolSelected: _selectSchool,
                  onExitSchoolMapMode: _exitSchoolMapMode,
                  onTogglePlacesOnMap: () {
                    setState(() {
                      _showPlacesOnMap = !_showPlacesOnMap;
                    });
                  },
                  onToggleSchoolsOnMap: () {
                    setState(() {
                      _showSchoolsOnMap = !_showSchoolsOnMap;
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
                    schoolMapMode: _schoolMapMode,
                    schools: _schools,
                    selectedSchool: _selectedSchool,
                    isLoadingSchools: _loadingSchools,
                    schoolsChecked: _schoolsChecked,
                    routePlaces: _routePlaces,
                    onRouteToggle: _toggleRoutePlace,
                    onRemoveRoutePlace: _removeRoutePlace,
                    onClearRoute: _clearRoute,
                    onViewSchools: _enterSchoolMapMode,
                    onExitSchoolMap: _exitSchoolMapMode,
                    onSchoolSelected: _selectSchool,
                    onClose: () {
                      setState(() {
                        _selectedPlace = null;
                        _selectedCommune = null;
                        _selectedSchool = null;
                        _schools = const [];
                        _schoolsChecked = false;
                        _schoolMapMode = false;
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
    required this.schoolMapMode,
    required this.selectedPlace,
    required this.selectedCommune,
    required this.routePlaces,
    required this.schools,
    required this.selectedSchool,
    required this.onPlaceSelected,
    required this.onRouteToggle,
    required this.onCommuneSelected,
    required this.onSchoolSelected,
    required this.onExitSchoolMapMode,
    required this.showPlacesOnMap,
    required this.showSchoolsOnMap,
    required this.onTogglePlacesOnMap,
    required this.onToggleSchoolsOnMap,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final List<_CommuneArea> communes;
  final bool isCommuneMode;
  final bool schoolMapMode;
  final TourismDestinationModel? selectedPlace;
  final ValueChanged<TourismDestinationModel> onPlaceSelected;
  final List<TourismDestinationModel> routePlaces;
  final ValueChanged<TourismDestinationModel> onRouteToggle;
  final _CommuneArea? selectedCommune;
  final ValueChanged<_CommuneArea> onCommuneSelected;
  final List<HighSchoolModel> schools;
  final HighSchoolModel? selectedSchool;
  final ValueChanged<HighSchoolModel> onSchoolSelected;
  final VoidCallback onExitSchoolMapMode;
  final bool showPlacesOnMap;
  final bool showSchoolsOnMap;
  final VoidCallback onTogglePlacesOnMap;
  final VoidCallback onToggleSchoolsOnMap;

  @override
  State<_TravelMapView> createState() => _TravelMapViewState();
}

class _TravelMapViewState extends State<_TravelMapView> {
  Size? _lastSize;
  String? _lastPathsSignature;
  _MapProjection? _projection;
  Map<String, Path> _scaledCommunePaths = {};
  Path _scaledProvincePath = Path();
  Rect? _combinedBounds;
  final TransformationController _transformController =
      TransformationController();

  Size? _markerCacheSize;
  int? _markerCacheSignature;
  _MapProjection? _markerCacheProjection;
  List<Offset> _markerPointsCache = const [];

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
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TravelMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final boundsChanged = widget.communes != oldWidget.communes ||
        widget.schoolMapMode != oldWidget.schoolMapMode;

    if (boundsChanged) {
      _calculateBounds();
      _lastSize = null;
      _lastPathsSignature = null;
      _markerPointsCache = const [];
      _markerCacheSize = null;
      _transformController.value = Matrix4.identity();
    }
  }

  String _pathsSignature(Size size) {
    final communeKey = widget.communes.map((c) => c.ma).join('_');
    return '${widget.province.displayName}_${widget.schoolMapMode}_${communeKey}_${size.width}x${size.height}';
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
    final pathsSignature = _pathsSignature(size);
    if (_lastSize == size &&
        _lastPathsSignature == pathsSignature &&
        _projection != null &&
        _scaledCommunePaths.isNotEmpty) {
      return;
    }

    final cacheKey = pathsSignature;
    if (_pathsCache.containsKey(cacheKey)) {
      final cached = _pathsCache[cacheKey]!;
      _scaledCommunePaths = cached['communePaths'] as Map<String, Path>;
      _scaledProvincePath = cached['provincePath'] as Path;
      _combinedBounds = cached['bounds'] as Rect?;
      _projection = cached['projection'] as _MapProjection?;
      _lastSize = size;
      _lastPathsSignature = pathsSignature;
      return;
    }

    _scaledCommunePaths.clear();
    _scaledProvincePath = Path()..fillType = PathFillType.evenOdd;
    _combinedBounds = null;

    if (widget.communes.isEmpty || size.width == 0 || size.height == 0) return;

    final padding = widget.schoolMapMode
        ? math.min(size.width, size.height) * 0.10
        : math.min(size.width, size.height) * 0.14;
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
    _lastPathsSignature = pathsSignature;
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

  int _markerPlacesSignature() {
    return Object.hash(
      widget.places.length,
      Object.hashAll(
        widget.places.map(
          (place) => Object.hash(place.name, place.latitude, place.longitude),
        ),
      ),
    );
  }

  List<Offset> _markerPointsFor(Size size) {
    final signature = _markerPlacesSignature();
    if (_markerCacheSize == size &&
        _markerCacheSignature == signature &&
        _markerCacheProjection == _projection &&
        _markerPointsCache.length == widget.places.length) {
      return _markerPointsCache;
    }

    final points = _buildMarkerPoints(size, widget.places);
    _markerCacheSize = size;
    _markerCacheSignature = signature;
    _markerCacheProjection = _projection;
    _markerPointsCache = points;
    return points;
  }

  List<Offset> _buildMarkerPoints(
    Size size,
    List<TourismDestinationModel> places,
  ) {
    final rawPoints = <Offset>[];

    for (var index = 0; index < places.length; index++) {
      final place = places[index];
      final hasValidLatLng = place.latitude != 0 && place.longitude != 0;

      if (hasValidLatLng && _projection != null) {
        rawPoints.add(
          _projection!.project(
            _MapPoint(
              longitude: place.longitude,
              latitude: place.latitude,
            ),
          ),
        );
      } else {
        final fallback = _fallbackPositions[index % _fallbackPositions.length];
        rawPoints.add(
          Offset(
            size.width * fallback.dx,
            size.height * fallback.dy,
          ),
        );
      }
    }

    const minDistance = 44.0;
    const baseSpreadRadius = 18.0;
    final adjusted = <Offset>[];

    for (var i = 0; i < rawPoints.length; i++) {
      var point = rawPoints[i];
      final place = places[i];
      final usesGps =
          place.latitude != 0 && place.longitude != 0 && _projection != null;
      var overlapIndex = 0;

      for (var j = 0; j < adjusted.length; j++) {
        if ((adjusted[j] - point).distance < minDistance) {
          overlapIndex++;
        }
      }

      if (overlapIndex > 0) {
        final ring = ((overlapIndex - 1) ~/ 6) + 1;
        final angle = (overlapIndex - 1) * (math.pi / 3);
        final radius = baseSpreadRadius + (ring - 1) * 12;
        point = Offset(
          point.dx + math.cos(angle) * radius,
          point.dy + math.sin(angle) * radius,
        );
      }

      adjusted.add(
        usesGps
            ? point
            : Offset(
                point.dx.clamp(14.0, size.width - 14.0),
                point.dy.clamp(14.0, size.height - 14.0),
              ),
      );
    }

    return adjusted;
  }

  List<({HighSchoolModel school, Offset point})> _buildSchoolMarkers(
    Size size,
    List<HighSchoolModel> schools,
  ) {
    if (_projection == null || widget.communes.isEmpty) {
      return const [];
    }

    final commune = widget.communes.first;
    final rawEntries = <({HighSchoolModel school, Offset point})>[];

    for (var index = 0; index < schools.length; index++) {
      final school = schools[index];
      if (!school.hasValidCoordinates) continue;

      final displayPoint = schoolDisplayPoint(school, commune, index);
      rawEntries.add((
        school: school,
        point: _projection!.project(displayPoint),
      ));
    }

    const minDistance = 40.0;
    const baseSpreadRadius = 16.0;
    final adjusted = <({HighSchoolModel school, Offset point})>[];

    for (final entry in rawEntries) {
      var point = entry.point;
      var overlapIndex = 0;

      for (final previous in adjusted) {
        if ((previous.point - point).distance < minDistance) {
          overlapIndex++;
        }
      }

      if (overlapIndex > 0) {
        final ring = ((overlapIndex - 1) ~/ 6) + 1;
        final angle = (overlapIndex - 1) * (math.pi / 3);
        final radius = baseSpreadRadius + (ring - 1) * 10;
        point = Offset(
          point.dx + math.cos(angle) * radius,
          point.dy + math.sin(angle) * radius,
        );
      }

      adjusted.add((school: entry.school, point: point));
    }

    return adjusted;
  }

  Widget _buildMapLayer(Size size) {
    final allMarkerPoints = _markerPointsFor(size);

    final visibleSchools = widget.schools
        .where((school) => school.hasValidCoordinates)
        .toList(growable: false);
    final schoolMarkers = _buildSchoolMarkers(size, visibleSchools);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: widget.isCommuneMode && !widget.schoolMapMode
          ? (details) {
              final position =
                  _transformController.toScene(details.localPosition);
              final commune = _communeAtPosition(position);
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
                schoolMapMode: widget.schoolMapMode,
                selectedCommuneName: widget.selectedCommune?.name,
                scaledCommunePaths: _scaledCommunePaths,
                scaledProvincePath: _scaledProvincePath,
                combinedBounds: _combinedBounds,
              ),
            ),
          ),
          if (widget.schoolMapMode)
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: widget.onExitSchoolMapMode,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Quay lại bản đồ xã/phường',
                          style: TextStyle(
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
          if (widget.schoolMapMode)
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: widget.onToggleSchoolsOnMap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.showSchoolsOnMap
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.showSchoolsOnMap
                              ? 'Ẩn trường THPT'
                              : 'Hiện trường THPT',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (!widget.isCommuneMode)
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
            ...List.generate(widget.places.length, (placeIndex) {
              final place = widget.places[placeIndex];
              if (placeIndex >= allMarkerPoints.length) {
                return const SizedBox.shrink();
              }

              final isSelected = widget.selectedPlace?.name == place.name;
              final isInRoute = widget.routePlaces
                  .any((item) => item.name == place.name);
              final point = allMarkerPoints[placeIndex];
              if (!point.dx.isFinite || !point.dy.isFinite) {
                return const SizedBox.shrink();
              }

              final displayIndex = placeIndex + 1;
              final dimOthers =
                  widget.selectedPlace != null && !isSelected && !isInRoute;

              const pinWidth = 34.0;
              const pinHeight = 42.0;

              return Positioned(
                left: point.dx - pinWidth / 2,
                top: point.dy - pinHeight,
                child: Opacity(
                  opacity: dimOthers ? 0.35 : 1,
                  child: IgnorePointer(
                    ignoring: dimOthers,
                    child: _PlaceBubble(
                      index: displayIndex,
                      place: place,
                      isSelected: isSelected,
                      isInRoute: isInRoute,
                      showLabel: isSelected || isInRoute,
                      onTap: () => widget.onPlaceSelected(place),
                      onRouteToggle: () => widget.onRouteToggle(place),
                    ),
                  ),
                ),
              );
            }),
          if (widget.schoolMapMode &&
              widget.showSchoolsOnMap &&
              widget.selectedCommune != null)
            ...schoolMarkers.map((marker) {
              final school = marker.school;
              final point = marker.point;
              final isSelected = widget.selectedSchool?.id == school.id;

              return Positioned(
                left: point.dx - 16,
                top: point.dy - 16,
                child: _SchoolBubble(
                  school: school,
                  isSelected: isSelected,
                  showLabel: isSelected,
                  onTap: () => widget.onSchoolSelected(school),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _buildPathsIfNeeded(size);

        final enableZoom = widget.schoolMapMode;

        if (!enableZoom) {
          return _buildMapLayer(size);
        }

        return InteractiveViewer(
          transformationController: _transformController,
          minScale: 1,
          maxScale: 8,
          clipBehavior: Clip.none,
          boundaryMargin: const EdgeInsets.all(120),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: _buildMapLayer(size),
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
    required this.schoolMapMode,
    required this.schools,
    required this.selectedSchool,
    required this.isLoadingSchools,
    required this.schoolsChecked,
    required this.routePlaces,
    required this.onRouteToggle,
    required this.onRemoveRoutePlace,
    required this.onClearRoute,
    required this.onViewSchools,
    required this.onExitSchoolMap,
    required this.onSchoolSelected,
    required this.onClose,
  });

  final bool isCommuneMode;
  final TourismDestinationModel? selectedPlace;
  final _CommuneArea? selectedCommune;
  final bool schoolMapMode;
  final List<HighSchoolModel> schools;
  final HighSchoolModel? selectedSchool;
  final bool isLoadingSchools;
  final bool schoolsChecked;
  final List<TourismDestinationModel> routePlaces;
  final ValueChanged<TourismDestinationModel> onRouteToggle;
  final ValueChanged<TourismDestinationModel> onRemoveRoutePlace;
  final VoidCallback onClearRoute;
  final VoidCallback onViewSchools;
  final VoidCallback onExitSchoolMap;
  final ValueChanged<HighSchoolModel> onSchoolSelected;
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
                      ? _CommuneDetail(
                          commune: selectedCommune!,
                          schoolMapMode: schoolMapMode,
                          schools: schools,
                          selectedSchool: selectedSchool,
                          isLoadingSchools: isLoadingSchools,
                          schoolsChecked: schoolsChecked,
                          onViewSchools: onViewSchools,
                          onExitSchoolMap: onExitSchoolMap,
                          onSchoolSelected: onSchoolSelected,
                        )
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
