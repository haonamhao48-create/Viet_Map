import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Cấu hình Google Sign-In cho Firebase Auth.
///
/// Web Client ID đọc từ `.env`:
/// `GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com`
class FirebaseAuthConfig {
  FirebaseAuthConfig._();

  static const _envKey = 'GOOGLE_WEB_CLIENT_ID';

  static String get webClientId => dotenv.env[_envKey]?.trim() ?? '';

  static Future<void> ensureGoogleSignInInitialized() async {
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      final needsClientId = kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux;

      if (needsClientId && webClientId.isEmpty) {
        throw StateError(
          'Chưa cấu hình $_envKey trong file .env. '
          'Xem hướng dẫn trong docs/FIREBASE_AUTH_SETUP.md',
        );
      }

      await GoogleSignIn.instance.initialize(
        clientId: needsClientId ? webClientId : null,
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );
    }
  }
}
