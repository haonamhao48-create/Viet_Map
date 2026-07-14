import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Cấu hình Google Sign-In cho Firebase Auth.
class FirebaseAuthConfig {
  FirebaseAuthConfig._();

  static const _envKey = 'GOOGLE_WEB_CLIENT_ID';
  static const _desktopEnvKey = 'GOOGLE_DESKTOP_CLIENT_ID';
  static const _secretKey = 'GOOGLE_CLIENT_SECRET';

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

  static String get desktopClientId {
    final fromEnv = dotenv.env[_desktopEnvKey]?.trim() ?? '';
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return webClientId; // fallback
  }

  static String get clientSecret {
    return dotenv.env[_secretKey]?.trim() ?? '';
  }

  static GoogleSignIn createGoogleSignIn() {
    const scopes = ['email', 'profile'];

    if (kIsWeb) {
      return GoogleSignIn(
        clientId: webClientId,
        scopes: scopes,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      final cid = desktopClientId;
      debugPrint('[DEBUG AUTH] Loading Google Sign-In Client ID for Desktop: $cid');
      if (cid.isEmpty) {
        throw StateError(
          'Chưa cấu hình $_desktopEnvKey trong file env. '
          'Xem hướng dẫn trong docs/FIREBASE_AUTH_SETUP.md',
        );
      }
      return GoogleSignIn(
        clientId: cid,
        scopes: scopes,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return GoogleSignIn(
        serverClientId: webClientId,
        scopes: scopes,
      );
    }

    // Android: không truyền serverClientId — plugin đọc default_web_client_id
    // từ google-services.json (tránh lỗi ApiException: 10 khi override sai).
    return GoogleSignIn(scopes: scopes);
  }
}
