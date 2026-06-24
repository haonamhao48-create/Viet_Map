import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  static const _googleScopes = <String>[
    'email',
    'profile',
    'openid',
  ];

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

    // Tránh lỗi reauth khi còn session Google cũ.
    await GoogleSignIn.instance.signOut();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate(
      scopeHint: _googleScopes,
    );

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message:
            'Không lấy được idToken từ Google. Kiểm tra GOOGLE_WEB_CLIENT_ID trong .env.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    await _saveUserToFirestore(userCredential.user);

    return userCredential;
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
