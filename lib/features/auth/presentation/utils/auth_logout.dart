import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../providers/auth_provider.dart';
import 'auth_navigation.dart';

/// Đăng xuất an toàn:
/// 1. Đóng drawer
/// 2. Chuyển sang `/login` qua root navigator
/// 3. Đợi MapScreen dispose xong
/// 4. Gọi Firebase signOut
///
/// Không dùng [ref] sau bước điều hướng — widget gọi logout có thể đã dispose.
Future<void> performSignOut(
  WidgetRef ref,
  BuildContext context,
) async {
  final authService = ref.read(authServiceProvider);
  ref.read(authLoadingProvider.notifier).state = false;

  final scaffoldState = Scaffold.maybeOf(context);
  if (scaffoldState?.isDrawerOpen == true) {
    scaffoldState!.closeDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  AuthNavigation.isSigningOut = true;
  try {
    final routerContext = rootNavigatorKey.currentContext ?? context;
    if (routerContext.mounted) {
      GoRouter.of(routerContext).go('/login');
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;

    await authService.signOut();
  } finally {
    AuthNavigation.isSigningOut = false;
  }
}
