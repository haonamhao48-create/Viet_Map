import '../datasources/tourism_local_datasource.dart';
import '../models/tourism_destination_model.dart';

class TourismRepository {
  TourismRepository(this._localDataSource);

  final TourismLocalDataSource _localDataSource;

  Future<List<TourismDestinationModel>> getDestinations() {
    return _localDataSource.loadDestinations();
  }
}
