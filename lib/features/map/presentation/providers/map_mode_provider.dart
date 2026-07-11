import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MapMode {
  vector,
  openStreetMap,
}

final mapModeProvider = StateProvider<MapMode>((ref) => MapMode.vector);
