import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/firestore_parsers.dart';

enum CampaignStatus {
  draft,
  active,
  completed,
  cancelled,
  unknown;

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case CampaignStatus.draft:
        return 'Nháp';
      case CampaignStatus.active:
        return 'Đang diễn ra';
      case CampaignStatus.completed:
        return 'Đã kết thúc';
      case CampaignStatus.cancelled:
        return 'Đã hủy';
      case CampaignStatus.unknown:
        return 'Không xác định';
    }
  }

  static CampaignStatus fromFirestore(String? value) {
    if (value == null || value.isEmpty) return CampaignStatus.unknown;
    return CampaignStatus.values.firstWhere(
      (item) => item.name == value.toLowerCase(),
      orElse: () => CampaignStatus.unknown,
    );
  }
}

class CampaignModel {
  const CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.bannerUrl,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String bannerUrl;
  final CampaignStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CampaignModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return CampaignModel(
      id: snapshot.id,
      title: readFirestoreString(data, ['title', 'name']),
      description: readFirestoreString(data, ['description', 'content']),
      bannerUrl: readFirestoreString(
        data,
        ['banner_url', 'bannerUrl', 'image_url', 'imageUrl'],
      ),
      status: CampaignStatus.fromFirestore(
        readFirestoreString(data, ['status']),
      ),
      startDate: parseFirestoreDate(data['start_date'] ?? data['startDate']),
      endDate: parseFirestoreDate(data['end_date'] ?? data['endDate']),
      createdAt: parseFirestoreDate(data['created_at'] ?? data['createdAt']),
      updatedAt: parseFirestoreDate(data['updated_at'] ?? data['updatedAt']),
    );
  }
}
