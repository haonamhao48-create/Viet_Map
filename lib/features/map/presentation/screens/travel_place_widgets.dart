part of 'travel_places_screen.dart';

/// Sidebar danh sách địa điểm phượt.
class _PlacesSidePanel extends StatelessWidget {
  const _PlacesSidePanel({
    required this.province,
    required this.places,
    required this.selectedPlace,
    required this.routePlaces,
    required this.onPlaceSelected,
    required this.onRouteToggle,
  });

  final ProvinceModel province;
  final List<TourismDestinationModel> places;
  final TourismDestinationModel? selectedPlace;
  final ValueChanged<TourismDestinationModel> onPlaceSelected;
  final List<TourismDestinationModel> routePlaces;
  final ValueChanged<TourismDestinationModel> onRouteToggle;

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
                    'Địa điểm phượt',
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
                    '${places.length} địa điểm nổi bật',
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
                  final place = places[index];
                  final isSelected = selectedPlace?.name == place.name;
                  final isInRoute =
                      routePlaces.any((item) => item.name == place.name);

                  return _PlaceListTile(
                    index: index + 1,
                    place: place,
                    isSelected: isSelected,
                    isInRoute: isInRoute,
                    onTap: () => onPlaceSelected(place),
                    onRouteToggle: () => onRouteToggle(place),
                  );
                },
                childCount: places.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile trong danh sách địa điểm.
class _PlaceListTile extends StatelessWidget {
  const _PlaceListTile({
    required this.index,
    required this.place,
    required this.isSelected,
    required this.isInRoute,
    required this.onTap,
    required this.onRouteToggle,
  });

  final int index;
  final TourismDestinationModel place;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isInRoute;
  final VoidCallback onRouteToggle;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? Colors.teal : Colors.transparent;
    final backgroundColor = isSelected
        ? Colors.teal.withValues(alpha: 0.10)
        : const Color(0xFFF5FAFA);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.teal,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (place.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          place.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (place.keywords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: place.keywords.take(3).map((keyword) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                keyword,
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip:
                      isInRoute ? 'Bỏ khỏi lộ trình' : 'Thêm vào lộ trình',
                  onPressed: onRouteToggle,
                  icon: Icon(
                    isInRoute
                        ? Icons.remove_road_rounded
                        : Icons.add_road_rounded,
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

/// Panel chi tiết địa điểm + lộ trình phượt.
class _SelectedPlaceDetailPanel extends StatelessWidget {
  const _SelectedPlaceDetailPanel({
    required this.place,
    required this.isInRoute,
    required this.routePlaces,
    required this.onRouteToggle,
    required this.onRemoveRoutePlace,
    required this.onClearRoute,
  });

  final TourismDestinationModel? place;
  final bool isInRoute;
  final List<TourismDestinationModel> routePlaces;
  final VoidCallback? onRouteToggle;
  final ValueChanged<TourismDestinationModel> onRemoveRoutePlace;
  final VoidCallback onClearRoute;

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
              child: place == null
                  ? Text(
                      'Chọn một địa điểm trên bản đồ hoặc trong danh sách để xem chi tiết.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PlaceDetail(place: place!),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onRouteToggle,
                            icon: Icon(
                              isInRoute
                                  ? Icons.remove_road_rounded
                                  : Icons.add_road_rounded,
                            ),
                            label: Text(
                              isInRoute
                                  ? 'Bỏ khỏi lộ trình'
                                  : 'Thêm vào lộ trình',
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lộ trình phượt',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (routePlaces.isNotEmpty)
                    TextButton(
                      onPressed: onClearRoute,
                      child: const Text('Xóa tất cả'),
                    ),
                ],
              ),
            ),
          ),
          if (routePlaces.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FAFA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Chưa có địa điểm nào trong lộ trình. Hãy thêm vài điểm muốn ghé.',
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final routePlace = routePlaces[index];
                    return _RoutePlaceTile(
                      index: index + 1,
                      place: routePlace,
                      onRemove: () => onRemoveRoutePlace(routePlace),
                    );
                  },
                  childCount: routePlaces.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tile trong lộ trình phượt.
class _RoutePlaceTile extends StatelessWidget {
  const _RoutePlaceTile({
    required this.index,
    required this.place,
    required this.onRemove,
  });

  final int index;
  final TourismDestinationModel place;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.orange,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              place.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Xóa khỏi lộ trình',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// Marker địa điểm trên bản đồ.
class _PlaceBubble extends StatelessWidget {
  const _PlaceBubble({
    required this.index,
    required this.place,
    required this.isSelected,
    required this.showLabel,
    required this.onTap,
    required this.isInRoute,
    required this.onRouteToggle,
  });

  final int index;
  final TourismDestinationModel place;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback onTap;
  final bool isInRoute;
  final VoidCallback onRouteToggle;

  @override
  Widget build(BuildContext context) {
    const pinWidth = 34.0;
    const pinHeight = 42.0;
    const labelMaxWidth = 230.0;

    return Tooltip(
      message: place.description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: SizedBox(
            width: pinWidth,
            height: pinHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _NumberedPin(
                  index: index,
                  isSelected: isSelected,
                  isInRoute: isInRoute,
                ),
                if (showLabel)
                  Positioned(
                    top: pinHeight + 6,
                    left: -(labelMaxWidth - pinWidth) / 2,
                    width: labelMaxWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.55),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                isSelected ? Colors.white : Colors.teal,
                            child: Text(
                              '$index',
                              style: TextStyle(
                                color: isSelected ? Colors.teal : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              place.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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

class _NumberedPin extends StatelessWidget {
  const _NumberedPin({
    required this.index,
    required this.isSelected,
    required this.isInRoute,
  });

  final int index;
  final bool isSelected;
  final bool isInRoute;

  @override
  Widget build(BuildContext context) {
    final pinColor = isSelected
        ? Colors.teal
        : (isInRoute ? Colors.orange : Colors.teal.shade600);

    return SizedBox(
      width: 34,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Icon(
              Icons.location_on_rounded,
              size: 38,
              color: pinColor,
            ),
          ),
          Positioned(
            top: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: TextStyle(
                  color: pinColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget chi tiết địa điểm (tên, mô tả, từ khóa).
class _PlaceDetail extends StatelessWidget {
  const _PlaceDetail({required this.place});

  final TourismDestinationModel place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.place_rounded, color: Colors.teal, size: 36),
        const SizedBox(height: 12),
        Text(
          place.name,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          place.province,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.teal,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Mô tả',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          place.description.isEmpty
              ? 'Chưa có mô tả cho địa điểm này.'
              : place.description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        if (place.keywords.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Từ khóa',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: place.keywords.map((keyword) {
              return Chip(
                label: Text(keyword),
                backgroundColor: Colors.teal.withValues(alpha: 0.10),
                labelStyle: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
