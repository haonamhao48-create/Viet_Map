import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/user_role.dart';
import '../providers/auth_provider.dart';

/// Chỉ cho phép tài khoản role `user`. Admin được chuyển sang `/admin`.
class UserRoleGate extends ConsumerWidget {
  const UserRoleGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Lỗi tải hồ sơ: $error')),
      ),
      data: (profile) {
        if (profile == null) {
          return _RedirectMessage(
            title: 'Yêu cầu đăng nhập',
            message: 'Vui lòng đăng nhập để tiếp tục.',
            buttonLabel: 'Về trang đăng nhập',
            onPressed: () => context.go('/login'),
          );
        }

        if (UserRole.isAdmin(profile.role)) {
          _redirectTo(context, '/admin');
          return const _RedirectLoading();
        }

        if (!UserRole.isUser(profile.role)) {
          return _RedirectMessage(
            title: 'Không có quyền truy cập',
            message: 'Vai trò "${profile.role}" chưa được hỗ trợ trên ứng dụng này.',
            buttonLabel: 'Về trang đăng nhập',
            onPressed: () => context.go('/login'),
          );
        }

        return child;
      },
    );
  }
}

/// Chỉ cho phép tài khoản role `admin`. User được chuyển sang `/home`.
class AdminRoleGate extends ConsumerWidget {
  const AdminRoleGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Lỗi tải hồ sơ: $error')),
      ),
      data: (profile) {
        if (profile == null) {
          return _RedirectMessage(
            title: 'Yêu cầu đăng nhập',
            message: 'Vui lòng đăng nhập để tiếp tục.',
            buttonLabel: 'Về trang đăng nhập',
            onPressed: () => context.go('/login'),
          );
        }

        if (UserRole.isUser(profile.role)) {
          _redirectTo(context, '/home');
          return const _RedirectLoading();
        }

        if (!UserRole.isAdmin(profile.role)) {
          return _RedirectMessage(
            title: 'Không có quyền truy cập',
            message: 'Vai trò "${profile.role}" chưa được hỗ trợ trên khu vực quản trị.',
            buttonLabel: 'Về trang đăng nhập',
            onPressed: () => context.go('/login'),
          );
        }

        return child;
      },
    );
  }
}

void _redirectTo(BuildContext context, String route) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      context.go(route);
    }
  });
}

class _RedirectLoading extends StatelessWidget {
  const _RedirectLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RedirectMessage extends StatelessWidget {
  const _RedirectMessage({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
