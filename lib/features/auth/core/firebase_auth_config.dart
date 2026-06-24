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

  static String get webClientId {
    final fromEnv = dotenv.env[_envKey]?.trim() ?? '';
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return fallbackWebClientId;
  }

  static GoogleSignIn createGoogleSignIn() {
    final needsClientId = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (needsClientId && webClientId.isEmpty) {
      throw StateError(
        'Chưa cấu hình $_envKey trong file .env. '
        'Xem hướng dẫn trong docs/FIREBASE_AUTH_SETUP.md',
      );
    }

    // v6 dùng GoogleSignInClient ổn định hơn Credential Manager (v7) trên OEM Android.
    if (needsClientId) {
      return GoogleSignIn(
        clientId: webClientId,
        scopes: const ['email', 'profile'],
      );
    }

    return GoogleSignIn(
      serverClientId: webClientId,
      scopes: const ['email', 'profile'],
    );
  }
}
