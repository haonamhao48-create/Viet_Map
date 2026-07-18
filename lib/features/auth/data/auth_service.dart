import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/notification_service.dart';
import '../core/firebase_auth_config.dart';
import '../data/models/app_user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? FirebaseAuthConfig.createGoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<AppUserModel?> watchCurrentUserProfile() {
    final user = currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return AppUserModel.fromFirestore(snapshot);
    });
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return signInWithGoogleDesktop();
    }

    final googleUser = await _requestGoogleAccount();
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message:
            'Không lấy được idToken từ Google. Kiểm tra serverClientId (Web Client ID) trên Firebase.',
      );
    }

    final userCredential = await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );

    await _saveUserToFirestore(userCredential.user);
    return userCredential;
  }

  Future<UserCredential> signInWithGoogleDesktop() async {
    // 1. Khởi động local server
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final redirectUri = 'http://localhost:$port';
    
    // 2. Tạo Google Auth URL
    final clientId = FirebaseAuthConfig.desktopClientId;
    final authUrl = 'https://accounts.google.com/o/oauth2/v2/auth'
        '?client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&response_type=code'
        '&scope=email%20profile%20openid';
        
    // 3. Mở trình duyệt mặc định
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', authUrl.replaceAll('&', '^&')]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [authUrl]);
    } else {
      await Process.run('xdg-open', [authUrl]);
    }
    
    // 4. Lắng nghe phản hồi từ trình duyệt
    try {
      final request = await server.first;
      final code = request.uri.queryParameters['code'];
      
      if (code == null) {
        request.response
          ..statusCode = 400
          ..write('Lỗi: Không lấy được mã xác thực code.');
        await request.response.close();
        throw Exception('Không có mã xác thực code từ Google.');
      }
      
      // Hiển thị thông báo thành công trên trình duyệt
      request.response
        ..headers.contentType = ContentType.html
        ..write('''
          <html>
            <head>
              <meta charset="utf-8">
              <title>Đăng nhập thành công</title>
              <style>
                body { font-family: sans-serif; text-align: center; padding-top: 50px; background-color: #f6fafc; color: #0f766e; }
                h1 { color: #0f766e; }
              </style>
            </head>
            <body>
              <h1>Đăng nhập Vietmap thành công!</h1>
              <p>Bạn có thể đóng cửa sổ này và quay lại ứng dụng.</p>
              <script>setTimeout(window.close, 3000);</script>
            </body>
          </html>
        ''');
      await request.response.close();
        
      // 5. Trao đổi code lấy tokens
      final clientSecret = FirebaseAuthConfig.clientSecret;
      final tokenResponse = await _exchangeAuthCode(code, redirectUri, clientId, clientSecret);
      final idToken = tokenResponse['id_token'];
      final accessToken = tokenResponse['access_token'];
      
      if (idToken == null) {
        final errorDescription = tokenResponse['error_description'] ?? tokenResponse['error'] ?? 'Không rõ lỗi';
        throw Exception('Không nhận được id_token từ Google ($errorDescription).');
      }
      
      // 6. Đăng nhập Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential.user);
      return userCredential;
      
    } finally {
      await server.close();
    }
  }

  Future<Map<String, dynamic>> _exchangeAuthCode(
    String code,
    String redirectUri,
    String clientId,
    String clientSecret,
  ) async {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('https://oauth2.googleapis.com/token'));
    request.headers.contentType = ContentType.parse('application/x-www-form-urlencoded');
    
    var body = 'code=${Uri.encodeComponent(code)}'
        '&client_id=${Uri.encodeComponent(clientId)}'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&grant_type=authorization_code';
        
    if (clientSecret.isNotEmpty) {
      body += '&client_secret=${Uri.encodeComponent(clientSecret)}';
    }
        
    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    client.close();
    
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  Future<GoogleSignInAccount> _requestGoogleAccount() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-canceled',
        message: 'Đăng nhập Google bị hủy.',
      );
    }
    return account;
  }

  static const _adminEmails = {
    'dbchan1624@gmail.com',
    'namtt4304@gmail.com',
  };

  bool _isAdminEmail(String? email) {
    if (email == null) return false;
    return _adminEmails.contains(email.trim().toLowerCase());
  }

  String _resolveRole(String? email, {String? existingRole}) {
    final normalized = existingRole?.trim().toLowerCase();
    if (normalized == 'admin' || normalized == 'user') {
      return normalized!;
    }
    return _isAdminEmail(email) ? 'admin' : 'user';
  }

  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final existingRole = snapshot.data()?['role'] as String?;
    final resolvedRole = _resolveRole(user.email, existingRole: existingRole);

    final commonData = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'fullName': user.displayName,
      'avatarUrl': user.photoURL,
      'provider': 'google',
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      await userRef.set({
        ...commonData,
        'role': resolvedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await NotificationService.saveTokenToFirestore(user.uid);
      return;
    }

    // Không ghi đè role khi đăng nhập lại — giữ admin/user đã có trên Firestore.
    await userRef.update({
      'email': user.email,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.saveTokenToFirestore(user.uid);
  }

  Future<void> signOut() async {
    // On Desktop, login uses custom OAuth (not GoogleSignIn SDK),
    // so _googleSignIn.signOut() may throw — always ensure Firebase signs out.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignored on Desktop — no active GoogleSignIn session to clear
      }
    } else {
      await _googleSignIn.signOut();
    }
    await _firebaseAuth.signOut();
  }
}
