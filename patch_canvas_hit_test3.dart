import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // 1. Add _communeIdAtPosition
  content = content.replaceFirst(
'''  String? _provinceIdAtPosition(ProvinceMapScene scene, Offset localPosition) {
    if (_viewportSize.isEmpty) {
      return null;
    }''',
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

  String? _provinceIdAtPosition(ProvinceMapScene scene, Offset localPosition) {
    if (_viewportSize.isEmpty) {
      return null;
    }'''
  );

  // 2. Add commune hit-testing in onPointerHover
  content = content.replaceFirst(
'''                        onPointerHover: (event) {
                          if (_shouldSuspendHover()) {
                            return;
                          }
                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );
                          final hoveredNotifier = ref.read(
                            hoveredProvinceIdProvider.notifier,
                          );
                          if (hoveredNotifier.state != provinceId) {
                            hoveredNotifier.state = provinceId;
                          }
                        },''',
'''                        onPointerHover: (event) {
                          if (_shouldSuspendHover()) {
                            return;
                          }
                          
                          final communeId = (communeMode && renderCommunes.isNotEmpty) ? _communeIdAtPosition(renderCommunes, event.localPosition) : null;
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
                          );
                          if (hoveredNotifier.state != provinceId) {
                            hoveredNotifier.state = provinceId;
                          }
                        },'''
  );

  // 3. Add commune hit-testing in onPointerDown
  content = content.replaceFirst(
'''                        onPointerDown: (event) {
                          if (featuredTravelMode) {
                            return;
                          }
                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );

                          if (provinceId == null) {
                            ref
                                    .read(selectedProvinceIdProvider.notifier)
                                    .state =
                                null;
                            return;
                          }''',
'''                        onPointerDown: (event) {
                          if (featuredTravelMode) {
                            return;
                          }
                          
                          final communeId = (communeMode && renderCommunes.isNotEmpty) ? _communeIdAtPosition(renderCommunes, event.localPosition) : null;
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

                          if (provinceId == null) {
                            ref
                                    .read(selectedProvinceIdProvider.notifier)
                                    .state =
                                null;
                            return;
                          }'''
  );

  file.writeAsStringSync(content);
}
