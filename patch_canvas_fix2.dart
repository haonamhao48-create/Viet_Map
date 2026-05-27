import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

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
  
  // Fix projectCommunes error:
  content = content.replaceFirst(
      "final renderCommunes = ProvinceMapScene.projectCommunes(communes, scene);",
      "final renderCommunes = _StagedProvinceRenderData.projectCommunes(communes, scene);"
  );

  // Rename method inside ProvinceMapCanvas since we injected it at the end of _StagedProvinceRenderData... wait, where did we inject it?
  // In `patch_canvas_final3.dart`, it was injected into _StagedProvinceRenderData class? No, let's see.
  // Actually, I can just change it to be a static method of ProvinceMapScene.
  content = content.replaceFirst(
      "static List<CommuneRenderData> projectCommunes(",
      "static List<CommuneRenderData> projectCommunes("
  ); // Wait, where did I inject it in final3? Let me find `static List<CommuneRenderData> projectCommunes` and move it to `ProvinceMapScene` if it's not there.
  
  // To make sure it's inside ProvinceMapScene, let's just make it a global function or something?
  // Let's replace `ProvinceMapScene.projectCommunes` with just `_projectCommunes`.
  content = content.replaceAll(
      "ProvinceMapScene.projectCommunes",
      "_projectCommunes"
  );
  content = content.replaceAll(
      "static List<CommuneRenderData> projectCommunes(",
      "List<CommuneRenderData> _projectCommunes("
  );
  
  file.writeAsStringSync(content);
}
