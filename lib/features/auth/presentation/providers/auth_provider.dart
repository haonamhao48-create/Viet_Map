import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_service.dart';
import '../../data/models/app_user_model.dart';
import '../../data/user_profile_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProfileServiceProvider =
Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProfileProvider =
StreamProvider.autoDispose<AppUserModel?>((ref) {
  final user = ref.watch(
    authStateProvider.select(
          (authState) => authState.valueOrNull,
    ),
  );

  if (user == null) {
    return Stream.value(null);
  }

  return ref
      .read(userProfileServiceProvider)
      .watchCurrentUserProfile();
});

final authLoadingProvider =
StateProvider<bool>((ref) => false);