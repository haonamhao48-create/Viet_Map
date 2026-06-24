import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../core/utils/text_normalizer.dart';
import '../../data/datasources/province_local_datasource.dart';
import '../../data/datasources/tourism_local_datasource.dart';
import '../../data/models/province_model.dart';
import '../../data/models/tourism_destination_model.dart';
import '../../data/repositories/province_repository.dart';
import '../../data/repositories/tourism_repository.dart';
import '../../data/datasources/commune_local_datasource.dart';
import '../../data/models/commune_model.dart';

final provinceLocalDataSourceProvider = Provider<ProvinceLocalDataSource>((
  ref,
) {
  return ProvinceLocalDataSource();
});

final provinceRepositoryProvider = Provider<ProvinceRepository>((ref) {
  final dataSource = ref.read(provinceLocalDataSourceProvider);
  return ProvinceRepository(dataSource);
});

final tourismLocalDataSourceProvider = Provider<TourismLocalDataSource>((ref) {
  return TourismLocalDataSource();
});

final tourismRepositoryProvider = Provider<TourismRepository>((ref) {
  final dataSource = ref.read(tourismLocalDataSourceProvider);
  return TourismRepository(dataSource);
});

final provincesProvider = FutureProvider<List<ProvinceModel>>((ref) async {
  final repository = ref.read(provinceRepositoryProvider);
  return repository.getProvinces();
});

final tourismDestinationsProvider =
    FutureProvider<List<TourismDestinationModel>>((ref) async {
      final repository = ref.read(tourismRepositoryProvider);
      return repository.getDestinations();
    });

final selectedProvinceIdProvider = StateProvider<String?>((ref) => null);

final selectedCommuneIdProvider = StateProvider<String?>((ref) => null);

final hoveredProvinceIdProvider = StateProvider<String?>((ref) => null);

final hoveredCommuneIdProvider = StateProvider<String?>((ref) => null);

final provinceSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredProvincesProvider = Provider<List<ProvinceModel>>((ref) {
  final provinces = ref.watch(provincesProvider).valueOrNull ?? const [];
  final selectedRegion = ref.watch(selectedRegionFilterProvider);

  final query = TextNormalizer.normalizeVietnamese(
    ref.watch(provinceSearchQueryProvider),
  );

  final filtered = provinces
      .where((province) {
    final matchesRegion =
        selectedRegion == null || province.macroRegion == selectedRegion;

    if (!matchesRegion) {
      return false;
    }

    if (query.isEmpty) {
      return true;
    }

    return province.normalizedSearchText.contains(query);
  })
      .toList(growable: false);

  filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
  return filtered;
});

final matchingProvinceIdsProvider = Provider<Set<String>>((ref) {
  return ref
      .watch(filteredProvincesProvider)
      .map((province) => province.id)
      .toSet();
});

final selectedProvinceProvider = Provider<ProvinceModel?>((ref) {
  final selectedId = ref.watch(selectedProvinceIdProvider);
  final provinces = ref.watch(provincesProvider).valueOrNull;

  if (selectedId == null || provinces == null) {
    return null;
  }

  for (final province in provinces) {
    if (province.id == selectedId) {
      return province;
    }
  }

  return null;
});

final selectedProvinceTourismProvider =
    Provider<AsyncValue<List<TourismDestinationModel>>>((ref) {
      final selectedProvince = ref.watch(selectedProvinceProvider);
      final destinationsAsync = ref.watch(tourismDestinationsProvider);

      if (selectedProvince == null) {
        return const AsyncData(<TourismDestinationModel>[]);
      }

      return destinationsAsync.whenData(
        (destinations) => destinations
            .where(
              (destination) => _matchesProvince(
                province: selectedProvince,
                tourismProvinceName: destination.province,
              ),
            )
            .toList(growable: false),
      );
    });

bool _matchesProvince({
  required ProvinceModel province,
  required String tourismProvinceName,
}) {
  final tourismKey = TextNormalizer.normalizeProvinceKey(tourismProvinceName);
  if (tourismKey.isEmpty) {
    return false;
  }

  return province.normalizedProvinceKeys.contains(tourismKey);
}

final compareModeProvider = StateProvider<bool>((ref) => false);

final firstCompareProvinceIdProvider = StateProvider<String?>((ref) => null);

final secondCompareProvinceIdProvider = StateProvider<String?>((ref) => null);

final firstCompareProvinceProvider = Provider<ProvinceModel?>((ref) {
  final id = ref.watch(firstCompareProvinceIdProvider);
  final provinces = ref.watch(provincesProvider).valueOrNull ?? [];

  if (id == null) return null;

  for (final province in provinces) {
    if (province.id == id) return province;
  }

  return null;
});

final secondCompareProvinceProvider = Provider<ProvinceModel?>((ref) {
  final id = ref.watch(secondCompareProvinceIdProvider);
  final provinces = ref.watch(provincesProvider).valueOrNull ?? [];

  if (id == null) return null;

  for (final province in provinces) {
    if (province.id == id) return province;
  }

  return null;
});

final selectedRegionFilterProvider = StateProvider<String?>((ref) => null);

final featuredTravelModeProvider = StateProvider<bool>((ref) => false);

final communeLocalDataSourceProvider = Provider<CommuneLocalDataSource>((ref) {
  return CommuneLocalDataSource();
});

final communesByProvinceProvider = FutureProvider.family<List<CommuneModel>, String>((ref, provinceId) async {
  final dataSource = ref.read(communeLocalDataSourceProvider);
  return dataSource.loadCommunesForProvince(provinceId);
});

final selectedCommuneProvider = Provider<CommuneModel?>((ref) {
  final selectedCommuneId = ref.watch(selectedCommuneIdProvider);
  final selectedProvinceId = ref.watch(selectedProvinceIdProvider);

  if (selectedCommuneId == null || selectedProvinceId == null) {
    return null;
  }

  final communes = ref.watch(communesByProvinceProvider(selectedProvinceId)).valueOrNull;
  if (communes == null) return null;

  for (final commune in communes) {
    if (commune.id == selectedCommuneId) {
      return commune;
    }
  }
  return null;
});

final communeModeProvider = StateProvider<bool>((ref) => false);
