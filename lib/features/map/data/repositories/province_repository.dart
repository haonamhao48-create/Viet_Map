import '../datasources/province_local_datasource.dart';
import '../models/province_model.dart';

class ProvinceRepository {
  ProvinceRepository(this._localDataSource);

  final ProvinceLocalDataSource _localDataSource;

  Future<List<ProvinceModel>> getProvinces() {
    return _localDataSource.loadProvinces();
  }
}
