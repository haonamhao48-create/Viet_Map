import '../datasources/campaign_firestore_datasource.dart';
import '../models/campaign_model.dart';

class CampaignRepository {
  CampaignRepository(this._dataSource);

  final CampaignFirestoreDataSource _dataSource;

  Stream<List<CampaignModel>> watchCampaigns() => _dataSource.watchCampaigns();
  Future<CampaignModel?> getCampaignById(String id) => _dataSource.getCampaignById(id);
  
  Future<void> createCampaign(CampaignModel campaign) => _dataSource.createCampaign(campaign);
  Future<void> updateCampaign(CampaignModel campaign) => _dataSource.updateCampaign(campaign);
  Future<void> deleteCampaign(String id) => _dataSource.deleteCampaign(id);
}
