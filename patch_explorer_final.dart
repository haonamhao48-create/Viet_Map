import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/map_explorer_panel.dart');
  var content = file.readAsStringSync();

  // Replace the condition exactly based on matching the literal string
  if (content.contains('? _EmptySelectionState(compact: compact)')) {
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
  }

  file.writeAsStringSync(content);
}
