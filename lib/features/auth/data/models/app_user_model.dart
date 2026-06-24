import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.role,
    required this.provider,
    this.createdAt,
    this.lastLoginAt,
  });

  final String uid;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final String provider;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  factory AppUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return AppUserModel(
      uid: data['uid']?.toString() ?? snapshot.id,
      email: data['email']?.toString(),
      fullName: data['fullName']?.toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      role: data['role']?.toString() ?? 'user',
      provider: data['provider']?.toString() ?? 'google',
      createdAt: _toDateTime(data['createdAt']),
      lastLoginAt: _toDateTime(data['lastLoginAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
