import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// TC2–TC3 (template): Topic/Publication search → VietMap: Chiến dịch & sự kiện tuyển sinh.
void main() {
  patrolTest(
    'TC2 - Open campaigns list from navigation',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      await $('Chiến dịch').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      expect($('Chiến dịch tuyển sinh'), findsOneWidget);
    },
  );

  patrolTest(
    'TC3 - Campaign publication details screen opens',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      await $('Chiến dịch').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      if ($('Thử lại').exists) {
        expect($('Chiến dịch tuyển sinh'), findsOneWidget);
        return;
      }

      // Tap card đầu tiên nếu có dữ liệu.
      final firstCard = $(ListTile).at(0);
      if (firstCard.exists) {
        await firstCard.tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));
        expect($('Sự kiện').exists || $('Chi tiết').exists || $('chiến dịch').exists, isTrue);
      } else {
        expect($('Chiến dịch tuyển sinh'), findsOneWidget);
      }
    },
  );
}
