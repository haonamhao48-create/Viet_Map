import 'package:cloud_firestore/cloud_firestore.dart';

enum SchoolVisitPurpose {
  recruitment,
  giftVisit,
  partnership,
  survey,
  other;

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case SchoolVisitPurpose.recruitment:
        return 'Tuyển sinh';
      case SchoolVisitPurpose.giftVisit:
        return 'Thăm hỏi / tặng quà';
      case SchoolVisitPurpose.partnership:
        return 'Hợp tác';
      case SchoolVisitPurpose.survey:
        return 'Khảo sát';
      case SchoolVisitPurpose.other:
        return 'Khác';
    }
  }

  static SchoolVisitPurpose fromFirestore(String? value) {
    return SchoolVisitPurpose.values.firstWhere(
      (purpose) => purpose.name == value,
      orElse: () => SchoolVisitPurpose.other,
    );
  }
}

class SchoolVisitNoteModel {
  const SchoolVisitNoteModel({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.maXaPhuong,
    required this.authorUid,
    required this.authorName,
    required this.visitDate,
    required this.purpose,
    this.occasion,
    this.gift,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String schoolName;
  final String maXaPhuong;
  final String authorUid;
  final String authorName;
  final DateTime visitDate;
  final SchoolVisitPurpose purpose;
  final String? occasion;
  final String? gift;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SchoolVisitNoteModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return SchoolVisitNoteModel(
      id: snapshot.id,
      schoolId: data['school_id']?.toString() ?? '',
      schoolName: data['school_name']?.toString() ?? '',
      maXaPhuong: data['ma_xa_phuong']?.toString() ?? '',
      authorUid: data['author_uid']?.toString() ?? '',
      authorName: data['author_name']?.toString() ?? 'Người dùng',
      visitDate: _toDateTime(data['visit_date']) ?? DateTime.now(),
      purpose: SchoolVisitPurpose.fromFirestore(data['purpose']?.toString()),
      occasion: data['occasion']?.toString(),
      gift: data['gift']?.toString(),
      note: data['note']?.toString(),
      createdAt: _toDateTime(data['created_at']),
      updatedAt: _toDateTime(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'school_id': schoolId,
      'school_name': schoolName,
      'ma_xa_phuong': maXaPhuong,
      'author_uid': authorUid,
      'author_name': authorName,
      'visit_date': Timestamp.fromDate(visitDate),
      'purpose': purpose.firestoreValue,
      if (occasion != null && occasion!.trim().isNotEmpty)
        'occasion': occasion!.trim(),
      if (gift != null && gift!.trim().isNotEmpty) 'gift': gift!.trim(),
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
