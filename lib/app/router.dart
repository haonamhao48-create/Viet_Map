import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/auth_gate.dart';
import '../features/auth/presentation/screens/profile_edit_screen.dart';
import '../features/campaigns/presentation/screens/campaign_detail_screen.dart';
import '../features/campaigns/presentation/screens/campaign_list_screen.dart';
import '../features/campaigns/presentation/screens/event_detail_screen.dart';
import '../features/campaigns/presentation/screens/my_events_screen.dart';
import '../features/campaigns/presentation/widgets/campaign_auth_gate.dart';

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
    GoRoute(
      path: '/campaigns',
      builder: (context, state) => const CampaignAuthGate(
        child: CampaignListScreen(),
      ),
    ),
    GoRoute(
      path: '/campaigns/:id',
      builder: (context, state) {
        final campaignId = state.pathParameters['id']!;
        return CampaignAuthGate(
          child: CampaignDetailScreen(campaignId: campaignId),
        );
      },
    ),
    GoRoute(
      path: '/events/:id',
      builder: (context, state) {
        final eventId = state.pathParameters['id']!;
        return CampaignAuthGate(
          child: EventDetailScreen(eventId: eventId),
        );
      },
    ),
    GoRoute(
      path: '/my-events',
      builder: (context, state) => const CampaignAuthGate(
        child: MyEventsScreen(),
      ),
    ),
  ],
);
