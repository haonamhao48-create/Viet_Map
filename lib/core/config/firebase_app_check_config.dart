import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Bật Firebase App Check — bắt buộc khi Storage/Firestore enforce App Check.
Future<void> initializeFirebaseAppCheck() async {
  if (kIsWeb) {
    return;
  }

  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );

    if (kDebugMode) {
      final token = await FirebaseAppCheck.instance.getToken();
      debugPrint(
        '[AppCheck] Debug mode — tìm dòng "App Check debug token" trong logcat, '
        'đăng ký token đó tại Firebase Console → App Check → Manage debug tokens. '
        'Token length: ${token?.length ?? 0}',
      );
    }
  } catch (error, stackTrace) {
    debugPrint('[AppCheck] Không kích hoạt được: $error\n$stackTrace');
  }
}
