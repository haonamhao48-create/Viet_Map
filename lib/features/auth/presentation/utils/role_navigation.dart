import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/user_role.dart';
import 'auth_navigation.dart';
import '../providers/auth_provider.dart';

/// Điều hướng sau đăng nhập theo role Firestore.
void navigateAfterLogin(BuildContext context, WidgetRef ref) {
  if (AuthNavigation.isSigningOut) return;

  final profile = ref.read(currentUserProfileProvider).valueOrNull;
  if (profile == null) return;

  context.go(UserRole.homeRouteFor(profile.role));
}
