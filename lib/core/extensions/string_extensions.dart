/// Extensions tiện ích cho kiểu String.
library;

extension VietnameseStringExtension on String {
  static const Map<String, String> _accentMap = {
    'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'đ': 'd',
    'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
  };

  /// Xóa dấu tiếng Việt và chuyển về chữ thường không dấu.
  ///
  /// Ví dụ: `'Đà Nẵng'.removeAccents()` → `'da nang'`
  String removeAccents() {
    String result = toLowerCase();
    _accentMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  /// Chuẩn hóa tên tỉnh thành thành dạng slug (dấu gạch ngang).
  ///
  /// Ví dụ: `'Thành phố Đà Nẵng'.toProvinceSlug()` → `'da-nang'`
  String toProvinceSlug() {
    String s = toLowerCase()
        .replaceAll('thành phố ', '')
        .replaceAll('tỉnh ', '')
        .replaceAll('thủ đô ', '')
        .trim();

    s = s.removeAccents();
    return s.replaceAll(RegExp(r'\s+'), '-');
  }

  /// Xóa dấu và chuyển về chữ thường để tìm kiếm.
  ///
  /// Ví dụ: `'Lâm Đồng'.normalizeForSearch()` → `'lam dong'`
  String normalizeForSearch() => removeAccents().trim();
}
