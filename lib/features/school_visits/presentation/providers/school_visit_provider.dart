import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/school_visit_firestore_datasource.dart';
import '../../data/models/school_visit_note_model.dart';

final schoolVisitDataSourceProvider =
    Provider<SchoolVisitFirestoreDataSource>((ref) {
  return SchoolVisitFirestoreDataSource();
});

final schoolVisitNotesProvider =
    StreamProvider.family<List<SchoolVisitNoteModel>, String>((ref, schoolId) {
  return ref.watch(schoolVisitDataSourceProvider).watchBySchoolId(schoolId);
});
