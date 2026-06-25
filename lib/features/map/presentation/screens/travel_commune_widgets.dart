part of 'travel_places_screen.dart';

/// Panel chi tiết xã/phường + danh sách trường THPT.
class _CommuneDetail extends StatelessWidget {
  const _CommuneDetail({
    required this.commune,
    required this.schoolMapMode,
    required this.schools,
    required this.selectedSchool,
    required this.isLoadingSchools,
    required this.schoolsChecked,
    required this.onViewSchools,
    required this.onExitSchoolMap,
    required this.onSchoolSelected,
  });

  final _CommuneArea commune;
  final bool schoolMapMode;
  final List<HighSchoolModel> schools;
  final HighSchoolModel? selectedSchool;
  final bool isLoadingSchools;
  final bool schoolsChecked;
  final VoidCallback onViewSchools;
  final VoidCallback onExitSchoolMap;
  final ValueChanged<HighSchoolModel> onSchoolSelected;

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

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
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
            if (!schoolMapMode) ...[
              const SizedBox(height: 28),
              if (isLoadingSchools || !schoolsChecked)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Đang kiểm tra trường THPT...'),
                      ),
                    ],
                  ),
                )
              else if (schools.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Xã/phường không có trường THPT.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onViewSchools,
                    icon: const Icon(Icons.school_rounded),
                    label: Text('Xem các trường THPT (${schools.length})'),
                  ),
                ),
            ],
            if (schoolMapMode) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onExitSchoolMap,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Quay lại bản đồ xã/phường'),
              ),
              const SizedBox(height: 20),
              Text(
                'Trường THPT (${schools.length})',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (isLoadingSchools)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (schools.isEmpty)
                Text(
                  'Không có trường THPT trong phường/xã này.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...schools.map(
                  (school) => _SchoolListTile(
                    school: school,
                    isSelected: selectedSchool?.id == school.id,
                    onTap: () => onSchoolSelected(school),
                  ),
                ),
              if (selectedSchool != null) ...[
                const SizedBox(height: 20),
                _SchoolDetailCard(school: selectedSchool!),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SchoolDetailCard extends StatelessWidget {
  const _SchoolDetailCard({required this.school});

  final HighSchoolModel school;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  school.tenTruong,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (school.diaChi.isNotEmpty) ...[
            Text('Địa chỉ', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(school.diaChi),
            const SizedBox(height: 10),
          ],
          if (school.khuVuc != null && school.khuVuc!.isNotEmpty)
            _SchoolInfoRow(label: 'Khu vực', value: school.khuVuc!),
          if (school.maTruong != null && school.maTruong!.isNotEmpty)
            _SchoolInfoRow(label: 'Mã trường', value: school.maTruong!),
          if (school.hasValidCoordinates)
            _SchoolInfoRow(
              label: 'Tọa độ',
              value:
                  '${school.latitude.toStringAsFixed(5)}, ${school.longitude.toStringAsFixed(5)}',
            ),
          SchoolVisitNotesSection(school: school),
        ],
      ),
    );
  }
}

class _SchoolInfoRow extends StatelessWidget {
  const _SchoolInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _SchoolListTile extends StatelessWidget {
  const _SchoolListTile({
    required this.school,
    required this.isSelected,
    required this.onTap,
  });

  final HighSchoolModel school;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected
            ? Colors.orange.withValues(alpha: 0.12)
            : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: isSelected ? Colors.orange : Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    school.tenTruong,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.orange.shade900
                          : Colors.black87,
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

/// Marker trường THPT trên bản đồ xã/phường.
class _SchoolBubble extends StatelessWidget {
  const _SchoolBubble({
    required this.school,
    required this.isSelected,
    required this.showLabel,
    required this.onTap,
  });

  final HighSchoolModel school;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.orange : Colors.orange.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel)
            Container(
              constraints: const BoxConstraints(maxWidth: 180),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                school.tenTruong,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: isSelected ? 12 : 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
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
