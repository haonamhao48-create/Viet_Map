import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync();

  // Fix 1
  content = content.replaceFirst(
'''    if (provinces.isEmpty || viewportSize.isEmpty) {
      return ProvinceMapScene(
        viewportSize: viewportSize,
        canvasSize: viewportSize,
        renderProvinces: const [],
        provinceById: const {},
      );
    }''',
'''    if (provinces.isEmpty || viewportSize.isEmpty) {
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
      );
    }'''
  );

  // Fix 2
  content = content.replaceFirst(
'''    if (stagedProvinces.isEmpty ||
        minProjectedX == double.infinity ||
        minProjectedY == double.infinity) {
      return ProvinceMapScene(
        viewportSize: viewportSize,
        canvasSize: viewportSize,
        renderProvinces: const [],
        provinceById: const {},
      );
    }''',
'''    if (stagedProvinces.isEmpty ||
        minProjectedX == double.infinity ||
        minProjectedY == double.infinity) {
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
      );
    }'''
  );

  // Fix 3 (Line 1119 return)
  content = content.replaceFirst(
'''    return ProvinceMapScene(
      viewportSize: viewportSize,
      canvasSize: canvasSize,
      renderProvinces: renderProvinces,
      provinceById: provinceById,
    );
  }

  static Rect _buildArchipelagoHoverRegion''',
'''    return ProvinceMapScene(
      viewportSize: viewportSize,
      canvasSize: canvasSize,
      renderProvinces: renderProvinces,
      provinceById: provinceById,
      minLon: minLon,
      maxLat: maxLat,
      scale: scale,
      padding: padding,
      translation: translation,
    );
  }

  static Rect _buildArchipelagoHoverRegion'''
  );

  file.writeAsStringSync(content);
}
