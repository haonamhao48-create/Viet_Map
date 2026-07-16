import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/high_school_firestore_datasource.dart';
import '../../data/models/high_school_model.dart';

final highSchoolDataSourceProvider =
Provider<HighSchoolFirestoreDataSource>((ref) {
  return HighSchoolFirestoreDataSource();
});

final schoolsProvider =
FutureProvider<List<HighSchoolModel>>((ref) async {
  final dataSource = ref.read(highSchoolDataSourceProvider);

  return dataSource.getAll();
});

final selectedSchoolIdProvider =
StateProvider<String?>((ref) => null);

final selectedSchoolProvider =
Provider<HighSchoolModel?>((ref) {
  final selectedId = ref.watch(selectedSchoolIdProvider);

  if (selectedId == null) {
    return null;
  }

  final schools =
      ref.watch(schoolsProvider).valueOrNull ?? [];

  for (final school in schools) {
    if (school.id == selectedId) {
      return school;
    }
  }

  return null;
});

final schoolSearchQueryProvider =
StateProvider<String>((ref) => '');

final filteredSchoolsProvider =
Provider<List<HighSchoolModel>>((ref) {
  final query = ref
      .watch(schoolSearchQueryProvider)
      .trim()
      .toLowerCase();

  final schools =
      ref.watch(schoolsProvider).valueOrNull ?? [];

  if (query.isEmpty) {
    return schools;
  }

  return schools.where((school) {
    return school.tenTruong
        .toLowerCase()
        .contains(query) ||
        school.diaChi
            .toLowerCase()
            .contains(query) ||
        school.tenTinhTp
            .toLowerCase()
            .contains(query);
  }).toList();
});