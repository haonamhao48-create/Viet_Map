import '../datasources/participation_firestore_datasource.dart';
import '../models/event_participation_model.dart';

class ParticipationRepository {
  ParticipationRepository(this._dataSource);

  final ParticipationFirestoreDataSource _dataSource;

  Stream<List<EventParticipationModel>> watchUserParticipations(String userId) =>
      _dataSource.watchUserParticipations(userId);

  Future<EventParticipationModel?> getUserParticipation({
    required String eventId,
    required String userId,
  }) =>
      _dataSource.getUserParticipation(eventId: eventId, userId: userId);

  Future<void> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String? userEmail,
  }) =>
      _dataSource.registerForEvent(
        eventId: eventId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );

  Future<void> cancelRegistration({
    required String eventId,
    required String userId,
  }) =>
      _dataSource.cancelRegistration(eventId: eventId, userId: userId);

  Stream<List<EventParticipationModel>> watchEventParticipations(String eventId) =>
      _dataSource.watchEventParticipations(eventId);

  Stream<List<EventParticipationModel>> watchAllParticipations() =>
      _dataSource.watchAllParticipations();

  Future<void> confirmAttendance(String participationId) =>
      _dataSource.confirmAttendance(participationId);

  Future<void> markAbsent(String participationId) =>
      _dataSource.markAbsent(participationId);

  Future<void> checkIn(String eventId, String userId) =>
      _dataSource.checkIn(eventId, userId);
}
