import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
    "import '../../data/models/tourism_destination_model.dart';",
    "import '../../data/models/tourism_destination_model.dart';\nimport '../../data/models/commune_model.dart';"
  );

  content = content.replaceFirst(
    "final hoveredId = ref.watch(hoveredProvinceIdProvider);",
    "final hoveredId = ref.watch(hoveredProvinceIdProvider);\n    final hoveredCommuneId = ref.watch(hoveredCommuneIdProvider);"
  );

  content = content.replaceFirst(
    "selectedRegion != null;",
    "selectedRegion != null;\n\n    final communesAsync = selectedId != null ? ref.watch(communesByProvinceProvider(selectedId)) : null;\n    final communes = communesAsync?.valueOrNull ?? [];"
  );

  content = content.replaceFirst(
    "final featuredPlacesFuture = _tourismFuture;",
    "final featuredPlacesFuture = _tourismFuture;\n            final renderCommunes = ProvinceMapScene.projectCommunes(communes, scene);"
  );

  content = content.replaceFirst(
    "ref.read(hoveredProvinceIdProvider.notifier).state = null;",
    "ref.read(hoveredProvinceIdProvider.notifier).state = null;\n                ref.read(hoveredCommuneIdProvider.notifier).state = null;"
  );

  content = content.replaceFirst(
    "colorScheme: Theme.of(context).colorScheme,",
    "colorScheme: Theme.of(context).colorScheme,\n                                communes: renderCommunes,\n                                hoveredCommuneId: hoveredCommuneId,"
  );

  content = content.replaceFirst(
    "required this.selectedRegionFilter,",
    "required this.selectedRegionFilter,\n    required this.communes,\n    required this.hoveredCommuneId,"
  );

  content = content.replaceFirst(
    "final String? selectedRegionFilter;",
    "final String? selectedRegionFilter;\n  final List<CommuneRenderData> communes;\n  final String? hoveredCommuneId;"
  );

  content = content.replaceFirst(
    "required this.provinceById,",
    "required this.provinceById,\n    required this.minLon,\n    required this.maxLat,\n    required this.scale,\n    required this.padding,\n    required this.translation,"
  );

  content = content.replaceFirst(
    "final Map<String, ProvinceRenderData> provinceById;",
    "final Map<String, ProvinceRenderData> provinceById;\n  final double minLon;\n  final double maxLat;\n  final double scale;\n  final double padding;\n  final Offset translation;"
  );

  // First empty return
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

  // Second empty return
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

  // Main return
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

  // Append projectCommunes exactly before `class _StagedProvinceRenderData`
  content = content.replaceFirst(
    "\n}\n\nclass _StagedProvinceRenderData {",
    '''
  static List<CommuneRenderData> projectCommunes(
    List<CommuneModel> communes,
    ProvinceMapScene scene,
  ) {
    if (communes.isEmpty) return [];

    final result = <CommuneRenderData>[];
    for (final commune in communes) {
      final paths = <ProvincePathData>[];
      Rect? communeBounds;

      for (final polygon in commune.polygons) {
        final path = Path();
        for (final ring in polygon.rings) {
          bool first = true;
          for (final coord in ring) {
            final x = (coord.longitude - scene.minLon) * scene.scale;
            final y = (scene.maxLat - coord.latitude) * scene.scale;

            if (first) {
              path.moveTo(x, y);
              first = false;
            } else {
              path.lineTo(x, y);
            }
          }
          path.close();
        }

        final shiftedPath = path.shift(scene.translation);
        final bounds = shiftedPath.getBounds();

        paths.add(ProvincePathData(path: shiftedPath, hitBounds: bounds));

        if (communeBounds == null) {
          communeBounds = bounds;
        } else {
          communeBounds = communeBounds.expandToInclude(bounds);
        }
      }

      result.add(CommuneRenderData(
        commune: commune,
        paths: paths,
        bounds: communeBounds ?? Rect.zero,
      ));
    }
    return result;
  }
}

class _StagedProvinceRenderData {'''
  );

  // Append new classes at the end
  content += '''

class ProvincePathData {
  final Path path;
  final Rect hitBounds;

  const ProvincePathData({
    required this.path,
    required this.hitBounds,
  });
}

class CommuneRenderData {
  final CommuneModel commune;
  final List<ProvincePathData> paths;
  final Rect bounds;

  const CommuneRenderData({
    required this.commune,
    required this.paths,
    required this.bounds,
  });
}
''';

  file.writeAsStringSync(content);
}
