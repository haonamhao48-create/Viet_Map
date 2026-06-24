import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/auth_gate.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
  ],
);