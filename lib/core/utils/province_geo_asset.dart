/// Slug tên file GeoJSON xã/phường trong `assets/geo/provinces/`.
String provinceGeoAssetSlug(String displayName) {
  final lower = displayName.toLowerCase().trim();

  if (_provinceFileMap.containsKey(lower)) {
    return _provinceFileMap[lower]!;
  }

  final stripped = lower
      .replaceAll('thành phố ', '')
      .replaceAll('tỉnh ', '')
      .replaceAll('thủ đô ', '')
      .trim();

  if (_provinceFileMap.containsKey(stripped)) {
    return _provinceFileMap[stripped]!;
  }

  var s = stripped;
  _accentMap.forEach((key, value) {
    s = s.replaceAll(key, value);
  });
  return s.replaceAll(RegExp(r'\s+'), '-');
}

const Map<String, String> _provinceFileMap = {
  'thủ đô hà nội': 'thu-do-ha-noi',
  'hà nội': 'thu-do-ha-noi',
  'hồ chí minh': 'ho-chi-minh',
  'thành phố hồ chí minh': 'ho-chi-minh',
  'đà nẵng': 'da-nang',
  'thành phố đà nẵng': 'da-nang',
  'cần thơ': 'can-tho',
  'thành phố cần thơ': 'can-tho',
  'hải phòng': 'hai-phong',
  'thành phố hải phòng': 'hai-phong',
  'huế': 'hue',
  'tỉnh huế': 'hue',
  'thừa thiên huế': 'hue',
  'bắc ninh': 'bac-ninh',
  'bắc kạn': 'bac-ninh',
  'cà mau': 'ca-mau',
  'cao bằng': 'cao-bang',
  'đắk lắk': 'dak-lak',
  'điện biên': 'dien-bien',
  'đồng nai': 'dong-nai',
  'đồng tháp': 'dong-thap',
  'gia lai': 'gia-lai',
  'hà tĩnh': 'ha-tinh',
  'khánh hòa': 'khanh-hoa',
  'lai châu': 'lai-chau',
  'lâm đồng': 'lam-dong',
  'lạng sơn': 'lang-son',
  'lào cai': 'lao-cai',
  'nghệ an': 'nghe-an',
  'ninh bình': 'ninh-binh',
  'phú thọ': 'phu-tho',
  'quảng ngãi': 'quang-ngai',
  'quảng ninh': 'quang-ninh',
  'quảng trị': 'quang-tri',
  'sơn la': 'son-la',
  'tây ninh': 'tay-ninh',
  'thái nguyên': 'thai-nguyen',
  'thanh hóa': 'thanh-hoa',
  'tuyên quang': 'tuyen-quang',
  'vĩnh long': 'vinh-long',
  'an giang': 'an-giang',
  'hưng yên': 'hung-yen',
};

const Map<String, String> _accentMap = {
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
