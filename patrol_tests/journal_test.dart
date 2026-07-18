import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// TC4–TC5 (template): Journals → VietMap: Chiến dịch tuyển sinh (campaign list).
void main() {
  patrolTest(
    'TC4 - Navigate to campaigns tab and verify list header',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      await $('Chiến dịch').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      expect($('Chiến dịch tuyển sinh'), findsOneWidget);
      expect($('Sự kiện của tôi'), findsOneWidget);
    },
  );

  patrolTest(
    'TC5 - Open my events as journal-style detail list',
    ($) async {
      await pumpVietMapApp($);

      if (await isLoginScreenVisible($)) {
        expect($(#patrol_login_google_button), findsOneWidget);
        return;
      }

      await $('Chiến dịch').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
      await $('Sự kiện của tôi').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      expect($('Sự kiện của tôi').exists || $('sự kiện').exists, isTrue);
    },
  );
}
