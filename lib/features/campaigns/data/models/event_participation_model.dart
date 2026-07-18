import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_parsers.dart';
import 'event_model.dart';

enum ParticipationStatus {
  registered,
  attended,
  cancelled,
  absent,
  unknown;

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case ParticipationStatus.registered:
        return 'Đã đăng ký';
      case ParticipationStatus.attended:
        return 'Đã tham dự';
      case ParticipationStatus.cancelled:
        return 'Đã hủy';
      case ParticipationStatus.absent:
        return 'Vắng mặt';
      case ParticipationStatus.unknown:
        return 'Không xác định';
    }
  }

  static ParticipationStatus fromFirestore(String? value) {
    if (value == null || value.isEmpty) return ParticipationStatus.unknown;
    return ParticipationStatus.values.firstWhere(
      (item) => item.name == value.toLowerCase(),
      orElse: () => ParticipationStatus.unknown,
    );
  }
}

class EventParticipationModel {
  const EventParticipationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.status,
    this.userEmail,
    this.registeredAt,
    this.updatedAt,
    this.cancelledAt,
    this.event,
    this.evidenceUrl,
  });

  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userEmail;
  final ParticipationStatus status;
  final DateTime? registeredAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final EventModel? event;
  final String? evidenceUrl;

  EventParticipationModel copyWith({
    EventModel? event,
    String? evidenceUrl,
  }) {
    return EventParticipationModel(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      status: status,
      registeredAt: registeredAt,
      updatedAt: updatedAt,
      cancelledAt: cancelledAt,
      event: event ?? this.event,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
    );
  }

  factory EventParticipationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    EventModel? event,
  }) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return EventParticipationModel(
      id: snapshot.id,
      eventId: readFirestoreString(data, ['event_id', 'eventId']),
      userId: readFirestoreString(data, ['user_id', 'userId']),
      userName: readFirestoreString(
        data,
        ['user_name', 'userName'],
        fallback: 'Người dùng',
      ),
      userEmail: readFirestoreString(data, ['user_email', 'userEmail']),
      status: ParticipationStatus.fromFirestore(
        readFirestoreString(data, ['status']),
      ),
      registeredAt: parseFirestoreDate(
        data['registered_at'] ?? data['registeredAt'],
      ),
      updatedAt: parseFirestoreDate(data['updated_at'] ?? data['updatedAt']),
      cancelledAt: parseFirestoreDate(
        data['cancelled_at'] ?? data['cancelledAt'],
      ),
      event: event,
      evidenceUrl: readFirestoreString(data, ['evidence_url', 'evidenceUrl']),
    );
  }

  Map<String, dynamic> toFirestoreCreate({
    required String userName,
    required String? userEmail,
  }) {
    return {
      'event_id': eventId,
      'user_id': userId,
      'user_name': userName,
      if (userEmail != null && userEmail.isNotEmpty) 'user_email': userEmail,
      'status': ParticipationStatus.registered.firestoreValue,
      'registered_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
