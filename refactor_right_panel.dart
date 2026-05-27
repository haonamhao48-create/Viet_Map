import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/screens/travel_places_screen.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // 1. Replace the right side panel logic in build()
  content = content.replaceFirst(
'''              if (!widget.isCommuneMode)
                SizedBox(
                  width: 360,
                  child: _SelectedPlaceDetailPanel(
                    place: _selectedPlace,
                    isInRoute: _selectedPlace != null && _isInRoute(_selectedPlace!),
                    routePlaces: _routePlaces,
                    onRouteToggle: _selectedPlace != null
                        ? () => _toggleRoutePlace(_selectedPlace!)
                        : null,
                    onRemoveRoutePlace: _removeRoutePlace,
                    onClearRoute: _clearRoute,
                  ),
                ),''',
'''              SizedBox(
                width: 360,
                child: widget.isCommuneMode
                    ? _SelectedCommuneDetailPanel(commune: _selectedCommune)
                    : _SelectedPlaceDetailPanel(
                        place: _selectedPlace,
                        isInRoute: _selectedPlace != null && _isInRoute(_selectedPlace!),
                        routePlaces: _routePlaces,
                        onRouteToggle: _selectedPlace != null
                            ? () => _toggleRoutePlace(_selectedPlace!)
                            : null,
                        onRemoveRoutePlace: _removeRoutePlace,
                        onClearRoute: _clearRoute,
                      ),
              ),'''
  );

  // 2. Remove showModalBottomSheet from _TravelMapView
  content = content.replaceFirst(
'''              if (commune != null) {
                onCommuneSelected(commune);

                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (_) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: _CommuneDetail(commune: commune),
                    );
                  },
                );
              }''',
'''              if (commune != null) {
                onCommuneSelected(commune);
              }'''
  );

  // 3. Add _SelectedCommuneDetailPanel at the end of the file
  content += '''

class _SelectedCommuneDetailPanel extends StatelessWidget {
  const _SelectedCommuneDetailPanel({
    required this.commune,
  });

  final _CommuneArea? commune;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: commune == null
                  ? Text(
                      'Chọn một đơn vị hành chính trên bản đồ hoặc trong danh sách để xem chi tiết.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    )
                  : _CommuneDetail(commune: commune!),
            ),
          ),
        ],
      ),
    );
  }
}
''';

  file.writeAsStringSync(content);
}
