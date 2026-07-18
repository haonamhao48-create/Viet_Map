
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/firebase_app_check_config.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/config/env');
  } catch (error) {
    debugPrint('Không tải được assets/config/env: $error');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeFirebaseAppCheck();

    // Khởi tạo Crashlytics nếu nền tảng hỗ trợ
    final isCrashlyticsSupported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isCrashlyticsSupported) {
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      debugPrint('Khởi tạo Firebase Crashlytics thành công.');
    } else {
      debugPrint('Bỏ qua Crashlytics trên nền tảng không hỗ trợ.');
    }

    // Khởi tạo dịch vụ thông báo đẩy (FCM)
    await NotificationService.initialize();
  } catch (error) {
    debugPrint('Khởi tạo Firebase thất bại: $error');
  }

  runApp(
    const ProviderScope(
      child: VNMapApp(),
    ),
  );
}

