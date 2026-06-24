import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/firebase_auth_config.dart';
import '../data/models/app_user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

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
    await FirebaseAuthConfig.ensureGoogleSignInInitialized();

    final googleUser = await _requestGoogleAccount();
    final idToken = googleUser.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message:
            'Không lấy được idToken từ Google. Hãy rebuild app sau khi cập nhật google-services.json.',
      );
    }

    final userCredential = await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );

    await _saveUserToFirestore(userCredential.user);
    return userCredential;
  }

  Future<GoogleSignInAccount> _requestGoogleAccount() async {
    if (!kIsWeb) {
      final lightweight =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (lightweight != null) {
        return lightweight;
      }
    }

    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        throw FirebaseAuthException(
          code: 'google-sign-in-canceled',
          message:
              'Google Sign-In thất bại. Hãy chạy: flutter clean && flutter run, '
              'và kiểm tra SHA-1 + google-services.json trên Firebase Console.',
        );
      }
      rethrow;
    }
  }

  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

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
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await userRef.update(commonData);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }
}
