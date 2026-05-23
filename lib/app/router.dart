import 'package:go_router/go_router.dart';

import '../features/map/presentation/screens/map_desktop_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MapDesktopScreen(),
    ),
  ],
);