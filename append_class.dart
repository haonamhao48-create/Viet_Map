import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  final content = '''

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
  file.writeAsStringSync(content, mode: FileMode.append);
}
