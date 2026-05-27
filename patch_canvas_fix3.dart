import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
      "final renderCommunes = _StagedProvinceRenderData.projectCommunes(communes, scene);",
      "final renderCommunes = _projectCommunes(communes, scene);"
  );

  file.writeAsStringSync(content);
}
