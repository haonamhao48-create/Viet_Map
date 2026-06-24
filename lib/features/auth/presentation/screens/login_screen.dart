import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authLoadingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5F3), Color(0xFFF7FCFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'VN Map App',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để khám phá bản đồ hành chính và địa điểm du lịch Việt Nam.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => _signIn(context, ref),
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          isLoading
                              ? 'Đang đăng nhập...'
                              : 'Đăng nhập bằng Google',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    ref.read(authLoadingProvider.notifier).state = true;

    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return error.message ?? 'Firebase Auth lỗi: ${error.code}';
    }

    final message = error.toString();
    if (message.contains('GOOGLE_WEB_CLIENT_ID') || message.contains('.env')) {
      return 'Chưa cấu hình GOOGLE_WEB_CLIENT_ID trong file .env. '
          'Xem docs/FIREBASE_AUTH_SETUP.md';
    }
    if (message.contains('network')) {
      return 'Lỗi mạng. Vui lòng kiểm tra kết nối internet.';
    }
    return 'Đăng nhập thất bại: $message';
  }
}
