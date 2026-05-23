import 'package:flutter_test/flutter_test.dart';

import 'package:vn_map_app/core/utils/text_normalizer.dart';

void main() {
  test('normalize vietnamese text for search', () {
    expect(
      TextNormalizer.normalizeVietnamese('Thành phố Hồ Chí Minh'),
      'thanh pho ho chi minh',
    );
  });
}
