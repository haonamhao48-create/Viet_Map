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

  EventModel copyWith({
    String? id,
    String? campaignId,
    String? title,
    String? description,
    String? imageUrl,
    String? schoolId,
    String? schoolName,
    String? address,
    int? capacity,
    int? registeredCount,
    EventStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      address: address ?? this.address,
      capacity: capacity ?? this.capacity,
      registeredCount: registeredCount ?? this.registeredCount,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'campaign_id': campaignId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'school_id': schoolId,
      'school_name': schoolName,
      'address': address,
      'capacity': capacity,
      'registered_count': registeredCount,
      'status': status.firestoreValue,
      'start_date': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'end_date': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
