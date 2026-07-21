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
        .where(
          Filter.or(
            Filter('user_id', isEqualTo: userId),
            Filter('userId', isEqualTo: userId),
          ),
        )
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

    // Collect error outside the transaction to avoid "Future already completed"
    String? errorMessage;

    await _firestore.runTransaction((transaction) async {
      errorMessage = null;

      final eventSnap = await transaction.get(eventRef);
      if (!eventSnap.exists) {
        errorMessage = 'Sự kiện không tồn tại.';
        return;
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
          errorMessage = 'Bạn đã đăng ký sự kiện này.';
          return;
        }
        if (status == ParticipationStatus.attended.firestoreValue ||
            status == ParticipationStatus.absent.firestoreValue) {
          errorMessage =
              'Không thể đăng ký lại sự kiện đã tham dự hoặc vắng mặt.';
          return;
        }
      }

      if (capacity > 0 && registeredCount >= capacity) {
        errorMessage = 'Sự kiện đã đủ số lượng đăng ký.';
        return;
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

    if (errorMessage != null) {
      throw ParticipationException(errorMessage!);
    }
  }

  Future<void> cancelRegistration({
    required String eventId,
    required String userId,
  }) async {
    final participationRef = _firestore
        .collection('event_participations')
        .doc(participationDocId(eventId, userId));
    final eventRef = _firestore.collection('events').doc(eventId);

    String? errorMessage;

    await _firestore.runTransaction((transaction) async {
      errorMessage = null;

      final participationSnap = await transaction.get(participationRef);
      if (!participationSnap.exists) {
        errorMessage = 'Không tìm thấy đăng ký của bạn.';
        return;
      }

      final status =
          participationSnap.data()?['status']?.toString() ?? '';
      if (status != ParticipationStatus.registered.firestoreValue) {
        errorMessage = 'Chỉ có thể hủy đăng ký đang active.';
        return;
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

    if (errorMessage != null) {
      throw ParticipationException(errorMessage!);
    }
  }

  Stream<List<EventParticipationModel>> watchEventParticipations(
      String eventId) {
    return _firestore
        .collection('event_participations')
        .where('event_id', isEqualTo: eventId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventParticipationModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<EventParticipationModel>> watchAllParticipations() {
    return _firestore
        .collection('event_participations')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventParticipationModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> confirmAttendance(String participationId) async {
    await _firestore
        .collection('event_participations')
        .doc(participationId)
        .update({
          'status': ParticipationStatus.attended.firestoreValue,
          'updated_at': FieldValue.serverTimestamp(),
        });
  }

  Future<void> markAbsent(String participationId) async {
    await _firestore
        .collection('event_participations')
        .doc(participationId)
        .update({
          'status': ParticipationStatus.absent.firestoreValue,
          'updated_at': FieldValue.serverTimestamp(),
        });
  }

  Future<void> checkIn(String eventId, String userId, String evidenceUrl) async {
    final docId = participationDocId(eventId, userId);
    final docRef = _firestore.collection('event_participations').doc(docId);

    String? errorMessage;

    await _firestore.runTransaction((transaction) async {
      errorMessage = null;

      final snap = await transaction.get(docRef);
      if (!snap.exists) {
        errorMessage = 'Bạn chưa đăng ký sự kiện này.';
        return;
      }

      final status = snap.data()?['status']?.toString() ?? '';
      if (status == ParticipationStatus.attended.firestoreValue) {
        errorMessage = 'Bạn đã check-in sự kiện này rồi.';
        return;
      }
      if (status != ParticipationStatus.registered.firestoreValue) {
        errorMessage = 'Không thể check-in (trạng thái: $status).';
        return;
      }

      transaction.update(docRef, {
        'status': ParticipationStatus.attended.firestoreValue,
        'evidence_url': evidenceUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    if (errorMessage != null) {
      throw ParticipationException(errorMessage!);
    }
  }

  Future<void> requestCheckIn({
    required String eventId,
    required String userId,
    required String evidenceUrl,
    required double latitude,
    required double longitude,
  }) async {
    final docId = participationDocId(eventId, userId);
    final docRef = _firestore.collection('event_participations').doc(docId);

    String? errorMessage;

    await _firestore.runTransaction((transaction) async {
      errorMessage = null;

      final snap = await transaction.get(docRef);
      if (!snap.exists) {
        errorMessage = 'Bạn chưa đăng ký sự kiện này.';
        return;
      }

      final status = snap.data()?['status']?.toString() ?? '';
      if (status == ParticipationStatus.attended.firestoreValue) {
        errorMessage = 'Bạn đã check-in sự kiện này rồi.';
        return;
      }
      if (status != ParticipationStatus.registered.firestoreValue) {
        errorMessage = 'Không thể check-in (trạng thái: $status).';
        return;
      }

      transaction.update(docRef, {
        'checkin_request': {
          'latitude': latitude,
          'longitude': longitude,
          'evidence_url': evidenceUrl,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'checkin_result': {
          'status': 'verifying',
        },
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    if (errorMessage != null) {
      throw ParticipationException(errorMessage!);
    }
  }

  Stream<EventParticipationModel?> watchParticipation(String eventId, String userId) {
    final docId = participationDocId(eventId, userId);
    return _firestore
        .collection('event_participations')
        .doc(docId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? EventParticipationModel.fromFirestore(snapshot) : null);
  }
}
