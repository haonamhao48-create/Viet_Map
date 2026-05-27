import 'dart:convert';
import 'dart:io';

void main() async {
  final inputFile = File(r'c:\Users\haona\OneDrive\Desktop\Viet_Map\assets\geo\communes.geojson');
  final outDir = Directory(r'c:\Users\haona\OneDrive\Desktop\Viet_Map\assets\geo\provinces');
  
  if (!await inputFile.exists()) {
    print('Input file not found');
    return;
  }
  
  if (!await outDir.exists()) {
    await outDir.create(recursive: true);
  }
  
  try {
    print('1. Đọc file dữ liệu (178MB)...');
    String stringData = await inputFile.readAsString();
    
    print('2. Xử lý lỗi chuẩn JSON (NaN -> null)...');
    stringData = stringData.replaceAll(': NaN', ': null');
    
    print('3. Đang giải mã (Decode) JSON...');
    final data = jsonDecode(stringData);
    final features = data['features'] as List;
    
    print('   - Tìm thấy ${features.length} xã/phường.');
    
    // Group by parent_ma (Province ID)
    Map<String, List<dynamic>> groupedFeatures = {};
    Map<String, String> provinceNames = {};
    
    for (var feature in features) {
      final properties = feature['properties'];
      if (properties == null) continue;
      
      final parentMa = properties['parent_ma']?.toString();
      final parentTen = properties['parent_ten']?.toString();
      
      if (parentTen != null) {
        // Normalize name: remove accents, lowercase, replace spaces with hyphens
        String normalized = parentTen.toLowerCase();
        const Map<String, String> accents = {
          'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a', 'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a', 'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
          'đ': 'd',
          'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e', 'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
          'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
          'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o', 'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o', 'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
          'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u', 'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
          'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
        };
        accents.forEach((key, value) {
          normalized = normalized.replaceAll(key, value);
        });
        normalized = normalized.replaceAll('thanh pho ', '').replaceAll('tinh ', '').trim();
        normalized = normalized.replaceAll(RegExp(r'\s+'), '-');

        if (!groupedFeatures.containsKey(normalized)) {
          groupedFeatures[normalized] = [];
          provinceNames[normalized] = parentTen;
        }
        groupedFeatures[normalized]!.add(feature);
      }
    }
    
    print('4. Đang lưu ${groupedFeatures.length} file riêng biệt cho từng Tỉnh/Thành...');
    
    int count = 0;
    for (var entry in groupedFeatures.entries) {
      final provinceCode = entry.key;
      final provinceFeatures = entry.value;
      
      final outputData = {
        "type": "FeatureCollection",
        "features": provinceFeatures,
      };
      
      // Save with formatting
      final outFile = File('${outDir.path}\\$provinceCode.geojson');
      await outFile.writeAsString(jsonEncode(outputData));
      count++;
    }
    
    print('\nHOÀN THÀNH! Đã lưu $count files vào thư mục: assets/geo/provinces/');
  } catch (e) {
    print('Lỗi trong quá trình xử lý: $e');
  }
}
