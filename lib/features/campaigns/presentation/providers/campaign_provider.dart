import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../map/presentation/providers/school_provider.dart';

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
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return const Stream.empty();
  }
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
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return Stream.value(const []);
  }

  final participationRepo = ref.watch(participationRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);

  return Stream.fromFuture(user.getIdToken()).asyncExpand((_) {
    return participationRepo.watchUserParticipations(user.uid).asyncMap(
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

final adminAllEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(eventRepositoryProvider).watchAllEvents();
});

final adminEventParticipationsProvider =
    StreamProvider.family<List<EventParticipationModel>, String>((ref, eventId) {
  return ref.watch(participationRepositoryProvider).watchEventParticipations(eventId);
});

final adminCampaignControllerProvider =
    StateNotifierProvider<AdminCampaignController, AsyncValue<void>>(
  (ref) => AdminCampaignController(ref),
);

class AdminCampaignController extends StateNotifier<AsyncValue<void>> {
  AdminCampaignController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<bool> create(CampaignModel campaign) async {
    state = const AsyncLoading();
    try {
      await ref.read(campaignRepositoryProvider).createCampaign(campaign);
      state = const AsyncData(null);
      ref.invalidate(campaignsStreamProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> updateCampaign(CampaignModel campaign) async {
    state = const AsyncLoading();
    try {
      await ref.read(campaignRepositoryProvider).updateCampaign(campaign);
      state = const AsyncData(null);
      ref.invalidate(campaignsStreamProvider);
      ref.invalidate(campaignDetailProvider(campaign.id));
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    try {
      await ref.read(campaignRepositoryProvider).deleteCampaign(id);
      state = const AsyncData(null);
      ref.invalidate(campaignsStreamProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final adminEventControllerProvider =
    StateNotifierProvider<AdminEventController, AsyncValue<void>>(
  (ref) => AdminEventController(ref),
);

class AdminEventController extends StateNotifier<AsyncValue<void>> {
  AdminEventController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<bool> create(EventModel event) async {
    state = const AsyncLoading();
    try {
      await ref.read(eventRepositoryProvider).createEvent(event);
      state = const AsyncData(null);
      ref.invalidate(campaignEventsProvider(event.campaignId));
      ref.invalidate(adminAllEventsProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> updateEvent(EventModel event) async {
    state = const AsyncLoading();
    try {
      await ref.read(eventRepositoryProvider).updateEvent(event);
      state = const AsyncData(null);
      ref.invalidate(campaignEventsProvider(event.campaignId));
      ref.invalidate(eventDetailProvider(event.id));
      ref.invalidate(adminAllEventsProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> delete(String eventId, String campaignId) async {
    state = const AsyncLoading();
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(eventId);
      state = const AsyncData(null);
      ref.invalidate(campaignEventsProvider(campaignId));
      ref.invalidate(adminAllEventsProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final adminParticipationControllerProvider =
    StateNotifierProvider<AdminParticipationController, AsyncValue<void>>(
  (ref) => AdminParticipationController(ref),
);

class AdminParticipationController extends StateNotifier<AsyncValue<void>> {
  AdminParticipationController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> confirm(String participationId, String eventId) async {
    state = const AsyncLoading();
    try {
      await ref.read(participationRepositoryProvider).confirmAttendance(participationId);
      state = const AsyncData(null);
      ref.invalidate(adminEventParticipationsProvider(eventId));
      ref.invalidate(eventDetailProvider(eventId));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> markAbsent(String participationId, String eventId) async {
    state = const AsyncLoading();
    try {
      await ref.read(participationRepositoryProvider).markAbsent(participationId);
      state = const AsyncData(null);
      ref.invalidate(adminEventParticipationsProvider(eventId));
      ref.invalidate(eventDetailProvider(eventId));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final userCheckInControllerProvider =
    StateNotifierProvider<UserCheckInController, AsyncValue<void>>(
  (ref) => UserCheckInController(ref),
);

class UserCheckInController extends StateNotifier<AsyncValue<void>> {
  UserCheckInController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<bool> checkIn(String eventId, XFile imageFile) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = AsyncError('Bạn cần đăng nhập.', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    try {
      // 1. Lấy vị trí GPS hiện tại của người dùng
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 2. Kiểm tra khoảng cách tại Client (để tránh upload ảnh tốn tài nguyên nếu ở xa)
      final eventAsync = ref.read(eventDetailProvider(eventId));
      final event = eventAsync.valueOrNull;
      if (event == null) {
        throw Exception('Không tìm thấy thông tin sự kiện.');
      }

      final schools = ref.read(schoolsProvider).valueOrNull ?? [];
      final school = schools.where((s) => s.id == event.schoolId).firstOrNull;
      if (school == null) {
        throw Exception('Không tìm thấy thông tin địa điểm của sự kiện.');
      }

      final distance = const Distance().as(
        LengthUnit.Meter,
        LatLng(position.latitude, position.longitude),
        LatLng(school.latitude, school.longitude),
      );

      const thresholdMeters = 200.0;
      if (distance > thresholdMeters) {
        throw Exception('Bạn ở quá xa địa điểm sự kiện (${distance.round()}m > ${thresholdMeters.round()}m). Không thể check-in.');
      }

      // 3. Tải ảnh bằng chứng lên Firebase Storage
      final bytes = await imageFile.readAsBytes();
      final extension = imageFile.name.split('.').last;
      final storageRef = FirebaseStorage.instance.ref().child(
          'users/${user.uid}/evidence_${eventId}_${DateTime.now().millisecondsSinceEpoch}.$extension');

      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await storageRef.getDownloadURL();

      // 4. Gửi yêu cầu check-in lên Firestore (chứa toạ độ GPS)
      final repo = ref.read(participationRepositoryProvider);
      await repo.requestCheckIn(
        eventId: eventId,
        userId: user.uid,
        evidenceUrl: downloadUrl,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // 5. Chờ phản hồi xác thực từ Cloud Functions (tối đa 15 giây)
      final completer = Completer<bool>();
      StreamSubscription? subscription;

      subscription = repo.watchParticipation(eventId, user.uid).listen((participation) {
        if (participation == null) return;

        if (participation.status == ParticipationStatus.attended) {
          subscription?.cancel();
          if (!completer.isCompleted) completer.complete(true);
        } else if (participation.checkinResult != null) {
          final resultStatus = participation.checkinResult!.status;
          if (resultStatus == 'failed_invalid_location' || resultStatus == 'error') {
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                Exception(participation.checkinResult!.errorMessage ?? 'Xác thực vị trí thất bại.'),
              );
            }
          }
        }
      });

      // Bắt đầu timeout
      final success = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          subscription?.cancel();
          throw TimeoutException('Quá thời gian chờ phản hồi xác thực từ máy chủ.');
        },
      );

      state = const AsyncData(null);
      ref.invalidate(eventParticipationProvider(eventId));
      ref.invalidate(myEventsWithDetailsProvider);
      return success;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final allParticipationsProvider = StreamProvider<List<EventParticipationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(participationRepositoryProvider).watchAllParticipations();
});
