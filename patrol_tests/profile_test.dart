import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// TC8 - Profile tab and user information.
void main() {
  patrolTest(
    'TC8 - Navigate to Profile and verify profile form',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      await $('Cá nhân').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      expect($('HỒ SƠ CÁ NHÂN'), findsOneWidget);
      expect($('Đăng xuất'), findsOneWidget);
    },
  );
}
