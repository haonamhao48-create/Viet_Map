import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/campaign_firestore_datasource.dart';
import '../../data/datasources/event_firestore_datasource.dart';
import '../../data/datasources/participation_firestore_datasource.dart';
import '../../data/models/campaign_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/event_participation_model.dart';
import '../../data/repositories/campaign_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/participation_repository.dart';

final campaignDataSourceProvider = Provider<CampaignFirestoreDataSource>((ref) {
  return CampaignFirestoreDataSource();
});

final eventDataSourceProvider = Provider<EventFirestoreDataSource>((ref) {
  return EventFirestoreDataSource();
});

final participationDataSourceProvider =
    Provider<ParticipationFirestoreDataSource>((ref) {
  return ParticipationFirestoreDataSource();
});

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository(ref.watch(campaignDataSourceProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(eventDataSourceProvider));
});

final participationRepositoryProvider = Provider<ParticipationRepository>((ref) {
  return ParticipationRepository(ref.watch(participationDataSourceProvider));
});

final campaignSearchQueryProvider = StateProvider<String>((ref) => '');

final eventFilterStatusProvider =
    StateProvider<EventStatus?>((ref) => null);

enum MyEventsTab {
  upcoming,
  registered,
  attended,
  cancelled,
  completed,
}

extension MyEventsTabX on MyEventsTab {
  String get label {
    switch (this) {
      case MyEventsTab.upcoming:
        return 'Sắp tới';
      case MyEventsTab.registered:
        return 'Đã đăng ký';
      case MyEventsTab.attended:
        return 'Đã tham dự';
      case MyEventsTab.cancelled:
        return 'Đã hủy';
      case MyEventsTab.completed:
        return 'Hoàn thành';
    }
  }
}

final myEventsTabProvider =
    StateProvider<MyEventsTab>((ref) => MyEventsTab.upcoming);

final campaignsStreamProvider = StreamProvider<List<CampaignModel>>((ref) {
  return ref.watch(campaignRepositoryProvider).watchCampaigns();
});

final filteredCampaignsProvider = Provider<AsyncValue<List<CampaignModel>>>(
  (ref) {
    final campaignsAsync = ref.watch(campaignsStreamProvider);
    final query = ref.watch(campaignSearchQueryProvider).trim().toLowerCase();

    return campaignsAsync.whenData((campaigns) {
      if (query.isEmpty) return campaigns;
      return campaigns
          .where((campaign) {
            return campaign.title.toLowerCase().contains(query) ||
                campaign.description.toLowerCase().contains(query);
          })
          .toList(growable: false);
    });
  },
);

final campaignDetailProvider =
    FutureProvider.family<CampaignModel?, String>((ref, campaignId) {
  return ref.watch(campaignRepositoryProvider).getCampaignById(campaignId);
});

final campaignEventsProvider =
    StreamProvider.family<List<EventModel>, String>((ref, campaignId) {
  return ref.watch(eventRepositoryProvider).watchEventsByCampaign(campaignId);
});

final filteredCampaignEventsProvider =
    Provider.family<AsyncValue<List<EventModel>>, String>((ref, campaignId) {
  final eventsAsync = ref.watch(campaignEventsProvider(campaignId));
  final filter = ref.watch(eventFilterStatusProvider);

  return eventsAsync.whenData((events) {
    if (filter == null) return events;
    return events
        .where((event) => event.status == filter)
        .toList(growable: false);
  });
});

final eventDetailProvider =
    FutureProvider.family<EventModel?, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).getEventById(eventId);
});

final userParticipationsProvider =
    StreamProvider<List<EventParticipationModel>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) {
    return const Stream.empty();
  }
  return ref.watch(participationRepositoryProvider).watchUserParticipations(
        userId,
      );
});

final eventParticipationProvider =
    FutureProvider.family<EventParticipationModel?, String>((ref, eventId) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return null;
  return ref.watch(participationRepositoryProvider).getUserParticipation(
        eventId: eventId,
        userId: userId,
      );
});

final myEventsWithDetailsProvider =
    StreamProvider<List<EventParticipationModel>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) {
    return Stream.value(const []);
  }

  final participationRepo = ref.watch(participationRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);

  return participationRepo.watchUserParticipations(userId).asyncMap(
    (participations) async {
      final cache = <String, EventModel>{};
      final enriched = <EventParticipationModel>[];

      for (final participation in participations) {
        var event = cache[participation.eventId];
        event ??= await eventRepo.getEventById(participation.eventId);
        if (event != null) {
          cache[participation.eventId] = event;
        }
        enriched.add(participation.copyWith(event: event));
      }

      return enriched;
    },
  );
});

List<EventParticipationModel> filterMyEvents({
  required List<EventParticipationModel> items,
  required MyEventsTab tab,
}) {
  final now = DateTime.now();

  bool isPastEvent(EventModel? event) {
    if (event?.endDate == null) return false;
    return event!.endDate!.isBefore(now);
  }

  bool isFutureEvent(EventModel? event) {
    if (event?.startDate == null) return false;
    return event!.startDate!.isAfter(now);
  }

  switch (tab) {
    case MyEventsTab.upcoming:
      return items
          .where(
            (item) =>
                item.status == ParticipationStatus.registered &&
                isFutureEvent(item.event),
          )
          .toList(growable: false);
    case MyEventsTab.registered:
      return items
          .where((item) => item.status == ParticipationStatus.registered)
          .toList(growable: false);
    case MyEventsTab.attended:
      return items
          .where((item) => item.status == ParticipationStatus.attended)
          .toList(growable: false);
    case MyEventsTab.cancelled:
      return items
          .where((item) => item.status == ParticipationStatus.cancelled)
          .toList(growable: false);
    case MyEventsTab.completed:
      return items
          .where(
            (item) =>
                isPastEvent(item.event) &&
                (item.status == ParticipationStatus.registered ||
                    item.status == ParticipationStatus.attended ||
                    item.status == ParticipationStatus.absent),
          )
          .toList(growable: false);
  }
}

final filteredMyEventsProvider =
    Provider<AsyncValue<List<EventParticipationModel>>>((ref) {
  final tab = ref.watch(myEventsTabProvider);
  final myEventsAsync = ref.watch(myEventsWithDetailsProvider);

  return myEventsAsync.whenData(
    (items) => filterMyEvents(items: items, tab: tab),
  );
});

String participationErrorMessage(Object error) {
  if (error is ParticipationException) {
    return error.message;
  }
  return error.toString();
}

final eventRegistrationControllerProvider =
    StateNotifierProvider<EventRegistrationController, AsyncValue<void>>(
  (ref) => EventRegistrationController(ref),
);

class EventRegistrationController extends StateNotifier<AsyncValue<void>> {
  EventRegistrationController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> register(String eventId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = AsyncError('Bạn cần đăng nhập.', StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    try {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      await ref.read(participationRepositoryProvider).registerForEvent(
            eventId: eventId,
            userId: user.uid,
            userName: profile?.fullName ?? user.displayName ?? 'Người dùng',
            userEmail: profile?.email ?? user.email,
          );
      ref.invalidate(eventParticipationProvider(eventId));
      ref.invalidate(eventDetailProvider(eventId));
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> cancel(String eventId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = AsyncError('Bạn cần đăng nhập.', StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    try {
      await ref.read(participationRepositoryProvider).cancelRegistration(
            eventId: eventId,
            userId: user.uid,
          );
      ref.invalidate(eventParticipationProvider(eventId));
      ref.invalidate(eventDetailProvider(eventId));
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
