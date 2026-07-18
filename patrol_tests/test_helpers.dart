import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:vn_map_app/app/app.dart';
import 'package:vn_map_app/core/config/firebase_app_check_config.dart';
import 'package:vn_map_app/firebase_options.dart';

/// Khởi động app VietMap trong Patrol test (giống main.dart).
Future<void> pumpVietMapApp(PatrolIntegrationTester $) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/config/env');
  } catch (_) {
    // env có thể thiếu trên CI — test UI vẫn chạy được.
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeFirebaseAppCheck();
  } catch (_) {
    // Firebase có thể fail nếu thiếu config — vẫn pump UI login.
  }

  await $.pumpWidgetAndSettle(
    const ProviderScope(child: VNMapApp()),
    timeout: const Duration(seconds: 45),
  );
  await $.pumpAndSettle(timeout: const Duration(seconds: 5));
}

/// Màn hình login khi chưa đăng nhập.
Future<bool> isLoginScreenVisible(PatrolIntegrationTester $) async {
  await $.pumpAndSettle(timeout: const Duration(seconds: 2));
  return $(#patrol_login_google_button).exists ||
      $('Đăng nhập bằng Google').exists;
}

/// Đã vào shell user hoặc admin.
Future<bool> isLoggedIn(PatrolIntegrationTester $) async {
  await $.pumpAndSettle(timeout: const Duration(seconds: 2));
  return $('Bản đồ').exists ||
      $('Dashboard').exists ||
      $('VIETMAP GIS').exists;
}

/// Mở drawer bản đồ (menu góc trái).
Future<void> openMapDrawer(PatrolIntegrationTester $) async {
  if ($(Icons.menu_rounded).exists) {
    await $(Icons.menu_rounded).tap();
    return;
  }
  if ($(Icons.menu).exists) {
    await $(Icons.menu).tap();
  }
}
