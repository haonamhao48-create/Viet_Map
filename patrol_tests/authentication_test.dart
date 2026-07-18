import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

void main() {
  patrolTest(
    'TC1 - Login screen shows Google Sign-In entry point',
    ($) async {
      await pumpVietMapApp($);

      expect($(#patrol_login_google_button), findsOneWidget);
      expect($('Đăng nhập bằng Google'), findsOneWidget);
      expect($('ĐĂNG NHẬP\nHỆ THỐNG'), findsOneWidget);
    },
  );

  patrolTest(
    'TC1 extended - Google Sign-In navigates to Home when already logged in',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        // Google account picker không tự động hóa được — đăng nhập thủ công trước khi chạy test này.
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      expect(await isLoggedIn($), isTrue);
      expect($('Bản đồ').exists || $('Dashboard').exists, isTrue);
    },
  );

  patrolTest(
    'TC11 - Logout redirects to Login screen',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      if ($('Cá nhân').exists) {
        await $('Cá nhân').tap();
      }

      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      if ($('Đăng xuất').exists) {
        await $('Đăng xuất').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      }

      expect(await isLoginScreenVisible($), isTrue);
    },
  );
}
