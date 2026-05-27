import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync();

  // 1. Add _communeIdAtPosition
  content = content.replaceFirst(
    "  String? _provinceIdAtPosition(ProvinceMapScene scene, Offset localPosition) {",
    '''  String? _communeIdAtPosition(List<CommuneRenderData> communes, Offset localPosition) {
    if (_viewportSize.isEmpty) return null;
    final scenePoint = _transformationController.toScene(localPosition);

    for (final commune in communes.reversed) {
      if (!commune.bounds.inflate(2).contains(scenePoint)) continue;
      for (final pathData in commune.paths) {
        if (pathData.hitBounds.inflate(2).contains(scenePoint) &&
            pathData.path.contains(scenePoint)) {
          return commune.commune.id;
        }
      }
    }
    return null;
  }

  String? _provinceIdAtPosition(ProvinceMapScene scene, Offset localPosition) {'''
  );

  // 2. Add commune hit-testing in onPointerHover
  content = content.replaceFirst(
    '''                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );
                          final hoveredNotifier = ref.read(
                            hoveredProvinceIdProvider.notifier,
                          );''',
    '''                          final communeId = renderCommunes.isNotEmpty ? _communeIdAtPosition(renderCommunes, event.localPosition) : null;
                          final hoveredCommuneNotifier = ref.read(hoveredCommuneIdProvider.notifier);
                          if (hoveredCommuneNotifier.state != communeId) {
                            hoveredCommuneNotifier.state = communeId;
                          }

                          final provinceId = communeId != null ? selectedId : _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );
                          final hoveredNotifier = ref.read(
                            hoveredProvinceIdProvider.notifier,
                          );'''
  );

  // 3. Add commune hit-testing in onPointerDown
  content = content.replaceFirst(
    '''                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );

                          if (provinceId == null) {''',
    '''                          final communeId = renderCommunes.isNotEmpty ? _communeIdAtPosition(renderCommunes, event.localPosition) : null;
                          if (communeId != null) {
                            ref.read(selectedCommuneIdProvider.notifier).state = communeId;
                            return;
                          } else {
                            ref.read(selectedCommuneIdProvider.notifier).state = null;
                          }

                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );

                          if (provinceId == null) {'''
  );

  file.writeAsStringSync(content);
}
