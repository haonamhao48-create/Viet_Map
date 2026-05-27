import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync();

  // 1. Add CommuneModel import
  if (!content.contains("import '../../data/models/commune_model.dart';")) {
    content = content.replaceFirst(
      "import '../../data/models/tourism_destination_model.dart';",
      "import '../../data/models/tourism_destination_model.dart';\nimport '../../data/models/commune_model.dart';"
    );
  }

  // 2. Fix ProvinceMapScene empty return
  content = content.replaceAll('''
      return ProvinceMapScene(
        viewportSize: viewportSize,
        canvasSize: viewportSize,
        renderProvinces: const [],
        provinceById: const {},
      );''', '''
      return ProvinceMapScene(
        viewportSize: viewportSize,
        canvasSize: viewportSize,
        renderProvinces: const [],
        provinceById: const {},
        minLon: 0,
        maxLat: 0,
        scale: 1,
        padding: padding,
        translation: Offset.zero,
      );''');

  // 3. Remove isTinyInteractive
  content = content.replaceAll(
    'isTinyInteractive: stagedProvince.isTinyInteractive,',
    ''
  );

  // 4. Add ProvincePathData at the bottom
  if (!content.contains('class ProvincePathData')) {
    content += '''

class ProvincePathData {
  final Path path;
  final Rect hitBounds;

  const ProvincePathData({
    required this.path,
    required this.hitBounds,
  });
}
''';
  }

  file.writeAsStringSync(content);
}
