import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_participation_model.dart';

class ParticipationException implements Exception {
  ParticipationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ParticipationFirestoreDataSource {
  ParticipationFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String participationDocId(String eventId, String userId) =>
      '${eventId}_$userId';

  Stream<List<EventParticipationModel>> watchUserParticipations(
    String userId,
  ) {
    return _firestore
        .collection('event_participations')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventParticipationModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<EventParticipationModel?> getUserParticipation({
    required String eventId,
    required String userId,
  }) async {
    final snapshot = await _firestore
        .collection('event_participations')
        .doc(participationDocId(eventId, userId))
        .get();
    if (!snapshot.exists) return null;
    return EventParticipationModel.fromFirestore(snapshot);
  }

  Future<void> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String? userEmail,
  }) async {
    final participationRef = _firestore
        .collection('event_participations')
        .doc(participationDocId(eventId, userId));
    final eventRef = _firestore.collection('events').doc(eventId);

    await _firestore.runTransaction((transaction) async {
      final eventSnap = await transaction.get(eventRef);
      if (!eventSnap.exists) {
        throw ParticipationException('Sự kiện không tồn tại.');
      }

      final eventData = eventSnap.data() ?? {};
      final capacity = (eventData['capacity'] as num?)?.toInt() ?? 0;
      final registeredCount =
          (eventData['registered_count'] as num?)?.toInt() ??
              (eventData['registeredCount'] as num?)?.toInt() ??
              0;

      final participationSnap = await transaction.get(participationRef);
      if (participationSnap.exists) {
        final status = participationSnap.data()?['status']?.toString() ?? '';
        if (status == ParticipationStatus.registered.firestoreValue) {
          throw ParticipationException('Bạn đã đăng ký sự kiện này.');
        }
        if (status == ParticipationStatus.attended.firestoreValue ||
            status == ParticipationStatus.absent.firestoreValue) {
          throw ParticipationException(
            'Không thể đăng ký lại sự kiện đã tham dự hoặc vắng mặt.',
          );
        }
      }

      if (capacity > 0 && registeredCount >= capacity) {
        throw ParticipationException('Sự kiện đã đủ số lượng đăng ký.');
      }

      final shouldIncrement = !participationSnap.exists ||
          participationSnap.data()?['status']?.toString() ==
              ParticipationStatus.cancelled.firestoreValue;

      transaction.set(
        participationRef,
        {
          'event_id': eventId,
          'user_id': userId,
          'user_name': userName,
          if (userEmail != null && userEmail.isNotEmpty)
            'user_email': userEmail,
          'status': ParticipationStatus.registered.firestoreValue,
          'registered_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'cancelled_at': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );

      if (shouldIncrement) {
        transaction.update(eventRef, {
          'registered_count': registeredCount + 1,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> cancelRegistration({
    required String eventId,
    required String userId,
  }) async {
    final participationRef = _firestore
        .collection('event_participations')
        .doc(participationDocId(eventId, userId));
    final eventRef = _firestore.collection('events').doc(eventId);

    await _firestore.runTransaction((transaction) async {
      final participationSnap = await transaction.get(participationRef);
      if (!participationSnap.exists) {
        throw ParticipationException('Không tìm thấy đăng ký của bạn.');
      }

      final status =
          participationSnap.data()?['status']?.toString() ?? '';
      if (status != ParticipationStatus.registered.firestoreValue) {
        throw ParticipationException('Chỉ có thể hủy đăng ký đang active.');
      }

      final eventSnap = await transaction.get(eventRef);
      final eventData = eventSnap.data() ?? {};
      final registeredCount =
          (eventData['registered_count'] as num?)?.toInt() ??
              (eventData['registeredCount'] as num?)?.toInt() ??
              0;

      transaction.update(participationRef, {
        'status': ParticipationStatus.cancelled.firestoreValue,
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      transaction.update(eventRef, {
        'registered_count': registeredCount > 0 ? registeredCount - 1 : 0,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
