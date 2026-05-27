import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/map_explorer_panel.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // 1. Remove the Chi tiết xã/phường chip
  content = content.replaceFirst(
'''                ChoiceChip(
                  label: Text(communeMode ? 'Tắt chi tiết xã' : 'Chi tiết xã/phường'),
                  selected: communeMode,
                  avatar: const Icon(Icons.map_rounded, size: 18),
                  onSelected: (selected) {
                    final nextMode = selected;
                    ref.read(communeModeProvider.notifier).state = nextMode;

                    if (nextMode) {
                      ref.read(compareModeProvider.notifier).state = false;
                      ref.read(featuredTravelModeProvider.notifier).state = false;
                    } else {
                      ref.read(hoveredCommuneIdProvider.notifier).state = null;
                      ref.read(selectedCommuneIdProvider.notifier).state = null;
                    }
                  },
                ),
                const SizedBox(width: 8),''',
  '');

  // 2. Add the Xem chi tiết xã phường button
  content = content.replaceFirst(
'''          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TravelPlacesScreen(
                      province: province,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('Xem bản đồ phượt'),
            ),
          ),
          const SizedBox(height: 18),''',
'''          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TravelPlacesScreen(
                      province: province,
                      isCommuneMode: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('Xem bản đồ phượt'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TravelPlacesScreen(
                      province: province,
                      isCommuneMode: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('Xem chi tiết xã/phường'),
            ),
          ),
          const SizedBox(height: 18),'''
  );

  file.writeAsStringSync(content);
}
