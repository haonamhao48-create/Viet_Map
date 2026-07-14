import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/high_school_firestore_datasource.dart';
import '../../data/models/high_school_model.dart';

final highSchoolDataSourceProvider = Provider<HighSchoolFirestoreDataSource>((ref) {
  return HighSchoolFirestoreDataSource();
});

final schoolsProvider = FutureProvider<List<HighSchoolModel>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/geojson/high_schools.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  
  final schools = jsonList.map((item) {
    final map = item as Map<String, dynamic>;
    final docId = map['id']?.toString() ?? '';
    return HighSchoolModel.fromMap(map, docId);
  }).toList()
    ..sort((a, b) => a.tenTruong.compareTo(b.tenTruong));

  return schools;
});

final selectedSchoolIdProvider = StateProvider<String?>((ref) => null);

final selectedSchoolProvider = Provider<HighSchoolModel?>((ref) {
  final selectedId = ref.watch(selectedSchoolIdProvider);
  if (selectedId == null) return null;
  
  final schools = ref.watch(schoolsProvider).valueOrNull ?? [];
  for (final school in schools) {
    if (school.id == selectedId) {
      return school;
    }
  }
  return null;
});

final schoolSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredSchoolsProvider = Provider<List<HighSchoolModel>>((ref) {
  final query = ref.watch(schoolSearchQueryProvider).trim().toLowerCase();
  final schools = ref.watch(schoolsProvider).valueOrNull ?? [];
  if (query.isEmpty) return schools;
  return schools.where((s) {
    return s.tenTruong.toLowerCase().contains(query) ||
           s.diaChi.toLowerCase().contains(query) ||
           s.tenTinhTp.toLowerCase().contains(query);
  }).toList();
});
