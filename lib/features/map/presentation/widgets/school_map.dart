import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/school_provider.dart';
import '../providers/route_provider.dart';
import '../../data/models/high_school_model.dart';

class RegionData {
  final String name;
  final LatLng center;
  final List<String> provinces;
  
  const RegionData({
    required this.name,
    required this.center,
    required this.provinces,
  });
}

class ProvinceStats {
  final String name;
  final LatLng center;
  final int schoolCount;
  
  ProvinceStats({
    required this.name,
    required this.center,
    required this.schoolCount,
  });
}

const List<RegionData> regionsList = [
  RegionData(
    name: 'Tây Bắc Bộ',
    center: LatLng(21.5, 103.8),
    provinces: ['Lai Châu', 'Điện Biên', 'Sơn La', 'Hòa Bình', 'Yên Bái', 'Lào Cai'],
  ),
  RegionData(
    name: 'Đông Bắc Bộ',
    center: LatLng(21.8, 106.0),
    provinces: ['Hà Giang', 'Cao Bằng', 'Bắc Kạn', 'Lạng Sơn', 'Tuyên Quang', 'Thái Nguyên', 'Phú Thọ', 'Bắc Giang', 'Quảng Ninh'],
  ),
  RegionData(
    name: 'Đồng bằng Sông Hồng',
    center: LatLng(20.9, 105.8),
    provinces: ['Hà Nội', 'Hải Phòng', 'Hải Dương', 'Hưng Yên', 'Bắc Ninh', 'Hà Nam', 'Nam Định', 'Thái Bình', 'Ninh Bình', 'Vĩnh Phúc'],
  ),
  RegionData(
    name: 'Bắc Trung Bộ',
    center: LatLng(18.2, 105.8),
    provinces: ['Thanh Hóa', 'Nghệ An', 'Hà Tĩnh', 'Quảng Bình', 'Quảng Trị', 'Thừa Thiên Huế'],
  ),
  RegionData(
    name: 'Nam Trung Bộ',
    center: LatLng(14.8, 108.8),
    provinces: ['Đà Nẵng', 'Quảng Nam', 'Quảng Ngãi', 'Bình Định', 'Phú Yên', 'Khánh Hòa', 'Ninh Thuận', 'Bình Thuận'],
  ),
  RegionData(
    name: 'Tây Nguyên',
    center: LatLng(13.3, 108.0),
    provinces: ['Kon Tum', 'Gia Lai', 'Đắk Lắk', 'Đắk Nông', 'Lâm Đồng'],
  ),
  RegionData(
    name: 'Đông Nam Bộ',
    center: LatLng(11.1, 106.9),
    provinces: ['TP. Hồ Chí Minh', 'Đồng Nai', 'Bà Rịa - Vũng Tàu', 'Bình Dương', 'Bình Phước', 'Tây Ninh'],
  ),
  RegionData(
    name: 'Đồng bằng Sông Cửu Long',
    center: LatLng(9.8, 105.4),
    provinces: ['Cần Thơ', 'Long An', 'Tiền Giang', 'Bến Tre', 'Trà Vinh', 'Vĩnh Long', 'Đồng Tháp', 'An Giang', 'Kiên Giang', 'Sóc Trăng', 'Bạc Liêu', 'Cà Mau', 'Hậu Giang'],
  ),
];

String normalizeProvinceName(String name) {
  final n = name.trim().toLowerCase();
  if (n.contains('hồ chí minh') || n.contains('hcm')) return 'TP. Hồ Chí Minh';
  if (n.contains('huế') || n.contains('thừa thiên')) return 'Thừa Thiên Huế';
  if (n.contains('đồng nai')) return 'Đồng Nai';
  if (n.contains('khánh hoà') || n.contains('khánh hòa')) return 'Khánh Hòa';
  if (n.contains('thanh hoá') || n.contains('thanh hóa')) return 'Thanh Hóa';
  return name.trim();
}

class SchoolMap extends ConsumerStatefulWidget {
  const SchoolMap({super.key});

  @override
  ConsumerState<SchoolMap> createState() => _SchoolMapState();
}

class _SchoolMapState extends ConsumerState<SchoolMap> {
  late final MapController _mapController;
  static const LatLng _vietnamCenter = LatLng(15.8, 108.0);
  static const double _defaultZoom = 6.0;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  LatLngBounds? _visibleBounds;
  double _currentZoom = _defaultZoom;

  final Map<String, List<List<LatLng>>> _provinceBoundaries = {};
  bool _isLoadingBoundaries = true;

  static const List<String> _geojsonFiles = [
    '01_ha_noi.geojson', '04_cao_bang.geojson', '08_tuyen_quang.geojson', 
    '11_dien_bien.geojson', '12_lai_chau.geojson', '14_son_la.geojson', 
    '15_lao_cai.geojson', '19_thai_nguyen.geojson', '20_lang_son.geojson', 
    '22_quang_ninh.geojson', '24_bac_ninh.geojson', '25_phu_tho.geojson', 
    '31_hai_phong.geojson', '33_hung_yen.geojson', '37_ninh_binh.geojson', 
    '38_thanh_hoa.geojson', '40_nghe_an.geojson', '42_ha_tinh.geojson', 
    '44_quang_tri.geojson', '46_hue.geojson', '48_da_nang.geojson', 
    '51_quang_ngai.geojson', '52_gia_lai.geojson', '56_khanh_hoa.geojson', 
    '66_dak_lak.geojson', '68_lam_dong.geojson', '75_dong_nai.geojson', 
    '79_ho_chi_minh.geojson', '80_tay_ninh.geojson', '82_dong_thap.geojson', 
    '86_vinh_long.geojson', '91_an_giang.geojson', '92_can_tho.geojson', 
    '96_ca_mau.geojson'
  ];

  Color _getRegionColor(String regionName) {
    switch (regionName) {
      case 'Tây Bắc Bộ':
        return Colors.green.shade600;
      case 'Đông Bắc Bộ':
        return Colors.teal.shade600;
      case 'Đồng bằng Sông Hồng':
        return Colors.blue.shade600;
      case 'Bắc Trung Bộ':
        return Colors.orange.shade700;
      case 'Nam Trung Bộ':
        return Colors.amber.shade700;
      case 'Tây Nguyên':
        return Colors.brown.shade500;
      case 'Đông Nam Bộ':
        return Colors.red.shade600;
      case 'Đồng bằng Sông Cửu Long':
        return Colors.purple.shade600;
      default:
        return const Color(0xFF0F766E);
    }
  }

  Future<void> _loadAllBoundaries() async {
    if (mounted) {
      setState(() {
        _isLoadingBoundaries = true;
      });
    }

    _provinceBoundaries.clear();

    try {
      /*
     * Không tải đồng thời toàn bộ 34 file.
     * Mỗi đợt chỉ tải tối đa 4 file để tránh nghẽn mạng,
     * CPU và bộ nhớ.
     */
      const batchSize = 4;

      for (int start = 0; start < _geojsonFiles.length; start += batchSize) {
        final end = (start + batchSize < _geojsonFiles.length)
            ? start + batchSize
            : _geojsonFiles.length;

        final currentBatch = _geojsonFiles.sublist(start, end);

        final batchResults = await Future.wait(
          currentBatch.map((fileName) async {
            try {
              final jsonString = await _loadGeoJsonFromFirebase(fileName);

              final parsedResult = await compute(
                parseGeoJsonIsolate,
                GeoJsonParseTask(jsonStr: jsonString),
              );

              return parsedResult.boundaries;
            } catch (error, stackTrace) {
              debugPrint(
                '[GEOJSON] Lỗi file $fileName: $error\n$stackTrace',
              );

              return <String, List<List<LatLng>>>{};
            }
          }),
        );

        for (final result in batchResults) {
          result.forEach((provinceName, polygonRings) {
            _provinceBoundaries
                .putIfAbsent(provinceName, () => <List<LatLng>>[])
                .addAll(polygonRings);
          });
        }

        debugPrint(
          '[GEOJSON] Đã xử lý $end/${_geojsonFiles.length} file',
        );
      }

      debugPrint(
        '[GEOJSON] Hoàn tất, số tỉnh: ${_provinceBoundaries.length}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Lỗi tải ranh giới địa phận: $error\n$stackTrace',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBoundaries = false;
        });
      }
    }
  }

  Future<String> _loadGeoJsonFromFirebase(String fileName) async {
    final appDirectory = await getApplicationSupportDirectory();

    final cacheDirectory = Directory(
      '${appDirectory.path}${Platform.pathSeparator}geojson'
          '${Platform.pathSeparator}provinces',
    );

    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }

    final localFile = File(
      '${cacheDirectory.path}${Platform.pathSeparator}$fileName',
    );

    // Đã tải trước đó thì đọc từ máy, không tải Firebase lần nữa.
    if (await localFile.exists() && await localFile.length() > 0) {
      debugPrint('[GEOJSON] Đọc cache: $fileName');
      return localFile.readAsString();
    }

    debugPrint('[GEOJSON] Đang tải Firebase: $fileName');

    final storageReference = _firebaseStorage.ref(
      'geojson/provinces/$fileName',
    );

    try {
      await storageReference.writeToFile(localFile);

      debugPrint(
        '[GEOJSON] Tải thành công: $fileName, '
            '${await localFile.length()} bytes',
      );

      return localFile.readAsString();
    } catch (error) {
      // Không giữ lại file hỏng hoặc file tải chưa hoàn tất.
      if (await localFile.exists()) {
        await localFile.delete();
      }

      throw Exception(
        'Không tải được geojson/provinces/$fileName: $error',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadAllBoundaries();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBoundaries) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
        ),
      );
    }

    final schoolsAsync = ref.watch(schoolsProvider);
    final filteredSchools = ref.watch(filteredSchoolsProvider);
    final selectedSchool = ref.watch(selectedSchoolProvider);
    final startSchool = ref.watch(startSchoolProvider);
    final endSchool = ref.watch(endSchoolProvider);
    
    // Watch OSRM route points
    final routePointsAsync = ref.watch(routePointsProvider);
    final routePoints = (startSchool == null || endSchool == null)
        ? const <LatLng>[]
        : (routePointsAsync.valueOrNull ?? []);

    // Listen for selection changes to center the camera on the school
    ref.listen<HighSchoolModel?>(selectedSchoolProvider, (previous, next) {
      if (next != null && next.hasValidCoordinates) {
        // Zoom to at least 12 so the school marker is always visible
        final targetZoom = _currentZoom < 12.0 ? 12.0 : _currentZoom;
        _mapController.move(LatLng(next.latitude, next.longitude), targetZoom);
      }
    });

    // Listen for route points changes to auto-zoom and center the route
    ref.listen<AsyncValue<List<LatLng>>>(routePointsProvider, (previous, next) {
      final points = next.valueOrNull ?? [];
      if (points.isNotEmpty) {
        final start = ref.read(startSchoolProvider);
        final end = ref.read(endSchoolProvider);
        if (start != null && end != null) {
          final minLat = start.latitude < end.latitude ? start.latitude : end.latitude;
          final maxLat = start.latitude > end.latitude ? start.latitude : end.latitude;
          final minLon = start.longitude < end.longitude ? start.longitude : end.longitude;
          final maxLon = start.longitude > end.longitude ? start.longitude : end.longitude;

          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds(
                LatLng(minLat, minLon),
                LatLng(maxLat, maxLon),
              ),
              padding: const EdgeInsets.all(80.0),
            ),
          );
        }
      }
    });

    // Listen for search results changes to automatically zoom and center them
    ref.listen<List<HighSchoolModel>>(filteredSchoolsProvider, (previous, next) {
      final query = ref.read(schoolSearchQueryProvider).trim();
      if (query.isNotEmpty && next.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final validCoords = next.where((s) => s.hasValidCoordinates).toList();
          if (validCoords.isNotEmpty) {
            if (validCoords.length == 1) {
              final school = validCoords.first;
              _mapController.move(LatLng(school.latitude, school.longitude), 13.0);
            } else {
              final bounds = LatLngBounds.fromPoints(
                validCoords.map((s) => LatLng(s.latitude, s.longitude)).toList(),
              );
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(64.0),
                ),
              );
            }
          }
        });
      }
    });

    return schoolsAsync.when(
      data: (_) {
        // 1. Calculate school count for each province dynamically
        final Map<String, int> provinceSchoolCounts = {};
        for (var school in filteredSchools) {
          if (!school.hasValidCoordinates) continue;
          final prov = normalizeProvinceName(school.tenTinhTp);
          provinceSchoolCounts[prov] = (provinceSchoolCounts[prov] ?? 0) + 1;
        }

        // 2. Calculate school count for each region dynamically
        final Map<String, int> regionSchoolCounts = {};
        for (var region in regionsList) {
          int count = 0;
          for (var prov in region.provinces) {
            count += provinceSchoolCounts[normalizeProvinceName(prov)] ?? 0;
          }
          regionSchoolCounts[region.name] = count;
        }

        // 3. Build stats for each province present in boundaries
        final List<ProvinceStats> provincesStatsList = [];
        _provinceBoundaries.forEach((provName, polyRings) {
          final count = provinceSchoolCounts[provName] ?? 0;
          if (count == 0) return; // Skip if no schools in this province
          
          double totalLat = 0;
          double totalLon = 0;
          int ptCount = 0;
          for (var ring in polyRings) {
            for (var p in ring) {
              totalLat += p.latitude;
              totalLon += p.longitude;
              ptCount++;
            }
          }
          final center = ptCount > 0 
              ? LatLng(totalLat / ptCount, totalLon / ptCount)
              : _vietnamCenter;

          provincesStatsList.add(ProvinceStats(
            name: provName,
            center: center,
            schoolCount: count,
          ));
        });

        final List<Marker> markers;
        final List<Polygon> mapPolygons = [];
        final searchQuery = ref.watch(schoolSearchQueryProvider).trim();
        final isSearching = searchQuery.isNotEmpty;

        if (_currentZoom < 7.0 && !isSearching) {
          // Level 1: Region View - Draw actual region boundaries (by painting its provinces)
          for (var region in regionsList) {
            final color = _getRegionColor(region.name);
            for (var provName in region.provinces) {
              final rings = _provinceBoundaries[normalizeProvinceName(provName)];
              if (rings != null) {
                for (var ring in rings) {
                  mapPolygons.add(
                    Polygon(
                      points: ring,
                      color: color.withValues(alpha: 0.15),
                      borderColor: color.withValues(alpha: 0.5),
                      borderStrokeWidth: 1.5,
                    ),
                  );
                }
              }
            }
          }

          // Minimal text labels at region centers
          markers = regionsList.map((region) {
            final count = regionSchoolCounts[region.name] ?? 0;
            return Marker(
              point: region.center,
              width: 140,
              height: 40,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    '${region.name}\n($count trường)',
                    style: const TextStyle(
                      color: Color(0xFF0B5952),
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                      shadows: [
                        Shadow(color: Colors.white, blurRadius: 4, offset: Offset(1, 1)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList();
        } else {
          // Level 2 & 3: School View (Zoom >= 7.0)
          
          // 1. Get visible school markers
          var visibleSchools = filteredSchools.where((s) {
            if (!s.hasValidCoordinates) return false;
            if (_visibleBounds == null || isSearching) return true;
            return _visibleBounds!.contains(LatLng(s.latitude, s.longitude));
          }).toList();

          // Always include critical schools (selected/start/end) even if outside viewport
          final criticalSchools = <HighSchoolModel>[];
          for (final school in filteredSchools) {
            if (!school.hasValidCoordinates) continue;
            if (school.id == selectedSchool?.id ||
                school.id == startSchool?.id ||
                school.id == endSchool?.id) {
              criticalSchools.add(school);
            }
          }
          final criticalIds = criticalSchools.map((s) => s.id).toSet();
          // Merge: keep visible list + any critical not already in it
          final visibleIds = visibleSchools.map((s) => s.id).toSet();
          visibleSchools = [
            ...visibleSchools,
            ...criticalSchools.where((s) => !visibleIds.contains(s.id)),
          ];


          const maxVisibleMarkers = 200;
          if (visibleSchools.length > maxVisibleMarkers) {
            final step = (visibleSchools.length / maxVisibleMarkers).ceil();
            final downsampled = <HighSchoolModel>[];
            for (int i = 0; i < visibleSchools.length; i += step) {
              downsampled.add(visibleSchools[i]);
            }
            visibleSchools = [
              ...downsampled.where((s) => !criticalIds.contains(s.id)),
              ...criticalSchools,
            ];
          }

          final schoolMarkers = visibleSchools.map((school) {
            final isSelected = selectedSchool?.id == school.id;
            final isStart = startSchool?.id == school.id;
            final isEnd = endSchool?.id == school.id;
            final markerSize = isSelected || isStart || isEnd ? 48.0 : 36.0;

            return Marker(
              point: LatLng(school.latitude, school.longitude),
              width: markerSize,
              height: markerSize,
              child: GestureDetector(
                onTap: () {
                  ref.read(selectedSchoolIdProvider.notifier).state = school.id;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: markerSize,
                    height: markerSize,
                    decoration: BoxDecoration(
                      color: isStart
                          ? Colors.green.shade600
                          : (isEnd
                              ? Colors.red.shade600
                              : (isSelected
                                  ? Colors.amber.shade700
                                  : const Color(0xFF0F766E))),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isStart
                            ? Icons.play_arrow_rounded
                            : (isEnd ? Icons.flag_rounded : Icons.school_rounded),
                        color: Colors.white,
                        size: isSelected || isStart || isEnd ? 20.0 : 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList();

          if (_currentZoom < 9.5 && !isSearching) {
            // Level 2: Province view - draw province boundaries and labels
            for (var prov in provincesStatsList) {
              final rings = _provinceBoundaries[prov.name];
              if (rings != null) {
                for (var ring in rings) {
                  mapPolygons.add(
                    Polygon(
                      points: ring,
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      borderColor: const Color(0xFF0F766E).withValues(alpha: 0.4),
                      borderStrokeWidth: 1.2,
                    ),
                  );
                }
              }
            }

            final provinceLabels = provincesStatsList.map((prov) {
              return Marker(
                point: prov.center,
                width: 120,
                height: 35,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      '${prov.name}\n(${prov.schoolCount} tr)',
                      style: TextStyle(
                        color: Colors.teal.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        shadows: const [
                          Shadow(color: Colors.white, blurRadius: 4, offset: Offset(1, 1)),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList();

            markers = [...schoolMarkers, ...provinceLabels];
          } else {
            // Level 3: School view only
            markers = schoolMarkers;
          }
        }

        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              final camera = _mapController.camera;
              final zoomChange = -pointerSignal.scrollDelta.dy / 250;
              final newZoom = (camera.zoom + zoomChange).clamp(5.0, 18.0);
              _mapController.move(camera.center, newZoom);
            }
          },
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _vietnamCenter,
              initialZoom: _defaultZoom,
              minZoom: 5.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(6.0, 101.0),
                  const LatLng(24.0, 118.0),
                ),
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (camera, hasGesture) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final newBounds = camera.visibleBounds;
                    final newZoom = camera.zoom;
                    if (_visibleBounds == null ||
                        _visibleBounds!.northEast != newBounds.northEast ||
                        _visibleBounds!.southWest != newBounds.southWest ||
                        _currentZoom != newZoom) {
                      setState(() {
                        _visibleBounds = newBounds;
                        _currentZoom = newZoom;
                      });
                    }
                  }
                });
              },
              onTap: (tapPosition, point) {
                if (_currentZoom < 7.0) {
                  // Check region boundaries (click inside any of its provinces)
                  for (final region in regionsList) {
                    for (final provName in region.provinces) {
                      final rings = _provinceBoundaries[normalizeProvinceName(provName)];
                      if (rings != null) {
                        for (final ring in rings) {
                          if (isPointInPolygon(point, ring)) {
                            _mapController.move(region.center, 8.0);
                            return;
                          }
                        }
                      }
                    }
                  }
                } else if (_currentZoom < 9.5) {
                  // Check province boundaries
                  for (final prov in provincesStatsList) {
                    final rings = _provinceBoundaries[prov.name];
                    if (rings != null) {
                      for (final ring in rings) {
                        if (isPointInPolygon(point, ring)) {
                          _mapController.move(prov.center, 11.0);
                          return;
                        }
                      }
                    }
                  }
                }
                
                // Deselect if tapping the map empty space
                ref.read(selectedSchoolIdProvider.notifier).state = null;
                ref.read(schoolSearchQueryProvider.notifier).state = '';
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.vn_map_app',
              ),
              if (mapPolygons.isNotEmpty)
                PolygonLayer(polygons: mapPolygons),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: const Color(0xFF0F766E),
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Lỗi tải bản đồ trường học: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

// ==========================================
// THUẬT TOÁN ĐA GIÁC LỒI (CONVEX HULL) & KIỂM TRA ĐIỂM TRONG ĐA GIÁC (RAY CASTING)
// ==========================================

/// Tìm đa giác lồi nhỏ nhất bao quanh danh sách các điểm (Thuật toán Andrew's Monotone Chain)
List<LatLng> calculateConvexHull(List<LatLng> points) {
  if (points.length < 3) return points;

  // Sắp xếp các điểm theo thứ tự longitude trước, sau đó là latitude
  final sorted = List<LatLng>.from(points)
    ..sort((a, b) {
      if (a.longitude != b.longitude) {
        return a.longitude.compareTo(b.longitude);
      }
      return a.latitude.compareTo(b.latitude);
    });

  final lower = <LatLng>[];
  for (final p in sorted) {
    while (lower.length >= 2 &&
        _crossProduct(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }

  final upper = <LatLng>[];
  for (final p in sorted.reversed) {
    while (upper.length >= 2 &&
        _crossProduct(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }

  lower.removeLast();
  upper.removeLast();

  return [...lower, ...upper];
}

double _crossProduct(LatLng o, LatLng a, LatLng b) {
  return (a.longitude - o.longitude) * (b.latitude - o.latitude) -
      (a.latitude - o.latitude) * (b.longitude - o.longitude);
}

/// Kiểm tra một điểm có nằm trong đa giác hay không (Thuật toán Ray Casting)
bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  if (polygon.isEmpty) return false;
  int i;
  int j = polygon.length - 1;
  bool oddNodes = false;
  final x = point.longitude;
  final y = point.latitude;

  for (i = 0; i < polygon.length; i++) {
    if ((polygon[i].latitude < y && polygon[j].latitude >= y ||
            polygon[j].latitude < y && polygon[i].latitude >= y) &&
        (polygon[i].longitude +
                (y - polygon[i].latitude) /
                    (polygon[j].latitude - polygon[i].latitude) *
                    (polygon[j].longitude - polygon[i].longitude) <
            x)) {
      oddNodes = !oddNodes;
    }
    j = i;
  }
  return oddNodes;
}

List<List<LatLng>> parseGeoJsonGeometry(Map<String, dynamic> geometry) {
  final type = geometry['type'] as String;
  final coordinates = geometry['coordinates'] as List<dynamic>;
  final result = <List<LatLng>>[];

  if (type == 'Polygon') {
    for (final ring in coordinates) {
      final points = <LatLng>[];
      for (final coord in ring) {
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        points.add(LatLng(lat, lon));
      }
      if (points.isNotEmpty) result.add(points);
    }
  } else if (type == 'MultiPolygon') {
    for (final polygon in coordinates) {
      for (final ring in polygon) {
        final points = <LatLng>[];
        for (final coord in ring) {
          final lon = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          points.add(LatLng(lat, lon));
        }
        if (points.isNotEmpty) result.add(points);
      }
    }
  }
  return result;
}

class GeoJsonParseTask {
  final String jsonStr;
  GeoJsonParseTask({required this.jsonStr});
}

class GeoJsonParseResult {
  final Map<String, List<List<LatLng>>> boundaries;
  GeoJsonParseResult({required this.boundaries});
}

GeoJsonParseResult parseGeoJsonIsolate(GeoJsonParseTask task) {
  final data = json.decode(task.jsonStr) as Map<String, dynamic>;
  final features = data['features'] as List<dynamic>;
  final parsed = <String, List<List<LatLng>>>{};

  for (final feature in features) {
    final props = feature['properties'] as Map<String, dynamic>;
    final name = props['name'] as String;
    final normalizedName = normalizeProvinceName(name);
    
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final polygonRings = parseGeoJsonGeometry(geometry);
    
    if (!parsed.containsKey(normalizedName)) {
      parsed[normalizedName] = [];
    }
    parsed[normalizedName]!.addAll(polygonRings);
  }
  return GeoJsonParseResult(boundaries: parsed);
}
