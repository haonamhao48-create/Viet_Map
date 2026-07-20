import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/event_model.dart';
import '../../../map/presentation/providers/school_provider.dart';
import 'campaign_provider.dart';

enum LocationStatusType {
  loading,
  inRange,
  outOfRange,
  error,
}

class UserLocationStatus {
  final LocationStatusType type;
  final double? distance;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  const UserLocationStatus({
    required this.type,
    this.distance,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });

  const UserLocationStatus.loading()
      : type = LocationStatusType.loading,
        distance = null,
        latitude = null,
        longitude = null,
        errorMessage = null;

  const UserLocationStatus.inRange(double this.distance, double this.latitude, double this.longitude)
      : type = LocationStatusType.inRange,
        errorMessage = null;

  const UserLocationStatus.outOfRange(double this.distance, double this.latitude, double this.longitude)
      : type = LocationStatusType.outOfRange,
        errorMessage = null;

  const UserLocationStatus.error(String this.errorMessage)
      : type = LocationStatusType.error,
        distance = null,
        latitude = null,
        longitude = null;
}

final userLocationStatusProvider =
    StreamProvider.family<UserLocationStatus, String>((ref, eventId) async* {
  // 1. Get the event details to find the school ID
  final eventAsync = ref.watch(eventDetailProvider(eventId));
  final event = eventAsync.valueOrNull;
  if (event == null) {
    yield const UserLocationStatus.loading();
    return;
  }

  // 2. Lookup coordinates for the school
  final schools = ref.watch(schoolsProvider).valueOrNull ?? [];
  final school = schools.where((s) => s.id == event.schoolId).firstOrNull;

  if (school == null) {
    yield const UserLocationStatus.error('Không tìm thấy tọa độ địa điểm sự kiện.');
    return;
  }

  final targetLatLng = LatLng(school.latitude, school.longitude);

  // 3. Request location permissions
  bool serviceEnabled;
  LocationPermission permission;

  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      yield const UserLocationStatus.error('Dịch vụ định vị GPS trên thiết bị đang tắt.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        yield const UserLocationStatus.error('Quyền truy cập GPS bị từ chối.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      yield const UserLocationStatus.error('Quyền GPS bị từ chối vĩnh viễn.');
      return;
    }
  } catch (e) {
    yield UserLocationStatus.error('Lỗi khởi tạo GPS: $e');
    return;
  }

  // 4. Stream position and calculate distance
  const thresholdMeters = 200.0;
  
  // Emit initial position
  try {
    final initialPos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
    final userLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    final distance = const Distance().as(
      LengthUnit.Meter,
      userLatLng,
      targetLatLng,
    );
    if (distance <= thresholdMeters) {
      yield UserLocationStatus.inRange(distance, initialPos.latitude, initialPos.longitude);
    } else {
      yield UserLocationStatus.outOfRange(distance, initialPos.latitude, initialPos.longitude);
    }
  } catch (e) {
    // Just yield loading, position stream will try to catch updates
    yield const UserLocationStatus.loading();
  }

  final positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update every 5 meters
    ),
  );

  yield* positionStream.map((position) {
    final userLatLng = LatLng(position.latitude, position.longitude);
    final distance = const Distance().as(
      LengthUnit.Meter,
      userLatLng,
      targetLatLng,
    );

    if (distance <= thresholdMeters) {
      return UserLocationStatus.inRange(distance, position.latitude, position.longitude);
    } else {
      return UserLocationStatus.outOfRange(distance, position.latitude, position.longitude);
    }
  }).handleError((error) {
    return UserLocationStatus.error('Lỗi định vị: $error');
  });
});
