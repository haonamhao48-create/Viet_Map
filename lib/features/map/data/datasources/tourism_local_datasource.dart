import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/tourism_destination_model.dart';

class TourismLocalDataSource {
  Future<List<TourismDestinationModel>> loadDestinations() async {
    try {
      final rawString = await rootBundle.loadString(
        'assets/data/tourism_destinations.json',
      );
      return compute(parseDestinations, rawString);
    } catch (_) {
      // Backward-compatible fallback for old compact dataset.
      final compactRawString = await rootBundle.loadString(
        'assets/data/tourism_destinations_compact.json',
      );
      return compute(parseDestinations, compactRawString);
    }
  }
}

@pragma('vm:entry-point')
List<TourismDestinationModel> parseDestinations(String rawString) {
  final decoded = jsonDecode(rawString);
  if (decoded is! List) {
    return const [];
  }

  final result = <TourismDestinationModel>[];
  for (final item in decoded) {
    if (item is Map<String, dynamic>) {
      result.add(TourismDestinationModel.fromJson(item));
      continue;
    }
    if (item is List<dynamic>) {
      result.add(TourismDestinationModel.fromCompactJsonRow(item));
    }
  }

  return result;
}
