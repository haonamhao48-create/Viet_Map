import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileService {
  UserProfileService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  Future<XFile?> pickAvatarImage() {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  }

  Future<String> uploadAvatar({
    required String uid,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final extension = _imageExtension(file);
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
    final ref = _storage.ref().child('users/$uid/avatar.$extension');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    return ref.getDownloadURL();
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Chưa đăng nhập.');
    }

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Họ tên không được để trống.');
    }

    final data = <String, dynamic>{
      'fullName': trimmedName,
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'bio': bio?.trim().isEmpty == true ? null : bio?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (avatarUrl != null) {
      data['avatarUrl'] = avatarUrl;
    }

    await _firestore.collection('users').doc(user.uid).update(data);

    await user.updateDisplayName(trimmedName);
    if (avatarUrl != null) {
      await user.updatePhotoURL(avatarUrl);
    }
  }

  Future<void> saveProfile({
    required String fullName,
    String? phone,
    String? bio,
    XFile? avatarFile,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Chưa đăng nhập.');
    }

    String? avatarUrl;
    if (avatarFile != null) {
      avatarUrl = await uploadAvatar(uid: user.uid, file: avatarFile);
    }

    await updateProfile(
      fullName: fullName,
      phone: phone,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }

  String _imageExtension(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) {
      return 'png';
    }
    return 'jpg';
  }
}
