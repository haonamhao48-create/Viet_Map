import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/tourism_destination_model.dart';

class TourismLocalDataSource {
  Future<List<TourismDestinationModel>> loadDestinations() async {
    final rawString = await rootBundle.loadString(
      'assets/data/tourism_destinations_compact.json',
    );
    return compute(_parseCompactDestinations, rawString);
  }
}

List<TourismDestinationModel> _parseCompactDestinations(String rawString) {
  final rows = jsonDecode(rawString) as List<dynamic>;

  return rows
      .whereType<List<dynamic>>()
      .map(TourismDestinationModel.fromCompactJsonRow)
      .toList(growable: false);
}
