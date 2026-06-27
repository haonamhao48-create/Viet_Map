import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/province_geo_asset.dart';
import '../../data/datasources/commune_local_datasource.dart';
import '../../data/datasources/tourism_local_datasource.dart';
import '../../data/datasources/high_school_firestore_datasource.dart';
import '../../data/models/commune_model.dart';
import '../../data/models/high_school_model.dart';
import '../../data/models/province_model.dart';
import '../../data/models/tourism_destination_model.dart';
import '../../../school_visits/presentation/widgets/school_visit_notes_section.dart';

part 'travel_map_models.dart';
part 'travel_map_view.dart';
part 'travel_map_painter.dart';
part 'travel_place_widgets.dart';
part 'travel_commune_widgets.dart';

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
  final CommuneLocalDataSource _communeDataSource = CommuneLocalDataSource();

  static final Map<String, List<_CommuneArea>> _parsedCommunesCache = {};

  @override
  void initState() {
    super.initState();
    _mapDataFuture = _loadMapData();
  }

  Future<List<TourismDestinationModel>> _loadPlaces() async {
    final allPlaces = await TourismLocalDataSource().loadDestinations();

    final selectedProvince = provinceGeoAssetSlug(widget.province.displayName);

    return allPlaces.where((place) {
      final placeProvince = provinceGeoAssetSlug(place.province);
      return placeProvince == selectedProvince;
    }).toList(growable: false);
  }

  Future<_TravelMapData> _loadMapData() async {
    final communes = await _loadCommunes();
    final places =
        widget.isCommuneMode ? const <TourismDestinationModel>[] : await _loadPlaces();
    return _TravelMapData(places: places, communes: communes);
  }

  Future<List<_CommuneArea>> _loadCommunes() async {
    final slug = provinceGeoAssetSlug(widget.province.displayName);

    if (_parsedCommunesCache.containsKey(slug)) {
      return _parsedCommunesCache[slug]!;
    }

    try {
      final models = await _communeDataSource
          .loadCommunesForProvinceSlug(slug)
          .timeout(const Duration(minutes: 2));
      final parsed =
          models.map(communeAreaFromModel).toList(growable: false);
      _parsedCommunesCache[slug] = parsed;
      return parsed;
    } on TimeoutException {
      throw Exception(
        'Tải dữ liệu xã/phường quá lâu. Vui lòng thử lại sau.',
      );
    } catch (e) {
      debugPrint(
        'Không tìm thấy dữ liệu xã/phường cho ${widget.province.displayName}: $e',
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TravelMapData>(
      future: _mapDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF9F8),
            appBar: AppBar(
              title: Text(widget.isCommuneMode ? 'Bản đồ xã/phường ${widget.province.displayName}' : 'Bản đồ phượt ${widget.province.displayName}'),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF9F8),
            appBar: AppBar(
              title: Text(widget.isCommuneMode ? 'Bản đồ xã/phường ${widget.province.displayName}' : 'Bản đồ phượt ${widget.province.displayName}'),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
            ),
          );
        }

        final mapData = snapshot.data;
        final places = mapData?.places ?? [];
        final communes = mapData?.communes ?? [];

        if (places.isEmpty && !widget.isCommuneMode) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF9F8),
            appBar: AppBar(
              title: Text('Bản đồ phượt ${widget.province.displayName}'),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Text(
                'Chưa có địa điểm phượt cho ${widget.province.displayName}',
              ),
            ),
          );
        }

        if (widget.isCommuneMode && communes.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF9F8),
            appBar: AppBar(
              title: Text('Bản đồ xã/phường ${widget.province.displayName}'),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Text(
                'Không có dữ liệu xã/phường cho ${widget.province.displayName}',
              ),
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
    );
  }
}
