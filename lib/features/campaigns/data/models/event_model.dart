import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_parsers.dart';

enum EventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
  unknown;

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case EventStatus.upcoming:
        return 'Sắp diễn ra';
      case EventStatus.ongoing:
        return 'Đang diễn ra';
      case EventStatus.completed:
        return 'Đã kết thúc';
      case EventStatus.cancelled:
        return 'Đã hủy';
      case EventStatus.unknown:
        return 'Không xác định';
    }
  }

  static EventStatus fromFirestore(String? value) {
    if (value == null || value.isEmpty) return EventStatus.unknown;
    return EventStatus.values.firstWhere(
      (item) => item.name == value.toLowerCase(),
      orElse: () => EventStatus.unknown,
    );
  }
}

class EventModel {
  const EventModel({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.schoolId,
    required this.schoolName,
    required this.address,
    required this.capacity,
    required this.registeredCount,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String campaignId;
  final String title;
  final String description;
  final String imageUrl;
  final String schoolId;
  final String schoolName;
  final String address;
  final int capacity;
  final int registeredCount;
  final EventStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFull => capacity > 0 && registeredCount >= capacity;

  int get remainingSlots =>
      capacity <= 0 ? 0 : (capacity - registeredCount).clamp(0, capacity);

  factory EventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return EventModel(
      id: snapshot.id,
      campaignId: readFirestoreString(
        data,
        ['campaign_id', 'campaignId'],
      ),
      title: readFirestoreString(data, ['title', 'name']),
      description: readFirestoreString(data, ['description', 'content']),
      imageUrl: readFirestoreString(
        data,
        ['image_url', 'imageUrl', 'banner_url', 'bannerUrl'],
      ),
      schoolId: readFirestoreString(data, ['school_id', 'schoolId']),
      schoolName: readFirestoreString(
        data,
        ['school_name', 'schoolName', 'ten_truong'],
      ),
      address: readFirestoreString(
        data,
        ['address', 'dia_chi', 'location'],
      ),
      capacity: parseFirestoreInt(data['capacity']),
      registeredCount: parseFirestoreInt(
        data['registered_count'] ?? data['registeredCount'],
      ),
      status: EventStatus.fromFirestore(
        readFirestoreString(data, ['status']),
      ),
      startDate: parseFirestoreDate(data['start_date'] ?? data['startDate']),
      endDate: parseFirestoreDate(data['end_date'] ?? data['endDate']),
      createdAt: parseFirestoreDate(data['created_at'] ?? data['createdAt']),
      updatedAt: parseFirestoreDate(data['updated_at'] ?? data['updatedAt']),
    );
  }
}
