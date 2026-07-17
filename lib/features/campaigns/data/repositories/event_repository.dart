import '../datasources/event_firestore_datasource.dart';
import '../models/event_model.dart';

class EventRepository {
  EventRepository(this._dataSource);

  final EventFirestoreDataSource _dataSource;

  Stream<List<EventModel>> watchEventsByCampaign(String campaignId) =>
      _dataSource.watchEventsByCampaign(campaignId);

  Future<EventModel?> getEventById(String id) => _dataSource.getEventById(id);
  
  Stream<List<EventModel>> watchAllEvents() => _dataSource.watchAllEvents();
  Future<void> createEvent(EventModel event) => _dataSource.createEvent(event);
  Future<void> updateEvent(EventModel event) => _dataSource.updateEvent(event);
  Future<void> deleteEvent(String id) => _dataSource.deleteEvent(id);
}
