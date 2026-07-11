import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/high_school_firestore_datasource.dart';
import '../../data/models/high_school_model.dart';

final highSchoolDataSourceProvider = Provider<HighSchoolFirestoreDataSource>((ref) {
  return HighSchoolFirestoreDataSource();
});

final schoolsProvider = FutureProvider<List<HighSchoolModel>>((ref) async {
  final dataSource = ref.watch(highSchoolDataSourceProvider);
  final schools = await dataSource.getAll();
  
  // Log thông tin để gỡ lỗi
  debugPrint('--- DEBUG FIRESTORE HIGH_SCHOOLS ---');
  debugPrint('Tổng số trường lấy về từ Firestore: ${schools.length}');
  
  final lamDongSchools = schools.where((s) {
    final nameLower = s.tenTruong.toLowerCase();
    final addressLower = s.diaChi.toLowerCase();
    final provinceLower = s.tenTinhTp.toLowerCase();
    return nameLower.contains('bảo lộc') ||
           addressLower.contains('bảo lộc') ||
           provinceLower.contains('lâm đồng') ||
           addressLower.contains('lâm đồng');
  }).toList();
  
  debugPrint('Số lượng trường ở Lâm Đồng/Bảo Lộc: ${lamDongSchools.length}');
  for (final s in lamDongSchools) {
    debugPrint('  + ${s.tenTruong} | Địa chỉ: ${s.diaChi} | Tọa độ: (${s.latitude}, ${s.longitude}) | Hợp lệ: ${s.hasValidCoordinates}');
  }
  
  final uniqueProvinces = schools.map((s) => s.tenTinhTp).toSet();
  debugPrint('Các tỉnh/thành phố có trong DB: $uniqueProvinces');
  debugPrint('------------------------------------');
  
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
