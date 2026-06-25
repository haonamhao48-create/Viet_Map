import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/school_visit_note_model.dart';

class SchoolVisitFirestoreDataSource {
  SchoolVisitFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'school_visit_notes';

  Stream<List<SchoolVisitNoteModel>> watchBySchoolId(String schoolId) {
    if (schoolId.isEmpty) {
      return Stream.value(const []);
    }

    return _firestore
        .collection(_collection)
        .where('school_id', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
          final notes = snapshot.docs
              .map(SchoolVisitNoteModel.fromFirestore)
              .toList(growable: false);
          notes.sort((a, b) => b.visitDate.compareTo(a.visitDate));
          return notes;
        });
  }

  Future<void> create(SchoolVisitNoteModel note) async {
    await _firestore.collection(_collection).add(note.toFirestore());
  }

  Future<void> delete(String noteId) async {
    await _firestore.collection(_collection).doc(noteId).delete();
  }
}
