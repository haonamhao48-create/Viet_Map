import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/screens/travel_places_screen.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // Add isCommuneMode to TravelPlacesScreen
  content = content.replaceFirst(
'''class TravelPlacesScreen extends StatefulWidget {
  const TravelPlacesScreen({
    super.key,
    required this.province,
  });

  final ProvinceModel province;''',
'''class TravelPlacesScreen extends StatefulWidget {
  const TravelPlacesScreen({
    super.key,
    required this.province,
    this.isCommuneMode = false,
  });

  final ProvinceModel province;
  final bool isCommuneMode;'''
  );

  // Update AppBar title
  content = content.replaceFirst(
'''        title: Text('Bản đồ phượt \${widget.province.displayName}'),''',
'''        title: Text(widget.isCommuneMode ? 'Bản đồ xã/phường \${widget.province.displayName}' : 'Bản đồ phượt \${widget.province.displayName}'),'''
  );

  // In build method, conditionally render panels and pass isCommuneMode
  content = content.replaceFirst(
'''            children: [
              SizedBox(
                width: 360,
                child: _PlacesSidePanel(
                  province: widget.province,
                  places: visiblePlaces,
                  selectedPlace: _selectedPlace,
                  routePlaces: _routePlaces,
                  onPlaceSelected: _selectPlace,
                  onRouteToggle: _toggleRoutePlace,
                ),
              ),
              Expanded(
                child: _TravelMapView(
                  province: widget.province,
                  places: visiblePlaces,
                  communes: widget.communes,
                  selectedPlace: _selectedPlace,
                  selectedCommune: _selectedCommune,
                  routePlaces: _routePlaces,
                  showPlacesOnMap: _showPlacesOnMap,
                  onPlaceSelected: _selectPlace,
                  onRouteToggle: _toggleRoutePlace,
                  onCommuneSelected: _selectCommune,
                  onTogglePlacesOnMap: () {
                    setState(() {
                      _showPlacesOnMap = !_showPlacesOnMap;
                    });
                  },
                ),
              ),
            ],''',
'''            children: [
              SizedBox(
                width: 360,
                child: widget.isCommuneMode 
                  ? _CommunesSidePanel(
                      province: widget.province,
                      communes: widget.communes,
                      selectedCommune: _selectedCommune,
                      onCommuneSelected: _selectCommune,
                    )
                  : _PlacesSidePanel(
                      province: widget.province,
                      places: visiblePlaces,
                      selectedPlace: _selectedPlace,
                      routePlaces: _routePlaces,
                      onPlaceSelected: _selectPlace,
                      onRouteToggle: _toggleRoutePlace,
                    ),
              ),
              Expanded(
                child: _TravelMapView(
                  province: widget.province,
                  places: widget.isCommuneMode ? [] : visiblePlaces,
                  communes: widget.isCommuneMode ? widget.communes : [],
                  selectedPlace: _selectedPlace,
                  selectedCommune: _selectedCommune,
                  routePlaces: _routePlaces,
                  showPlacesOnMap: _showPlacesOnMap,
                  onPlaceSelected: _selectPlace,
                  onRouteToggle: _toggleRoutePlace,
                  onCommuneSelected: _selectCommune,
                  onTogglePlacesOnMap: () {
                    setState(() {
                      _showPlacesOnMap = !_showPlacesOnMap;
                    });
                  },
                ),
              ),
            ],'''
  );

  // Same for mobile layout
  content = content.replaceFirst(
'''          child: _TravelMapView(
            province: widget.province,
            places: visiblePlaces,
            communes: widget.communes,
            selectedPlace: _selectedPlace,
            selectedCommune: _selectedCommune,
            routePlaces: _routePlaces,
            showPlacesOnMap: _showPlacesOnMap,
            onPlaceSelected: _selectPlace,
            onRouteToggle: _toggleRoutePlace,
            onCommuneSelected: _selectCommune,
            onTogglePlacesOnMap: () {
              setState(() {
                _showPlacesOnMap = !_showPlacesOnMap;
              });
            },
          ),''',
'''          child: _TravelMapView(
            province: widget.province,
            places: widget.isCommuneMode ? [] : visiblePlaces,
            communes: widget.isCommuneMode ? widget.communes : [],
            selectedPlace: _selectedPlace,
            selectedCommune: _selectedCommune,
            routePlaces: _routePlaces,
            showPlacesOnMap: _showPlacesOnMap,
            onPlaceSelected: _selectPlace,
            onRouteToggle: _toggleRoutePlace,
            onCommuneSelected: _selectCommune,
            onTogglePlacesOnMap: () {
              setState(() {
                _showPlacesOnMap = !_showPlacesOnMap;
              });
            },
          ),'''
  );

  // Add _CommunesSidePanel
  content += '''

class _CommunesSidePanel extends StatelessWidget {
  const _CommunesSidePanel({
    required this.province,
    required this.communes,
    required this.selectedCommune,
    required this.onCommuneSelected,
  });

  final ProvinceModel province;
  final List<_CommuneArea> communes;
  final _CommuneArea? selectedCommune;
  final ValueChanged<_CommuneArea> onCommuneSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết Xã/Phường',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    province.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\${communes.length} đơn vị hành chính',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final commune = communes[index];
                  final isSelected = selectedCommune?.name == commune.name;

                  return _CommuneListTile(
                    index: index + 1,
                    commune: commune,
                    isSelected: isSelected,
                    onTap: () => onCommuneSelected(commune),
                  );
                },
                childCount: communes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommuneListTile extends StatelessWidget {
  const _CommuneListTile({
    required this.index,
    required this.commune,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final _CommuneArea commune;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? Colors.teal : Colors.transparent;
    final backgroundColor = isSelected
        ? Colors.teal.withValues(alpha: 0.10)
        : const Color(0xFFF5FAFA);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected ? Colors.teal : Colors.grey.shade400,
                  child: Text(
                    '\$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    commune.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.teal.shade900 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
''';

  file.writeAsStringSync(content);
}
