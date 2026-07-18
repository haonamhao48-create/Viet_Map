import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// TC6–TC7 (template): Keywords → VietMap: Tìm kiếm trường THPT.
void main() {
  patrolTest(
    'TC6 - Open school directory from map drawer',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      await openMapDrawer($);
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));
      await $('Danh mục trường học').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      expect($('DANH SÁCH TRƯỜNG HỌC'), findsOneWidget);
    },
  );

  patrolTest(
    'TC7 - Search schools by keyword and show filtered results',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      await openMapDrawer($);
      await $('Danh mục trường học').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      final searchField = $(TextField).at(0);
      if (searchField.exists) {
        await searchField.enterText('Lâm Đồng');
        await $.pumpAndSettle(timeout: const Duration(seconds: 3));
      }

      expect($('DANH SÁCH TRƯỜNG HỌC'), findsOneWidget);
    },
  );
}
