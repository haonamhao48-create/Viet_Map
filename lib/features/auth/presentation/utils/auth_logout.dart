import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

Future<void> performSignOut(
    WidgetRef ref,
    BuildContext context,
    ) async {
  // Lấy service trước vì widget có thể bị dispose sau khi đóng Drawer.
  final authService = ref.read(authServiceProvider);

  final scaffoldState = Scaffold.maybeOf(context);

  if (scaffoldState?.isDrawerOpen == true) {
    // Không dùng Navigator.pop(context) để đóng Drawer.
    scaffoldState!.closeDrawer();

    // Đợi animation đóng Drawer hoàn tất.
    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );
  }

  // Không dùng context, ref hoặc điều hướng sau dòng này.
  await authService.signOut();
}