import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../utils/auth_logout.dart';

/// Avatar + tên + đăng xuất trên AppBar (desktop).
class MapAppBarUserActions extends ConsumerWidget {
  const MapAppBarUserActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return const SizedBox.shrink();
    }

    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final theme = Theme.of(context);
    final displayName =
        profile?.fullName ?? authUser.displayName ?? authUser.email ?? '';
    final avatarUrl = profile?.avatarUrl ?? authUser.photoURL;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              await context.push('/profile');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                  if (displayName.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          color: Colors.white,
          tooltip: 'Đăng xuất',
          onPressed: () => performSignOut(ref, context),
        ),
      ],
    );
  }
}

class UserAccountHeader extends ConsumerWidget {
  const UserAccountHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final theme = Theme.of(context);

    if (authUser == null) {
      return const SizedBox.shrink();
    }

    final displayName = profile?.fullName ?? authUser.displayName ?? 'Người dùng';
    final email = profile?.email ?? authUser.email ?? '';
    final avatarUrl = profile?.avatarUrl ?? authUser.photoURL;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final router = GoRouter.of(context);
                  final scaffoldState = Scaffold.maybeOf(context);

                  if (scaffoldState?.isDrawerOpen == true) {
                    scaffoldState!.closeDrawer();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  }

                  await router.push('/profile');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: avatarUrl == null
                            ? null
                            : NetworkImage(avatarUrl),
                        child: avatarUrl == null
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            Text(
                              'Chạm để chỉnh sửa hồ sơ',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF2DD4BF),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await performSignOut(ref, context);
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
