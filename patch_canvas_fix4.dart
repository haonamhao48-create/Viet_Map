import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync();

  if (!content.contains('_projectCommunes(List<CommuneModel> communes, ProvinceMapScene scene)')) {
    content += '''

List<CommuneRenderData> _projectCommunes(List<CommuneModel> communes, ProvinceMapScene scene) {
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
''';
  }

  file.writeAsStringSync(content);
}
