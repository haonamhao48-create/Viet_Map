import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/province_model.dart';

class ProvinceLocalDataSource {
  Future<List<ProvinceModel>> loadProvinces() async {
    final rawString = await rootBundle.loadString(
      'assets/data/provinces_compact.json',
    );
    return compute(_parseCompactProvinces, rawString);
  }
}

List<ProvinceModel> _parseCompactProvinces(String rawString) {
  final rows = jsonDecode(rawString) as List<dynamic>;

  return rows
      .whereType<List<dynamic>>()
      .map(ProvinceModel.fromCompactJsonRow)
      .toList(growable: false);
}
