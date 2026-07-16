import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Đăng xuất an toàn: đóng drawer/dialog, về `/`, rồi mới signOut Firebase.
Future<void> performSignOut(WidgetRef ref, BuildContext context) async {
  ref.read(authLoadingProvider.notifier).state = false;

  final scaffoldState = Scaffold.maybeOf(context);
  if (scaffoldState?.isDrawerOpen ?? false) {
    Navigator.of(context).pop();
  }

  if (context.mounted) {
    context.go('/');
  }

  await Future<void>.delayed(Duration.zero);

  await ref.read(authServiceProvider).signOut();
}
