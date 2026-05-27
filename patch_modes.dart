import 'dart:io';

void main() {
  patchProvinceProvider();
  patchMapExplorerPanel();
  patchProvinceMapCanvas();
}

void patchProvinceProvider() {
  final file = File('lib/features/map/presentation/providers/province_provider.dart');
  var content = file.readAsStringSync();

  if (!content.contains('final communeModeProvider')) {
    content += '\nfinal communeModeProvider = StateProvider<bool>((ref) => false);\n';
    file.writeAsStringSync(content);
  }
}

void patchMapExplorerPanel() {
  final file = File('lib/features/map/presentation/widgets/map_explorer_panel.dart');
  var content = file.readAsStringSync();

  // Add communeMode
  if (!content.contains('final communeMode = ref.watch(communeModeProvider);')) {
    content = content.replaceFirst(
      'final featuredTravelMode = ref.watch(featuredTravelModeProvider);',
      'final featuredTravelMode = ref.watch(featuredTravelModeProvider);\n    final communeMode = ref.watch(communeModeProvider);'
    );
  }

  // Add ActionChip
  if (!content.contains('Chi tiết xã/phường')) {
    content = content.replaceFirst(
'''        ActionChip(
          avatar: const Icon(Icons.compare_arrows_rounded, size: 18),''',
'''        ActionChip(
          avatar: Icon(
            communeMode
                ? Icons.map_rounded
                : Icons.layers_rounded,
            size: 18,
          ),
          label: Text(
            communeMode ? 'Tắt chi tiết xã' : 'Chi tiết xã/phường',
          ),
          onPressed: () {
            final nextMode = !communeMode;
            ref.read(communeModeProvider.notifier).state = nextMode;

            if (nextMode) {
              ref.read(featuredTravelModeProvider.notifier).state = false;
              ref.read(compareModeProvider.notifier).state = false;
            } else {
              ref.read(selectedCommuneIdProvider.notifier).state = null;
            }
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.compare_arrows_rounded, size: 18),'''
    );
  }

  // Disable commune mode when toggling compareMode
  content = content.replaceFirst(
'''            if (!nextMode) {
              ref.read(firstCompareProvinceIdProvider.notifier).state = null;
              ref.read(secondCompareProvinceIdProvider.notifier).state = null;
            } else {
              ref.read(selectedProvinceIdProvider.notifier).state = null;
            }''',
'''            if (!nextMode) {
              ref.read(firstCompareProvinceIdProvider.notifier).state = null;
              ref.read(secondCompareProvinceIdProvider.notifier).state = null;
            } else {
              ref.read(selectedProvinceIdProvider.notifier).state = null;
              ref.read(communeModeProvider.notifier).state = false;
            }'''
  );

  // Disable commune mode when toggling featuredTravelMode
  content = content.replaceFirst(
'''            if (nextMode) {
              ref.read(compareModeProvider.notifier).state = false;''',
'''            if (nextMode) {
              ref.read(compareModeProvider.notifier).state = false;
              ref.read(communeModeProvider.notifier).state = false;'''
  );

  file.writeAsStringSync(content);
}

void patchProvinceMapCanvas() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync();

  if (!content.contains('final communeMode = ref.watch(communeModeProvider);')) {
    content = content.replaceFirst(
      'final featuredTravelMode = ref.watch(featuredTravelModeProvider);',
      'final featuredTravelMode = ref.watch(featuredTravelModeProvider);\n    final communeMode = ref.watch(communeModeProvider);'
    );
  }

  // Update onPointerHover
  content = content.replaceFirst(
    'final communeId = renderCommunes.isNotEmpty ? _communeIdAtPosition(renderCommunes, event.localPosition) : null;',
    'final communeId = (communeMode && renderCommunes.isNotEmpty) ? _communeIdAtPosition(renderCommunes, event.localPosition) : null;'
  );

  // Update onPointerDown (this replaceFirst will apply to the second occurrence, or we can just replace all)
  content = content.replaceAll(
    'final communeId = renderCommunes.isNotEmpty ? _communeIdAtPosition(renderCommunes, event.localPosition) : null;',
    'final communeId = (communeMode && renderCommunes.isNotEmpty) ? _communeIdAtPosition(renderCommunes, event.localPosition) : null;'
  );

  // Update paint method
  content = content.replaceAll(
    'if (renderCommunes.isNotEmpty) {',
    'if (communeMode && renderCommunes.isNotEmpty) {'
  );

  file.writeAsStringSync(content);
}
