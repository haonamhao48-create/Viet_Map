import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/high_school_model.dart';

class HighSchoolFirestoreDataSource {
  HighSchoolFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<HighSchoolModel>> getByCommuneCode(String maXaPhuong) async {
    final code = maXaPhuong.trim();
    if (code.isEmpty) {
      return const [];
    }

    final snapshot = await _firestore
        .collection('high_schools')
        .where('ma_xa_phuong', isEqualTo: code)
        .get();

    final schools = snapshot.docs
        .map(HighSchoolModel.fromFirestore)
        .where((school) => school.tenTruong.isNotEmpty)
        .toList()
      ..sort((a, b) => a.tenTruong.compareTo(b.tenTruong));

    return schools;
  }

  Future<List<HighSchoolModel>> getAll() async {
    final snapshot = await _firestore.collection('high_schools').get();

    final schools = snapshot.docs
        .map(HighSchoolModel.fromFirestore)
        .where((school) => school.tenTruong.isNotEmpty)
        .toList()
      ..sort((a, b) => a.tenTruong.compareTo(b.tenTruong));

    return schools;
  }

  Stream<List<HighSchoolModel>> streamAll() {
    return _firestore.collection('high_schools').snapshots().map((snapshot) {
      return snapshot.docs
          .map(HighSchoolModel.fromFirestore)
          .where((school) => school.tenTruong.isNotEmpty)
          .toList()
        ..sort((a, b) => a.tenTruong.compareTo(b.tenTruong));
    });
  }
}

