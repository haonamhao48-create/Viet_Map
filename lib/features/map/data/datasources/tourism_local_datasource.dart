import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tourism_destination_model.dart';

class TourismLocalDataSource {
  Future<List<TourismDestinationModel>> loadDestinations() async {
    final rawString = await rootBundle.loadString(
      'assets/data/tourism_destinations.json',
    );
    final List<dynamic> data = jsonDecode(rawString) as List<dynamic>;

    return data
        .whereType<Map<String, dynamic>>()
        .map(TourismDestinationModel.fromJson)
        .toList(growable: false);
  }
}
