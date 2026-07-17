import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campaign_model.dart';

class CampaignFirestoreDataSource {
  CampaignFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CampaignModel>> watchCampaigns() {
    return _firestore
        .collection('campaigns')
        .orderBy('start_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CampaignModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<CampaignModel?> getCampaignById(String id) async {
    final snapshot =
        await _firestore.collection('campaigns').doc(id).get();
    if (!snapshot.exists) return null;
    return CampaignModel.fromFirestore(snapshot);
  }

  Future<void> createCampaign(CampaignModel campaign) async {
    final docRef = campaign.id.isEmpty
        ? _firestore.collection('campaigns').doc()
        : _firestore.collection('campaigns').doc(campaign.id);
    await docRef.set(campaign.copyWith(id: docRef.id).toFirestore());
  }

  Future<void> updateCampaign(CampaignModel campaign) async {
    await _firestore
        .collection('campaigns')
        .doc(campaign.id)
        .update(campaign.toFirestore());
  }

  Future<void> deleteCampaign(String id) async {
    await _firestore.collection('campaigns').doc(id).delete();
  }
}
