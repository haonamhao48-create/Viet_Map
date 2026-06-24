import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Cấu hình Google Sign-In cho Firebase Auth.
class FirebaseAuthConfig {
  FirebaseAuthConfig._();

  static const _envKey = 'GOOGLE_WEB_CLIENT_ID';

  /// Fallback khớp `default_web_client_id` trong google-services.json.
  static const fallbackWebClientId =
      '166713477101-v09cj3hm7vclucujp4usha14a3hcrdgj.apps.googleusercontent.com';

  static bool _initialized = false;

  static String get webClientId {
    final fromEnv = dotenv.env[_envKey]?.trim() ?? '';
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return fallbackWebClientId;
  }

  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> ensureGoogleSignInInitialized() async {
    if (_initialized) {
      return;
    }

    final needsClientId = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (needsClientId && webClientId.isEmpty) {
      throw StateError(
        'Chưa cấu hình $_envKey trong file .env. '
        'Xem hướng dẫn trong docs/FIREBASE_AUTH_SETUP.md',
      );
    }

    // Android/iOS: để plugin đọc serverClientId từ google-services.json.
    // Desktop/Web: truyền web client id từ .env.
    await GoogleSignIn.instance.initialize(
      clientId: needsClientId ? webClientId : null,
      serverClientId: _isMobile ? null : webClientId,
    );

    _initialized = true;
  }
}
