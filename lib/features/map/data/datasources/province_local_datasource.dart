import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/province_model.dart';

class ProvinceLocalDataSource {
  Future<List<ProvinceModel>> loadProvinces() async {
    final rawString = await rootBundle.loadString(
      'assets/geo/vietnam_complete.geojson',
    );

    final cleanedString = rawString
        .replaceAll(': NaN', ': null')
        .replaceAll(':NaN', ':null')
        .replaceAll('[NaN', '[null')
        .replaceAll(', NaN', ', null')
        .replaceAll(',NaN', ',null');

    final Map<String, dynamic> data = jsonDecode(cleanedString);
    final List features = data['features'] as List;

    return features
        .map((feature) => ProvinceModel.fromGeoJsonFeature(feature))
        .toList();
  }
}
