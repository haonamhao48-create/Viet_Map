part of 'travel_places_screen.dart';

/// Panel chi tiết xã/phường (tên, diện tích, dân số, v.v.).
class _CommuneDetail extends StatelessWidget {
  const _CommuneDetail({required this.commune});

  final _CommuneArea commune;

  String _formatNumber(num? value) {
    if (value == null) return '—';
    final text = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            commune.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            commune.type.isEmpty ? 'Khu vực hành chính' : commune.type,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.teal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CommuneInfoChip(
                label: 'Diện tích',
                value: commune.areaKm2 == null
                    ? '—'
                    : '${commune.areaKm2!.toStringAsFixed(2)} km²',
              ),
              _CommuneInfoChip(
                label: 'Dân số',
                value: commune.population == null
                    ? '—'
                    : '${_formatNumber(commune.population)} người',
              ),
              _CommuneInfoChip(
                label: 'Mật độ',
                value: commune.density == null
                    ? '—'
                    : '${_formatNumber(commune.density)} người/km²',
              ),
            ],
          ),
          if (commune.capital.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Trụ sở / trung tâm',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(commune.capital),
          ],
          if (commune.predecessors.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Tiền thân',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              commune.predecessors,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip hiển thị thông tin thống kê xã/phường.
class _CommuneInfoChip extends StatelessWidget {
  const _CommuneInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.teal.withValues(alpha: 0.10),
      labelStyle: const TextStyle(
        color: Colors.teal,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Sidebar danh sách xã/phường với local state để tối ưu rebuild.
class _CommunesSidePanel extends StatefulWidget {
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
  State<_CommunesSidePanel> createState() => _CommunesSidePanelState();
}

class _CommunesSidePanelState extends State<_CommunesSidePanel> {
  /// Lưu tên xã đang chọn locally để chỉ rebuild 2 tiles bị ảnh hưởng.
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.selectedCommune?.name;
  }

  @override
  void didUpdateWidget(_CommunesSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCommune?.name != _selectedName) {
      _selectedName = widget.selectedCommune?.name;
    }
  }

  void _handleTap(_CommuneArea commune) {
    setState(() {
      _selectedName = commune.name;
    });
    widget.onCommuneSelected(commune);
  }

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
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.province.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.communes.length} đơn vị hành chính',
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
                  final commune = widget.communes[index];
                  final isSelected = _selectedName == commune.name;
                  return RepaintBoundary(
                    child: _CommuneListTile(
                      key: ValueKey(commune.name),
                      index: index + 1,
                      commune: commune,
                      isSelected: isSelected,
                      onTap: () => _handleTap(commune),
                    ),
                  );
                },
                childCount: widget.communes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile xã/phường trong sidebar — được bọc RepaintBoundary để tách layer paint.
class _CommuneListTile extends StatelessWidget {
  const _CommuneListTile({
    super.key,
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
                  backgroundColor:
                      isSelected ? Colors.teal : Colors.grey.shade400,
                  child: Text(
                    '$index',
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
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isSelected ? Colors.teal.shade900 : Colors.black87,
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
