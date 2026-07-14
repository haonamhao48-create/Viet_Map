import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase config đọc từ `assets/config/env` (không hardcode API key trong source).
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase chưa cấu hình cho Linux. Thêm biến môi trường tương ứng.',
        );
      default:
        throw UnsupportedError(
          'Firebase chưa hỗ trợ platform này.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _require('FIREBASE_WEB_API_KEY'),
        appId: _require('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        authDomain: _require('FIREBASE_AUTH_DOMAIN'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
        measurementId: _optional('FIREBASE_WEB_MEASUREMENT_ID'),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _require('FIREBASE_ANDROID_API_KEY'),
        appId: _require('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _require('FIREBASE_IOS_API_KEY'),
        appId: _require('FIREBASE_IOS_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _require('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: _require('FIREBASE_MACOS_API_KEY'),
        appId: _require('FIREBASE_MACOS_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _require('FIREBASE_MACOS_BUNDLE_ID'),
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: _require('FIREBASE_WINDOWS_API_KEY'),
        appId: _require('FIREBASE_WINDOWS_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        authDomain: _require('FIREBASE_AUTH_DOMAIN'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
        measurementId: _optional('FIREBASE_WINDOWS_MEASUREMENT_ID'),
      );

  static String _require(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError(
        'Thiếu $key trong assets/config/env. Xem assets/config/env.example.',
      );
    }
    return value;
  }

  static String? _optional(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
