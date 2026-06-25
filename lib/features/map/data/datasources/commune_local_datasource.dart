import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/commune_model.dart';

class CommuneLocalDataSource {
  Future<List<CommuneModel>> loadCommunesForProvinceSlug(String slug) async {
    try {
      final rawString = await rootBundle.loadString(
        'assets/geo/provinces/$slug.geojson',
      );
      return compute(parseCommunesGeoJson, rawString);
    } catch (e) {
      debugPrint('Failed to load communes for province slug $slug: $e');
      return [];
    }
  }
}

@pragma('vm:entry-point')
List<CommuneModel> parseCommunesGeoJson(String rawString) {
  try {
    final fixedString = rawString.replaceAll(': NaN', ': null');
    final data = jsonDecode(fixedString) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>? ?? [];

    return features
        .whereType<Map<String, dynamic>>()
        .map(CommuneModel.fromGeoJsonFeature)
        .toList(growable: false);
  } catch (e) {
    debugPrint('Error parsing communes geojson: $e');
    return [];
  }
}
