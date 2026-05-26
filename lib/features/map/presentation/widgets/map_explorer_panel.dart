import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/province_model.dart';
import '../../data/models/tourism_destination_model.dart';
import '../providers/province_provider.dart';
import '../screens/travel_places_screen.dart';

class MapExplorerPanel extends ConsumerStatefulWidget {
  const MapExplorerPanel({
    super.key,
    this.compact = false,
    this.embedded = false,
    this.mobileOverlay = false,
    this.showSelectionCard = true,
    this.scrollController,
  });

  final bool compact;
  final bool embedded;
  final bool mobileOverlay;
  final bool showSelectionCard;
  final ScrollController? scrollController;

  @override
  ConsumerState<MapExplorerPanel> createState() => _MapExplorerPanelState();
}

class _MapExplorerPanelState extends ConsumerState<MapExplorerPanel> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(provinceSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    final selectedProvince = ref.watch(selectedProvinceProvider);
    final selectedProvinceId = ref.watch(selectedProvinceIdProvider);
    final searchQuery = ref.watch(provinceSearchQueryProvider);
    final filteredProvinces = ref.watch(filteredProvincesProvider);
    final theme = Theme.of(context);

    if (_searchController.text != searchQuery) {
      _searchController.value = TextEditingValue(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
      );
    }

    if (widget.mobileOverlay) {
      return _MobileSearchBar(
        controller: _searchController,
        resultCount: filteredProvinces.length,
        onChanged: (value) {
          ref.read(provinceSearchQueryProvider.notifier).state = value;
        },
        onClear: () {
          ref.read(provinceSearchQueryProvider.notifier).state = '';
          ref.read(selectedProvinceIdProvider.notifier).state = null;
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.embedded
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerLowest,
        border: widget.embedded
            ? null
            : Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
      ),
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                widget.embedded ? 12 : 22,
                20,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelHero(
                    compact: widget.compact,
                    filteredCount: filteredProvinces.length,
                    totalCount: provincesAsync.valueOrNull?.length ?? 0,
                  ),
                  const SizedBox(height: 16),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(provinceSearchQueryProvider.notifier).state =
                          value;
                    },
                    onClear: () {
                      ref.read(provinceSearchQueryProvider.notifier).state = '';
                    },
                  ),
                  const SizedBox(height: 12),
                  _PanelHintRow(
                    searchQuery: searchQuery,
                    onResetSelection: () {
                      ref.read(selectedProvinceIdProvider.notifier).state =
                          null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (widget.showSelectionCard && selectedProvince != null) ...[
                    _SelectedProvinceCard(province: selectedProvince),
                    const SizedBox(height: 16),
                  ],
                  _RegionLegend(compact: widget.compact),
                  const SizedBox(height: 16),
                  Text(
                    'Danh sách khu vực',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          provincesAsync.when(
            data: (_) {
              final compareMode = ref.watch(compareModeProvider);
              final firstCompareId = ref.watch(firstCompareProvinceIdProvider);
              final secondCompareId = ref.watch(secondCompareProvinceIdProvider);

              if (filteredProvinces.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptySearchState(query: searchQuery),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final province = filteredProvinces[index];

                    final isSelected = compareMode
                        ? province.id == firstCompareId ||
                        province.id == secondCompareId
                        : province.id == selectedProvinceId;

                    return _ProvinceListTile(
                      province: province,
                      isSelected: isSelected,
                      onTap: () {
                        final compareMode = ref.read(compareModeProvider);

                        if (!compareMode) {
                          ref.read(selectedProvinceIdProvider.notifier).state = province.id;
                          return;
                        }

                        final firstId = ref.read(firstCompareProvinceIdProvider);
                        final secondId = ref.read(secondCompareProvinceIdProvider);

                        if (firstId == province.id) {
                          ref.read(firstCompareProvinceIdProvider.notifier).state = null;
                          return;
                        }

                        if (secondId == province.id) {
                          ref.read(secondCompareProvinceIdProvider.notifier).state = null;
                          return;
                        }

                        if (firstId == null) {
                          ref.read(firstCompareProvinceIdProvider.notifier).state = province.id;
                        } else if (secondId == null) {
                          ref.read(secondCompareProvinceIdProvider.notifier).state = province.id;
                        } else {
                          ref.read(firstCompareProvinceIdProvider.notifier).state = province.id;
                          ref.read(secondCompareProvinceIdProvider.notifier).state = null;
                        }
                      },
                    );
                  }, childCount: filteredProvinces.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Không thể đọc dữ liệu: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapSelectionDetailsPanel extends ConsumerWidget {
  const MapSelectionDetailsPanel({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProvince = ref.watch(selectedProvinceProvider);
    final compareMode = ref.watch(compareModeProvider);
    final firstProvince = ref.watch(firstCompareProvinceProvider);
    final secondProvince = ref.watch(secondCompareProvinceProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 18 : 22, 20, 20),
              child: compareMode
                  ? _ProvinceComparePanel(
                firstProvince: firstProvince,
                secondProvince: secondProvince,
              )
                  : selectedProvince == null
                  ? _EmptySelectionState(compact: compact)
                  : _SelectedProvinceCard(province: selectedProvince),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHero extends StatelessWidget {
  const _PanelHero({
    required this.compact,
    required this.filteredCount,
    required this.totalCount,
  });

  final bool compact;
  final int filteredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bản đồ Việt Nam',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm tỉnh thành để lọc nhanh, bấm vào tỉnh để xem thông tin và các địa điểm du lịch nổi bật.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStatChip(
                label: 'Hiển thị',
                value: '$filteredCount/$totalCount',
              ),
              const _HeroStatChip(label: 'Chế độ', value: 'Tương tác'),
              const _HeroStatChip(label: 'Thông tin', value: 'Theo tỉnh'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm tỉnh, thành phố, thủ phủ...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _PanelHintRow extends ConsumerWidget {
  const _PanelHintRow({
    required this.searchQuery,
    required this.onResetSelection,
  });

  final String searchQuery;
  final VoidCallback onResetSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compareMode = ref.watch(compareModeProvider);
    final featuredTravelMode = ref.watch(featuredTravelModeProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.compare_arrows_rounded, size: 18),
          label: Text(compareMode ? 'Tắt so sánh' : 'So sánh 2 tỉnh'),
          onPressed: () {
            final nextMode = !compareMode;

            ref.read(compareModeProvider.notifier).state = nextMode;

            if (!nextMode) {
              ref.read(firstCompareProvinceIdProvider.notifier).state = null;
              ref.read(secondCompareProvinceIdProvider.notifier).state = null;
            } else {
              ref.read(selectedProvinceIdProvider.notifier).state = null;
            }
          },
        ),
        ActionChip(
          avatar: Icon(
            featuredTravelMode
                ? Icons.map_rounded
                : Icons.travel_explore_rounded,
            size: 18,
          ),
          label: Text(
            featuredTravelMode ? 'Tắt phượt nổi bật' : 'Phượt nổi bật',
          ),
          onPressed: () {
            final nextMode = !featuredTravelMode;

            ref.read(featuredTravelModeProvider.notifier).state = nextMode;

            if (nextMode) {
              ref.read(compareModeProvider.notifier).state = false;
              ref.read(firstCompareProvinceIdProvider.notifier).state = null;
              ref.read(secondCompareProvinceIdProvider.notifier).state = null;
              ref.read(selectedProvinceIdProvider.notifier).state = null;
            }
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.filter_center_focus_rounded, size: 18),
          label: const Text('Bỏ chọn'),
          onPressed: () {
            onResetSelection();
            ref.read(firstCompareProvinceIdProvider.notifier).state = null;
            ref.read(secondCompareProvinceIdProvider.notifier).state = null;
          },
        ),
        if (searchQuery.isNotEmpty)
          ActionChip(
            avatar: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Xóa bộ lọc'),
            onPressed: () {
              final container = ProviderScope.containerOf(context);
              container.read(provinceSearchQueryProvider.notifier).state = '';
            },
          ),
      ],
    );
  }
}

class _SelectedProvinceCard extends ConsumerWidget {
  const _SelectedProvinceCard({required this.province});

  final ProvinceModel province;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ProvinceRegionPalette.colorForRegion(province.macroRegion);
    final tourismAsync = ref.watch(selectedProvinceTourismProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  province.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${province.type} • ${ProvinceRegionPalette.labelForRegion(province.macroRegion)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                label: 'Dân số',
                value: _formatNumber(province.population),
              ),
              _InfoPill(
                label: 'Diện tích',
                value: '${province.areaKm2.toStringAsFixed(0)} km²',
              ),
              _InfoPill(
                label: 'Mật độ',
                value: province.density.toStringAsFixed(0),
              ),
            ],
          ),
          if ((province.capital ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Trung tâm hành chính: ${province.capital}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if ((province.predecessors ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tiền thân: ${province.predecessors}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),

          SizedBox(
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
          const SizedBox(height: 18),
          Text(
            'Địa điểm du lịch',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          tourismAsync.when(
            data: (destinations) {
              if (destinations.isEmpty) {
                return Text(
                  'Chưa có dữ liệu điểm du lịch cho tỉnh hoặc thành phố này.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }

              return Column(
                children: destinations
                    .map(
                      (destination) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TourismDestinationTile(
                          destination: destination,
                          accent: accent,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Text(
              'Không thể đọc dữ liệu du lịch: $error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySelectionState extends StatelessWidget {
  const _EmptySelectionState({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin khu vực',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bấm vào một tỉnh hoặc thành phố trên bản đồ để xem thông tin chi tiết và các địa điểm du lịch nổi bật ở đây.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chọn một khu vực để mở thẻ thông tin bên phải.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourismDestinationTile extends StatelessWidget {
  const _TourismDestinationTile({
    required this.destination,
    required this.accent,
  });

  final TourismDestinationModel destination;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  destination.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (destination.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              destination.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
          if (destination.keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: destination.keywords
                  .map(
                    (keyword) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        keyword,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('$label: $value', style: theme.textTheme.labelLarge),
    );
  }
}

class _RegionLegend extends ConsumerWidget {
  const _RegionLegend({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regions = ProvinceRegionPalette.orderedRegions;
    final selectedRegion = ref.watch(selectedRegionFilterProvider);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Màu theo vùng', style: theme.textTheme.titleMedium),
              ),
              if (selectedRegion != null)
                TextButton(
                  onPressed: () {
                    ref.read(selectedRegionFilterProvider.notifier).state = null;
                  },
                  child: const Text('Tất cả'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: regions.map((region) {
              return _LegendChip(
                label: ProvinceRegionPalette.labelForRegion(region),
                color: ProvinceRegionPalette.colorForRegion(region),
                selected: selectedRegion == region,
                onTap: () {
                  final notifier =
                  ref.read(selectedRegionFilterProvider.notifier);

                  notifier.state = selectedRegion == region ? null : region;

                  ref.read(selectedProvinceIdProvider.notifier).state = null;
                  ref.read(firstCompareProvinceIdProvider.notifier).state = null;
                  ref.read(secondCompareProvinceIdProvider.notifier).state = null;
                },
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? color.withValues(alpha: 0.22)
          : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle,
                size: selected ? 14 : 10,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProvinceListTile extends StatelessWidget {
  const _ProvinceListTile({
    required this.province,
    required this.isSelected,
    required this.onTap,
  });

  final ProvinceModel province;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ProvinceRegionPalette.colorForRegion(province.macroRegion);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected
            ? accent.withValues(alpha: 0.14)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        province.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ProvinceRegionPalette.labelForRegion(province.macroRegion)} • ${province.type}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: isSelected ? accent : theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Không tìm thấy kết quả cho "$query". Hãy thử tên khác, bỏ dấu, hoặc nhập thủ phủ.',
      ),
    );
  }
}

class _MobileSearchBar extends StatelessWidget {
  const _MobileSearchBar({
    required this.controller,
    required this.resultCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final int resultCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VN Map',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _SearchField(
            controller: controller,
            onChanged: onChanged,
            onClear: onClear,
          ),
          const SizedBox(height: 8),
          Text(
            '$resultCount khu vực phù hợp',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceComparePanel extends StatelessWidget {
  const _ProvinceComparePanel({
    required this.firstProvince,
    required this.secondProvince,
  });

  final ProvinceModel? firstProvince;
  final ProvinceModel? secondProvince;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (firstProvince == null || secondProvince == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'So sánh 2 tỉnh',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Hãy chọn đủ 2 tỉnh hoặc thành phố từ danh sách bên trái để xem bảng so sánh.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            _ComparePickStatus(
              label: 'Tỉnh thứ nhất',
              province: firstProvince,
            ),
            const SizedBox(height: 10),
            _ComparePickStatus(
              label: 'Tỉnh thứ hai',
              province: secondProvince,
            ),
          ],
        ),
      );
    }

    final first = firstProvince!;
    final second = secondProvince!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'So sánh khu vực',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _CompareHeader(first: first, second: second),
          const SizedBox(height: 14),
          _CompareRow(
            label: 'Loại',
            firstValue: first.type,
            secondValue: second.type,
          ),
          _CompareRow(
            label: 'Vùng',
            firstValue: ProvinceRegionPalette.labelForRegion(first.macroRegion),
            secondValue:
            ProvinceRegionPalette.labelForRegion(second.macroRegion),
          ),
          _CompareRow(
            label: 'Dân số',
            firstValue: _formatNumber(first.population),
            secondValue: _formatNumber(second.population),
          ),
          _CompareRow(
            label: 'Diện tích',
            firstValue: '${first.areaKm2.toStringAsFixed(0)} km²',
            secondValue: '${second.areaKm2.toStringAsFixed(0)} km²',
          ),
          _CompareRow(
            label: 'Mật độ',
            firstValue: first.density.toStringAsFixed(0),
            secondValue: second.density.toStringAsFixed(0),
          ),
          _CompareRow(
            label: 'Trung tâm',
            firstValue: (first.capital ?? '').isEmpty ? '—' : first.capital!,
            secondValue: (second.capital ?? '').isEmpty ? '—' : second.capital!,
          ),
          _CompareRow(
            label: 'Tiền thân',
            firstValue:
            (first.predecessors ?? '').isEmpty ? '—' : first.predecessors!,
            secondValue: (second.predecessors ?? '').isEmpty
                ? '—'
                : second.predecessors!,
          ),
        ],
      ),
    );
  }
}

class _ComparePickStatus extends StatelessWidget {
  const _ComparePickStatus({
    required this.label,
    required this.province,
  });

  final String label;
  final ProvinceModel? province;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = province != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selected ? '$label: ${province!.displayName}' : '$label: chưa chọn',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareHeader extends StatelessWidget {
  const _CompareHeader({
    required this.first,
    required this.second,
  });

  final ProvinceModel first;
  final ProvinceModel second;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstColor = ProvinceRegionPalette.colorForRegion(first.macroRegion);
    final secondColor = ProvinceRegionPalette.colorForRegion(second.macroRegion);

    return Row(
      children: [
        Expanded(
          child: _CompareProvinceName(
            province: first,
            color: firstColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CompareProvinceName(
            province: second,
            color: secondColor,
          ),
        ),
      ],
    );
  }
}

class _CompareProvinceName extends StatelessWidget {
  const _CompareProvinceName({
    required this.province,
    required this.color,
  });

  final ProvinceModel province;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        province.displayName,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.firstValue,
    required this.secondValue,
  });

  final String label;
  final String firstValue;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(firstValue)),
              const SizedBox(width: 12),
              Expanded(child: Text(secondValue)),
            ],
          ),
        ],
      ),
    );
  }
}

class ProvinceRegionPalette {
  static const orderedRegions = [
    'northern_midlands',
    'red_river_delta',
    'central_coast',
    'central_highlands',
    'southeast',
    'mekong_delta',
  ];

  static Color colorForRegion(String region) {
    switch (region) {
      case 'northern_midlands':
        return const Color(0xFF4C8BF5);
      case 'red_river_delta':
        return const Color(0xFF11A579);
      case 'central_coast':
        return const Color(0xFFF39C35);
      case 'central_highlands':
        return const Color(0xFF9B6D3F);
      case 'southeast':
        return const Color(0xFFE14ECA);
      case 'mekong_delta':
        return const Color(0xFF0D9488);
      default:
        return const Color(0xFF64748B);
    }
  }

  static String labelForRegion(String region) {
    switch (region) {
      case 'northern_midlands':
        return 'Trung du và miền núi Bắc Bộ';
      case 'red_river_delta':
        return 'Đồng bằng sông Hồng';
      case 'central_coast':
        return 'Duyên hải miền Trung';
      case 'central_highlands':
        return 'Tây Nguyên';
      case 'southeast':
        return 'Đông Nam Bộ';
      case 'mekong_delta':
        return 'Đồng bằng sông Cửu Long';
      default:
        return 'Khác';
    }
  }
}

String _formatNumber(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);

    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}
