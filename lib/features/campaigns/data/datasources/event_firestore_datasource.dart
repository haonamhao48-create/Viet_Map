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
        .orderBy('start_date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<EventModel?> getEventById(String id) async {
    final snapshot = await _firestore.collection('events').doc(id).get();
    if (!snapshot.exists) return null;
    return EventModel.fromFirestore(snapshot);
  }
}
