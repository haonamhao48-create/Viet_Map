import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';

class EventFirestoreDataSource {
  EventFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<EventModel>> watchEventsByCampaign(String campaignId) {
    return _firestore
        .collection('events')
        .where('campaign_id', isEqualTo: campaignId)
        .snapshots()
        .map(
          (snapshot) {
            final list = snapshot.docs
                .map(EventModel.fromFirestore)
                .toList();
            // Sắp xếp theo ngày bắt đầu tăng dần (ascending)
            list.sort((a, b) {
              final aDate = a.startDate ?? DateTime.now();
              final bDate = b.endDate ?? DateTime.now();
              return aDate.compareTo(bDate);
            });
            return list;
          },
        );
  }

  Future<EventModel?> getEventById(String id) async {
    final snapshot = await _firestore.collection('events').doc(id).get();
    if (!snapshot.exists) return null;
    return EventModel.fromFirestore(snapshot);
  }

  Stream<List<EventModel>> watchAllEvents() {
    return _firestore
        .collection('events')
        .orderBy('start_date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> createEvent(EventModel event) async {
    final docRef = event.id.isEmpty
        ? _firestore.collection('events').doc()
        : _firestore.collection('events').doc(event.id);
    await docRef.set(event.copyWith(id: docRef.id).toFirestore());
  }

  Future<void> updateEvent(EventModel event) async {
    await _firestore
        .collection('events')
        .doc(event.id)
        .update(event.toFirestore());
  }

  Future<void> deleteEvent(String id) async {
    await _firestore.collection('events').doc(id).delete();
  }
}
