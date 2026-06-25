import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/auth_gate.dart';
import '../features/auth/presentation/screens/profile_edit_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileEditScreen(),
    ),
  ],
);