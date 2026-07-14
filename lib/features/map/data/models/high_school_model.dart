import 'package:cloud_firestore/cloud_firestore.dart';

class HighSchoolModel {
  const HighSchoolModel({
    required this.id,
    required this.tenTruong,
    required this.latitude,
    required this.longitude,
    required this.maXaPhuong,
    required this.maTinhTp,
    required this.tenXaPhuong,
    required this.tenTinhTp,
    required this.diaChi,
    this.khuVuc,
    this.maTruong,
    this.stt,
  });

  final String id;
  final String tenTruong;
  final double latitude;
  final double longitude;
  final String maXaPhuong;
  final String maTinhTp;
  final String tenXaPhuong;
  final String tenTinhTp;
  final String diaChi;
  final String? khuVuc;
  final String? maTruong;
  final int? stt;

  bool get hasValidCoordinates =>
      isValidVietnamCoordinate(latitude, longitude);

  static bool isValidVietnamCoordinate(double lat, double lon) {
    return lat >= 8 && lat <= 24 && lon >= 102 && lon <= 110;
  }

  factory HighSchoolModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return HighSchoolModel.fromMap(data, snapshot.id);
  }

  factory HighSchoolModel.fromMap(Map<String, dynamic> data, String docId) {
    final coordinates = _parseCoordinates(data);

    return HighSchoolModel(
      id: docId,
      tenTruong: data['ten_truong']?.toString() ?? '',
      latitude: coordinates.$1,
      longitude: coordinates.$2,
      maXaPhuong: data['ma_xa_phuong']?.toString() ?? '',
      maTinhTp: data['ma_tinh_tp']?.toString() ?? '',
      tenXaPhuong: data['ten_xa_phuong']?.toString() ?? '',
      tenTinhTp: data['ten_tinh_tp']?.toString() ?? '',
      diaChi: data['dia_chi']?.toString() ?? '',
      khuVuc: data['khu_vuc']?.toString(),
      maTruong: data['ma_truong']?.toString(),
      stt: data['stt'] != null
          ? (data['stt'] is num
              ? (data['stt'] as num).toInt()
              : int.tryParse(data['stt'].toString()))
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return 0;
    }
    // CSV nguồn dùng dấu phẩy thập phân: 106,6985
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  static (double, double) _parseCoordinates(Map<String, dynamic> data) {
    var latitude = _toDouble(
      data['latitude'] ?? data['lat'] ?? data['vi_do'] ?? data['vĩ_độ'],
    );
    var longitude = _toDouble(
      data['longitude'] ?? data['lng'] ?? data['kinh_do'] ?? data['kinh_độ'],
    );

    final location = data['location'];
    if (location is GeoPoint) {
      latitude = location.latitude;
      longitude = location.longitude;
    }

    return _normalizeForVietnam(latitude, longitude);
  }

  static (double, double) _normalizeForVietnam(double lat, double lon) {
    if (isValidVietnamCoordinate(lat, lon)) {
      return (lat, lon);
    }
    if (isValidVietnamCoordinate(lon, lat)) {
      return (lon, lat);
    }
    if (lat > 50 && lon < 50) {
      return (lon, lat);
    }
    return (lat, lon);
  }
}
