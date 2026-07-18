import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// TC9 (template): PDF export + Storage → VietMap: Avatar upload UI (Firebase Storage).
void main() {
  patrolTest(
    'TC9 - Profile shows avatar upload section for Firebase Storage',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      await $('Cá nhân').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      expect($('HỒ SƠ CÁ NHÂN'), findsOneWidget);
      expect(
        $('Chạm biểu tượng camera để đổi ảnh đại diện').exists ||
            $(Icons.camera_alt_outlined).exists ||
            $(Icons.camera_alt).exists,
        isTrue,
      );
    },
  );
}
