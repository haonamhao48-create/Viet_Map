import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/map_explorer_panel.dart');
  var content = file.readAsStringSync();

  // 1. Add import
  content = content.replaceFirst(
    "import '../../data/models/province_model.dart';",
    "import '../../data/models/province_model.dart';\nimport '../../data/models/commune_model.dart';"
  );

  // 2. Add selectedCommuneProvider
  content = content.replaceFirst(
    "    final selectedProvince = ref.watch(selectedProvinceProvider);",
    "    final selectedProvince = ref.watch(selectedProvinceProvider);\n    final selectedCommune = ref.watch(selectedCommuneProvider);"
  );

  // 3. Update build condition
  content = content.replaceFirst(
'''              child: compareMode
                  ? _ProvinceComparePanel(
                firstProvince: firstProvince,
                secondProvince: secondProvince,
              )
                  : selectedProvince == null
                  ? _EmptySelectionState(compact: compact)
                  : _SelectedProvinceCard(province: selectedProvince),''',
'''              child: compareMode
                  ? _ProvinceComparePanel(
                firstProvince: firstProvince,
                secondProvince: secondProvince,
              )
                  : (selectedCommune != null && selectedProvince != null)
                  ? _SelectedCommuneCard(commune: selectedCommune, province: selectedProvince)
                  : selectedProvince == null
                  ? _EmptySelectionState(compact: compact)
                  : _SelectedProvinceCard(province: selectedProvince),'''
  );

  // 4. Add _SelectedCommuneCard
  content += '''

class _SelectedCommuneCard extends ConsumerWidget {
  const _SelectedCommuneCard({required this.commune, required this.province});

  final CommuneModel commune;
  final ProvinceModel province;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ProvinceRegionPalette.colorForRegion(province.macroRegion);

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
                  commune.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  ref.read(selectedCommuneIdProvider.notifier).state = null;
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\${commune.type} thuộc \${province.displayName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (commune.population > 0)
                _InfoPill(
                  label: 'Dân số',
                  value: _formatNumber(commune.population),
                ),
              if (commune.areaKm2 > 0)
                _InfoPill(
                  label: 'Diện tích',
                  value: '\${commune.areaKm2.toStringAsFixed(2)} km²',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
''';

  file.writeAsStringSync(content);
}
