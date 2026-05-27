import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File(r'c:\Users\haona\OneDrive\Desktop\Viet_Map\assets\geo\communes.geojson');
  
  if (!await file.exists()) {
    print('File not found');
    return;
  }
  
  try {
    print('Reading file...');
    String stringData = await file.readAsString();
    print('Fixing NaN...');
    // Replace NaN (not surrounded by quotes) with null.
    // A simple replaceAll might catch letters in strings, but we know it's `: NaN`
    stringData = stringData.replaceAll(': NaN', ': null');
    
    print('Decoding JSON...');
    final data = jsonDecode(stringData);
    
    final features = data['features'] as List;
    print('Number of features: ${features.length}');
    
    if (features.isNotEmpty) {
      print('\nProperties of the first feature:');
      print(JsonEncoder.withIndent('  ').convert(features[0]['properties']));
    }
  } catch (e) {
    print('Error: $e');
  }
}
