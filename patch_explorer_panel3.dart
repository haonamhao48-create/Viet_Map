import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/map_explorer_panel.dart');
  var content = file.readAsStringSync();

  // 1. Add import (if not already present)
  if (!content.contains("import '../../data/models/commune_model.dart';")) {
    content = content.replaceFirst(
      "import '../../data/models/province_model.dart';",
      "import '../../data/models/province_model.dart';\nimport '../../data/models/commune_model.dart';"
    );
  }

  // 2. Add selectedCommuneProvider (if not already present)
  if (!content.contains("final selectedCommune = ref.watch(selectedCommuneProvider);")) {
    content = content.replaceFirst(
'''  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProvince = ref.watch(selectedProvinceProvider);
    final compareMode = ref.watch(compareModeProvider);''',
'''  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProvince = ref.watch(selectedProvinceProvider);
    final selectedCommune = ref.watch(selectedCommuneProvider);
    final compareMode = ref.watch(compareModeProvider);'''
    );
  }

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

  file.writeAsStringSync(content);
}
