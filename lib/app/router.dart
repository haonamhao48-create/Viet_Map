import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/screens/admin_campaign_form_screen.dart';
import '../features/admin/presentation/screens/admin_campaign_list_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_event_detail_screen.dart';
import '../features/admin/presentation/screens/admin_event_form_screen.dart';
import '../features/admin/presentation/screens/admin_event_list_screen.dart';
import '../features/admin/presentation/screens/admin_participants_screen.dart';
import '../features/admin/presentation/screens/admin_statistics_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_edit_screen.dart';
import '../features/auth/presentation/utils/auth_navigation.dart';
import '../features/auth/presentation/widgets/role_gate.dart';
import '../features/campaigns/presentation/screens/campaign_detail_screen.dart';
import '../features/campaigns/presentation/screens/campaign_list_screen.dart';
import '../features/campaigns/presentation/screens/event_detail_screen.dart';
import '../features/campaigns/presentation/screens/my_events_screen.dart';
import '../features/campaigns/presentation/widgets/campaign_auth_gate.dart';
import '../features/map/presentation/screens/map_screen.dart';

import '../features/map/presentation/screens/school_list_screen.dart';
import '../features/map/presentation/screens/directions_screen.dart';
import 'widgets/main_user_shell.dart';
import 'widgets/main_admin_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

bool _isUserRoute(String location) {
  return location == '/home' ||
      location.startsWith('/profile') ||
      location.startsWith('/campaigns') ||
      location.startsWith('/events') ||
      location.startsWith('/my-events');
}

bool _isAdminRoute(String location) {
  return location == '/admin' || location.startsWith('/admin/');
}

bool _isProtectedRoute(String location) {
  return _isUserRoute(location) || _isAdminRoute(location);
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final location = state.matchedLocation;

    if (location == '/') {
      return isLoggedIn ? '/home' : '/login';
    }

    if (!isLoggedIn && _isProtectedRoute(location)) {
      return '/login';
    }

    // Không tự redirect /login → /home ở đây.
    // LoginScreen sẽ điều hướng theo role sau khi tải profile.
    if (isLoggedIn && location == '/login' && !AuthNavigation.isSigningOut) {
      return null;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(key: ValueKey('login')),
    ),
    ShellRoute(
      navigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, state, child) => MainAdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminRoleGate(
            child: AdminDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/campaigns',
          builder: (context, state) => const AdminRoleGate(
            child: AdminCampaignListScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/statistics',
          builder: (context, state) => const AdminRoleGate(
            child: AdminStatisticsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/profile',
          builder: (context, state) => const AdminRoleGate(
            child: ProfileEditScreen(),
          ),
        ),
      ],
    ),
    ShellRoute(
      navigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, state, child) => MainUserShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const UserRoleGate(
            child: MapScreen(key: ValueKey('home')),
          ),
        ),
        GoRoute(
          path: '/schools',
          builder: (context, state) => const UserRoleGate(
            child: SchoolListScreen(key: ValueKey('schools')),
          ),
        ),
        GoRoute(
          path: '/directions',
          builder: (context, state) => const UserRoleGate(
            child: DirectionsScreen(key: ValueKey('directions')),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const UserRoleGate(
            child: CampaignAuthGate(
              child: ProfileEditScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/campaigns',
          builder: (context, state) => const UserRoleGate(
            child: CampaignAuthGate(
              child: CampaignListScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/my-events',
          builder: (context, state) => const UserRoleGate(
            child: CampaignAuthGate(
              child: MyEventsScreen(),
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/campaigns/:id',
      builder: (context, state) {
        final campaignId = state.pathParameters['id'];

        if (campaignId == null || campaignId.isEmpty) {
          return const UserRoleGate(
            child: CampaignAuthGate(
              child: CampaignListScreen(),
            ),
          );
        }

        return UserRoleGate(
          child: CampaignAuthGate(
            child: CampaignDetailScreen(campaignId: campaignId),
          ),
        );
      },
    ),
    GoRoute(
      path: '/events/:id',
      builder: (context, state) {
        final eventId = state.pathParameters['id'];

        if (eventId == null || eventId.isEmpty) {
          return const UserRoleGate(
            child: CampaignAuthGate(
              child: CampaignListScreen(),
            ),
          );
        }

        return UserRoleGate(
          child: CampaignAuthGate(
            child: EventDetailScreen(eventId: eventId),
          ),
        );
      },
    ),

    GoRoute(
      path: '/admin/campaigns/new',
      builder: (context, state) => const AdminRoleGate(
        child: AdminCampaignFormScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/campaigns/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AdminRoleGate(
          child: AdminCampaignFormScreen(campaignId: id),
        );
      },
    ),
    GoRoute(
      path: '/admin/campaigns/:id/events',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AdminRoleGate(
          child: AdminEventListScreen(campaignId: id ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/admin/campaigns/:id/events/new',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AdminRoleGate(
          child: AdminEventFormScreen(campaignId: id),
        );
      },
    ),
    GoRoute(
      path: '/admin/events/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AdminRoleGate(
          child: AdminEventDetailScreen(eventId: id ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/admin/events/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AdminRoleGate(
          child: AdminEventFormScreen(eventId: id),
        );
      },
    ),
    GoRoute(
      path: '/admin/events/:id/participants',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AdminRoleGate(
          child: AdminParticipantsScreen(eventId: id ?? ''),
        );
      },
    ),

  ],
);
