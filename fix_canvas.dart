import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync();

  final pattern = RegExp(r'(DateTime\?\s+_lastTransformAt;)(.*?)(transformationController:\s+_transformationController,)', dotAll: true);
  
  final replacement = '''\$1

  @override
  void initState() {
    super.initState();
    _tourismFuture = TourismLocalDataSource().loadDestinations();
    _transformationController = TransformationController();
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    final selectedId = ref.watch(selectedProvinceIdProvider);
    final featuredTravelMode = ref.watch(featuredTravelModeProvider);
    final compareMode = ref.watch(compareModeProvider);
    final firstCompareId = ref.watch(firstCompareProvinceIdProvider);
    final secondCompareId = ref.watch(secondCompareProvinceIdProvider);
    final hoveredId = ref.watch(hoveredProvinceIdProvider);
    final hoveredCommuneId = ref.watch(hoveredCommuneIdProvider);
    final matchingIds = ref.watch(matchingProvinceIdsProvider);
    final selectedRegion = ref.watch(selectedRegionFilterProvider);
    final hasActiveFilter =
        ref.watch(provinceSearchQueryProvider).trim().isNotEmpty ||
        selectedRegion != null;
    
    final communesAsync = selectedId != null ? ref.watch(communesByProvinceProvider(selectedId)) : null;
    final communes = communesAsync?.valueOrNull ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return provincesAsync.when(
          data: (provinces) {
            _syncScene(provinces);
            final scene = _scene!;
            final selectedProvince = selectedId == null
                ? null
                : scene.provinceById[selectedId];
            final featuredPlacesFuture = _tourismFuture;
            final renderCommunes = ProvinceMapScene.projectCommunes(communes, scene);

            return MouseRegion(
              onExit: (_) {
                ref.read(hoveredProvinceIdProvider.notifier).state = null;
                ref.read(hoveredCommuneIdProvider.notifier).state = null;
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerLowest,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRect(
                      child: InteractiveViewer(
                        \$3''';

  content = content.replaceFirstMapped(pattern, (match) {
    return replacement.replaceAll('\$1', match.group(1)!).replaceAll('\$3', match.group(3)!);
  });

  file.writeAsStringSync(content);
}
