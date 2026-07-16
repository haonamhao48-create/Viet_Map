import '../datasources/event_firestore_datasource.dart';
import '../models/event_model.dart';

class EventRepository {
  EventRepository(this._dataSource);

  final EventFirestoreDataSource _dataSource;

  Stream<List<EventModel>> watchEventsByCampaign(String campaignId) =>
      _dataSource.watchEventsByCampaign(campaignId);

  Future<EventModel?> getEventById(String id) => _dataSource.getEventById(id);
}
