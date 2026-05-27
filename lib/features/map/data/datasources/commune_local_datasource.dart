import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/commune_model.dart';

class CommuneLocalDataSource {
  Future<List<CommuneModel>> loadCommunesForProvince(String provinceId) async {
    try {
      final rawString = await rootBundle.loadString(
        'assets/geo/provinces/$provinceId.geojson',
      );
      return compute(_parseCommunesGeoJson, rawString);
    } catch (e) {
      // If file doesn't exist for this province or failed to load
      debugPrint('Failed to load communes for province $provinceId: $e');
      return [];
    }
  }
}

List<CommuneModel> _parseCommunesGeoJson(String rawString) {
  try {
    final data = jsonDecode(rawString) as Map<String, dynamic>;
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
