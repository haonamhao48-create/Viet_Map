import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/tourism_local_datasource.dart';
import '../../data/models/province_model.dart';
import '../../data/models/tourism_destination_model.dart';
import '../providers/province_provider.dart';
import '../screens/travel_places_screen.dart';
import 'map_explorer_panel.dart';

class ProvinceMapCanvas extends ConsumerStatefulWidget {
  const ProvinceMapCanvas({super.key, this.isMobile = false});

  final bool isMobile;

  @override
  ConsumerState<ProvinceMapCanvas> createState() => _ProvinceMapCanvasState();
}

class _ProvinceMapCanvasState extends ConsumerState<ProvinceMapCanvas> {
  static const double _mapPadding = 28;
  static const int _hoverSuspendAfterTransformMs = 90;

  late final TransformationController _transformationController;
  late final Future<List<TourismDestinationModel>> _tourismFuture;
  ProvinceMapScene? _scene;
  Size _viewportSize = Size.zero;
  DateTime? _lastTransformAt;

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
    final matchingIds = ref.watch(matchingProvinceIdsProvider);
    final selectedRegion = ref.watch(selectedRegionFilterProvider);
    final hasActiveFilter =
        ref.watch(provinceSearchQueryProvider).trim().isNotEmpty ||
        selectedRegion != null;

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
            return MouseRegion(
              onExit: (_) {
                ref.read(hoveredProvinceIdProvider.notifier).state = null;
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
                        transformationController: _transformationController,
                        minScale: 1,
                        maxScale: 18,
                        boundaryMargin: const EdgeInsets.all(280),
                        child: SizedBox(
                          width: scene.canvasSize.width,
                          height: scene.canvasSize.height,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              isComplex: true,
                              willChange: false,
                              painter: _ProvinceMapPainter(
                                scene: scene,
                                selectedProvinceId: selectedId,
                                compareMode: compareMode,
                                firstCompareProvinceId: firstCompareId,
                                secondCompareProvinceId: secondCompareId,
                                hoveredProvinceId: hoveredId,
                                matchingProvinceIds: matchingIds,
                                selectedRegionFilter: selectedRegion,
                                hasActiveFilter: hasActiveFilter,
                                colorScheme: Theme.of(context).colorScheme,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerHover: (event) {
                          if (_shouldSuspendHover()) {
                            return;
                          }
                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );
                          final hoveredNotifier = ref.read(
                            hoveredProvinceIdProvider.notifier,
                          );
                          if (hoveredNotifier.state != provinceId) {
                            hoveredNotifier.state = provinceId;
                          }
                        },
                        onPointerDown: (event) {
                          if (featuredTravelMode) {
                            return;
                          }
                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );

                          if (provinceId == null) {
                            ref
                                    .read(selectedProvinceIdProvider.notifier)
                                    .state =
                                null;
                            return;
                          }

                          final compareMode = ref.read(compareModeProvider);

                          if (!compareMode) {
                            ref
                                    .read(selectedProvinceIdProvider.notifier)
                                    .state =
                                provinceId;
                            return;
                          }

                          final firstId = ref.read(
                            firstCompareProvinceIdProvider,
                          );
                          final secondId = ref.read(
                            secondCompareProvinceIdProvider,
                          );

                          if (firstId == provinceId) {
                            ref
                                    .read(
                                      firstCompareProvinceIdProvider.notifier,
                                    )
                                    .state =
                                null;
                            return;
                          }

                          if (secondId == provinceId) {
                            ref
                                    .read(
                                      secondCompareProvinceIdProvider.notifier,
                                    )
                                    .state =
                                null;
                            return;
                          }

                          if (firstId == null) {
                            ref
                                    .read(
                                      firstCompareProvinceIdProvider.notifier,
                                    )
                                    .state =
                                provinceId;
                          } else if (secondId == null) {
                            ref
                                    .read(
                                      secondCompareProvinceIdProvider.notifier,
                                    )
                                    .state =
                                provinceId;
                          } else {
                            ref
                                    .read(
                                      firstCompareProvinceIdProvider.notifier,
                                    )
                                    .state =
                                provinceId;
                            ref
                                    .read(
                                      secondCompareProvinceIdProvider.notifier,
                                    )
                                    .state =
                                null;
                          }
                        },
                      ),

                    ),
                    if (featuredTravelMode)
                      FutureBuilder<List<TourismDestinationModel>>(
                        future: featuredPlacesFuture,
                        builder: (context, snapshot) {
                          final places = snapshot.data ?? const <TourismDestinationModel>[];

                          return Positioned.fill(
                            child: _FeaturedTravelOverlay(
                              scene: scene,
                              places: places,
                              onOpenProvince: (province) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TravelPlacesScreen(
                                      province: province,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    if (!widget.isMobile)
                      Positioned(
                        left: 18,
                        bottom: 18,
                        child: _MapStatusBar(
                          selectedProvince: selectedProvince?.province,
                          matchCount: matchingIds.length,
                          totalCount: scene.renderProvinces.length,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Khong the tai ban do: $error')),
        );
      },
    );
  }

  void _syncScene(List<ProvinceModel> provinces) {
    if (_viewportSize.isEmpty) {
      return;
    }

    final currentScene = _scene;
    if (currentScene == null || currentScene.viewportSize != _viewportSize) {
      _scene = ProvinceMapScene.fromProvinces(
        provinces,
        _viewportSize,
        padding: _mapPadding,
      );
      _transformationController.value = Matrix4.identity();
    }
  }

  void _handleTransformChanged() {
    _lastTransformAt = DateTime.now();
  }

  bool _shouldSuspendHover() {
    final lastTransformAt = _lastTransformAt;
    if (lastTransformAt == null) {
      return false;
    }

    final elapsed = DateTime.now().difference(lastTransformAt).inMilliseconds;
    return elapsed < _hoverSuspendAfterTransformMs;
  }

  String? _provinceIdAtPosition(ProvinceMapScene scene, Offset localPosition) {
    if (_viewportSize.isEmpty) {
      return null;
    }

    final scenePoint = _transformationController.toScene(localPosition);
    String? nearestTinyProvinceId;
    double nearestTinyDistance = double.infinity;

    for (final province in scene.renderProvinces.reversed) {
      if (province.province.isDerivedArchipelago &&
          province.hoverRegion != null &&
          province.hoverRegion!.contains(scenePoint)) {
        return province.province.id;
      }

      if (province.bounds != Rect.zero &&
          !province.bounds.inflate(6).contains(scenePoint)) {
        if (!province.isTinyInteractive ||
            !province.bounds.inflate(14).contains(scenePoint)) {
          continue;
        }
      }

      for (final path in province.paths) {
        if (path.getBounds().inflate(2).contains(scenePoint) &&
            path.contains(scenePoint)) {
          return province.province.id;
        }
      }

      if (province.isTinyInteractive) {
        final expandedBounds = province.bounds.inflate(14);
        if (expandedBounds.contains(scenePoint)) {
          final distance = (scenePoint - province.bounds.center).distance;
          if (distance < nearestTinyDistance) {
            nearestTinyDistance = distance;
            nearestTinyProvinceId = province.province.id;
          }
        }
      }
    }

    return nearestTinyProvinceId;
  }
}

class _ProvinceMapPainter extends CustomPainter {
  const _ProvinceMapPainter({
    required this.scene,
    required this.selectedProvinceId,
    required this.compareMode,
    required this.firstCompareProvinceId,
    required this.secondCompareProvinceId,
    required this.hoveredProvinceId,
    required this.matchingProvinceIds,
    required this.hasActiveFilter,
    required this.colorScheme,
    required this.selectedRegionFilter,
  });

  final ProvinceMapScene scene;
  final String? selectedProvinceId;
  final bool compareMode;
  final String? firstCompareProvinceId;
  final String? secondCompareProvinceId;
  final String? hoveredProvinceId;
  final Set<String> matchingProvinceIds;
  final bool hasActiveFilter;
  final ColorScheme colorScheme;
  final String? selectedRegionFilter;

  @override
  void paint(Canvas canvas, Size size) {
    const extendedPaintInset = 2400.0;
    final extendedRect = Rect.fromLTWH(
      -extendedPaintInset,
      -extendedPaintInset,
      size.width + (extendedPaintInset * 2),
      size.height + (extendedPaintInset * 2),
    );

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFEAF6FF),
          colorScheme.surfaceContainerLowest,
          const Color(0xFFDDF3F1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(extendedRect);
    canvas.drawRect(extendedRect, backgroundPaint);

    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.14)
      ..strokeWidth = 1;

    const gridGap = 180.0;
    for (double x = 0; x <= size.width; x += gridGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (final province in scene.renderProvinces) {
      final isSelected = compareMode
          ? province.province.id == firstCompareProvinceId ||
                province.province.id == secondCompareProvinceId
          : province.province.id == selectedProvinceId;
      final isHovered = province.province.id == hoveredProvinceId;
      final isMatch = matchingProvinceIds.contains(province.province.id);
      final isRegionMatch =
          selectedRegionFilter == null ||
          province.province.macroRegion == selectedRegionFilter;
      final isArchipelago = province.province.isDerivedArchipelago;
      final baseColor = ProvinceRegionPalette.colorForRegion(
        province.province.macroRegion,
      );

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isArchipelago
            ? _archipelagoFillColor(
                baseColor: baseColor,
                isSelected: isSelected,
                isHovered: isHovered,
              )
            : _fillColor(
                baseColor: baseColor,
                isSelected: isSelected,
                isHovered: isHovered,
                isMatch: isMatch,
                isRegionMatch: isRegionMatch,
              );

      final borderPaint = Paint()
        ..color = isArchipelago
            ? _archipelagoBorderColor(
                baseColor: baseColor,
                isSelected: isSelected,
                isHovered: isHovered,
              )
            : _borderColor(
                baseColor: baseColor,
                isSelected: isSelected,
                isHovered: isHovered,
                isMatch: isMatch,
              )
        ..style = PaintingStyle.stroke
        ..strokeWidth = province.isTiny
            ? (isArchipelago
                  ? (isSelected ? 1.8 : (isHovered ? 1.5 : 1.1))
                  : (isSelected ? 3.6 : (isHovered ? 3.0 : 1.4)))
            : (isSelected ? 2.8 : (isHovered ? 2.2 : 1.1));

      for (final path in province.paths) {
        if (!province.isTinyInteractive) {
          canvas.drawShadow(
            path,
            (isSelected || isHovered)
                ? baseColor.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.08),
            province.isTiny ? 5 : 2.5,
            true,
          );
        }
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
      }

      if (province.isTiny && (isSelected || isHovered)) {
        _drawTinyProvinceHighlight(
          canvas,
          province,
          baseColor,
          isSelected: isSelected,
        );
      }

      if (province.province.isDerivedArchipelago && (isSelected || isHovered)) {
        _drawArchipelagoHoverRegion(
          canvas,
          province,
          baseColor,
          isSelected: isSelected,
        );
      }

      if (province.province.isDerivedArchipelago) {
        _drawArchipelagoPresence(
          canvas,
          province,
          baseColor,
          isSelected: isSelected,
          isHovered: isHovered,
        );
      }

      if ((isSelected || isHovered) && province.labelAnchor != null) {
        final labelText = compareMode && isSelected
            ? _compareLabelText(
                province.province.id,
                province.province.displayName,
              )
            : province.province.displayName;

        _drawProvinceLabel(canvas, province.labelAnchor!, labelText, baseColor);
      }
    }
  }

  String _compareLabelText(String provinceId, String displayName) {
    if (provinceId == firstCompareProvinceId) {
      return '1. $displayName';
    }

    if (provinceId == secondCompareProvinceId) {
      return '2. $displayName';
    }

    return displayName;
  }

  Color _fillColor({
    required Color baseColor,
    required bool isSelected,
    required bool isHovered,
    required bool isMatch,
    required bool isRegionMatch,
  }) {
    if (isSelected) {
      return baseColor.withValues(alpha: 0.72);
    }
    if (isHovered) {
      return baseColor.withValues(alpha: 0.58);
    }
    if (!isRegionMatch) {
      return baseColor.withValues(alpha: 0.10);
    }
    if (hasActiveFilter && !isMatch) {
      return baseColor.withValues(alpha: 0.18);
    }
    return baseColor.withValues(alpha: 0.46);
  }

  Color _archipelagoFillColor({
    required Color baseColor,
    required bool isSelected,
    required bool isHovered,
  }) {
    if (isSelected) {
      return baseColor.withValues(alpha: 0.92);
    }
    if (isHovered) {
      return baseColor.withValues(alpha: 0.84);
    }
    return baseColor.withValues(alpha: 0.74);
  }

  Color _borderColor({
    required Color baseColor,
    required bool isSelected,
    required bool isHovered,
    required bool isMatch,
  }) {
    if (isSelected || isHovered) {
      return baseColor;
    }
    if (hasActiveFilter && !isMatch) {
      return colorScheme.outlineVariant.withValues(alpha: 0.18);
    }
    return Colors.white.withValues(alpha: 0.92);
  }

  Color _archipelagoBorderColor({
    required Color baseColor,
    required bool isSelected,
    required bool isHovered,
  }) {
    if (isSelected) {
      return Colors.white;
    }
    if (isHovered) {
      return baseColor.withValues(alpha: 1);
    }
    return Colors.white.withValues(alpha: 0.98);
  }

  void _drawTinyProvinceHighlight(
    Canvas canvas,
    ProvinceRenderData province,
    Color baseColor, {
    required bool isSelected,
  }) {
    if (province.labelAnchor == null) {
      return;
    }

    final center = province.bounds == Rect.zero
        ? province.labelAnchor!
        : province.bounds.center;
    final haloRadius = isSelected ? 20.0 : 16.0;
    final dotRadius = isSelected ? 4.8 : 4.0;

    final haloPaint = Paint()
      ..color = baseColor.withValues(alpha: isSelected ? 0.20 : 0.14)
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final corePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.98)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, haloRadius, haloPaint);
    canvas.drawCircle(center, haloRadius * 0.62, ringPaint);
    canvas.drawCircle(center, dotRadius, corePaint);
  }

  void _drawArchipelagoPresence(
    Canvas canvas,
    ProvinceRenderData province,
    Color baseColor, {
    required bool isSelected,
    required bool isHovered,
  }) {
    if (province.bounds == Rect.zero) {
      return;
    }

    final center = province.bounds.center;
    final haloRadius = isSelected ? 22.0 : (isHovered ? 19.0 : 16.0);
    final ringRadius = isSelected ? 11.0 : (isHovered ? 9.5 : 8.0);

    final haloPaint = Paint()
      ..color = baseColor.withValues(alpha: isSelected ? 0.24 : 0.14)
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: isSelected ? 1 : 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.2 : 1.6;
    final corePaint = Paint()
      ..color = baseColor.withValues(alpha: 1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, haloRadius, haloPaint);
    canvas.drawCircle(center, ringRadius, ringPaint);
    canvas.drawCircle(center, isSelected ? 4.6 : 3.8, corePaint);
  }

  void _drawArchipelagoHoverRegion(
    Canvas canvas,
    ProvinceRenderData province,
    Color baseColor, {
    required bool isSelected,
  }) {
    final hoverRegion = province.hoverRegion;
    if (province.labelAnchor == null || hoverRegion == null) {
      return;
    }

    final center = hoverRegion.center;
    final emphasis = isSelected;
    final borderPaint = Paint()
      ..color = baseColor.withValues(alpha: emphasis ? 0.95 : 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = emphasis ? 2.8 : 2.0;
    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: emphasis ? 0.95 : 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final corePaint = Paint()
      ..color = baseColor.withValues(alpha: 1)
      ..style = PaintingStyle.fill;

    final region = RRect.fromRectAndRadius(
      hoverRegion,
      Radius.circular(hoverRegion.shortestSide * 0.18),
    );
    final innerRegion = RRect.fromRectAndRadius(
      hoverRegion.deflate(4),
      Radius.circular(
        (hoverRegion.shortestSide * 0.18).clamp(8, 24).toDouble(),
      ),
    );

    canvas.drawRRect(region, borderPaint);
    canvas.drawRRect(innerRegion, innerBorderPaint);
    canvas.drawCircle(center, emphasis ? 5.0 : 4.2, corePaint);
  }

  void _drawProvinceLabel(
    Canvas canvas,
    Offset anchor,
    String text,
    Color baseColor,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 180);

    final padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        anchor.dx - (textPainter.width / 2) - padding.horizontal / 2,
        anchor.dy - 36,
        textPainter.width + padding.horizontal,
        textPainter.height + padding.vertical,
      ),
      const Radius.circular(14),
    );

    final bubblePaint = Paint()..color = baseColor.withValues(alpha: 0.95);
    canvas.drawRRect(rect, bubblePaint);
    textPainter.paint(
      canvas,
      Offset(rect.left + padding.left, rect.top + padding.top / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ProvinceMapPainter oldDelegate) {
    return oldDelegate.scene != scene ||
        oldDelegate.selectedProvinceId != selectedProvinceId ||
        oldDelegate.compareMode != compareMode ||
        oldDelegate.firstCompareProvinceId != firstCompareProvinceId ||
        oldDelegate.secondCompareProvinceId != secondCompareProvinceId ||
        oldDelegate.hoveredProvinceId != hoveredProvinceId ||
        oldDelegate.hasActiveFilter != hasActiveFilter ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.selectedRegionFilter != selectedRegionFilter ||
        oldDelegate.matchingProvinceIds.length != matchingProvinceIds.length;

  }
}

class _MapStatusBar extends StatelessWidget {
  const _MapStatusBar({
    required this.selectedProvince,
    required this.matchCount,
    required this.totalCount,
  });

  final ProvinceModel? selectedProvince;
  final int matchCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          selectedProvince == null
              ? 'Dang hien thi $matchCount/$totalCount khu vuc'
              : 'Da chon: ${selectedProvince!.displayName}',
          style: theme.textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _FeaturedTravelOverlay extends StatelessWidget {
  const _FeaturedTravelOverlay({
    required this.scene,
    required this.places,
    required this.onOpenProvince,
  });

  final ProvinceMapScene scene;
  final List<TourismDestinationModel> places;
  final ValueChanged<ProvinceModel> onOpenProvince;

  String _normalizeProvinceName(String value) {
    return value
        .toLowerCase()
        .replaceAll('tỉnh ', '')
        .replaceAll('thành phố ', '')
        .trim();
  }

  TourismDestinationModel? _featuredPlaceForProvince(ProvinceModel province) {
    final provinceName = _normalizeProvinceName(province.displayName);

    for (final place in places) {
      if (_normalizeProvinceName(place.province) == provinceName) {
        return place;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Widget>[];

    for (final renderProvince in scene.renderProvinces) {
      final province = renderProvince.province;
      final place = _featuredPlaceForProvince(province);

      if (place == null) continue;
      if (renderProvince.bounds == Rect.zero) continue;

      final center = renderProvince.bounds.center;

      markers.add(
        Positioned(
          left: center.dx - 18,
          top: center.dy - 18,
          child: _FeaturedTravelMarker(
            province: province,
            place: place,
            onTap: () {
              onOpenProvince(province);
            },
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: markers,
      ),
    );
  }
}

class _FeaturedTravelMarker extends StatelessWidget {
  const _FeaturedTravelMarker({
    required this.province,
    required this.place,
    required this.onTap,
  });

  final ProvinceModel province;
  final TourismDestinationModel place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${place.name}\n${province.displayName}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 190),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.teal.withValues(alpha: 0.65),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.teal,
                  child: Icon(
                    Icons.place_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    place.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProvinceMapScene {
  ProvinceMapScene({
    required this.viewportSize,
    required this.canvasSize,
    required this.renderProvinces,
    required this.provinceById,
  });

  final Size viewportSize;
  final Size canvasSize;
  final List<ProvinceRenderData> renderProvinces;
  final Map<String, ProvinceRenderData> provinceById;

  factory ProvinceMapScene.fromProvinces(
    List<ProvinceModel> provinces,
    Size viewportSize, {
    double padding = 28,
  }) {
    if (provinces.isEmpty || viewportSize.isEmpty) {
      return ProvinceMapScene(
        viewportSize: viewportSize,
        canvasSize: viewportSize,
        renderProvinces: const [],
        provinceById: const {},
      );
    }

    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;

    for (final province in provinces) {
      if (province.isDerivedArchipelago) {
        continue;
      }

      for (final polygon in province.polygons) {
        for (final ring in polygon.rings) {
          for (final point in ring) {
            minLon = math.min(minLon, point.longitude);
            maxLon = math.max(maxLon, point.longitude);
            minLat = math.min(minLat, point.latitude);
            maxLat = math.max(maxLat, point.latitude);
          }
        }
      }
    }

    final lonRange = math.max(maxLon - minLon, 0.01);
    final latRange = math.max(maxLat - minLat, 0.01);
    final usableWidth = math.max(viewportSize.width - (padding * 2), 320.0);
    final usableHeight = math.max(viewportSize.height - (padding * 2), 320.0);
    final scale = math.min(usableWidth / lonRange, usableHeight / latRange);

    Offset projectMainland(double longitude, double latitude) {
      final x = ((longitude - minLon) * scale) + padding;
      final y = ((maxLat - latitude) * scale) + padding;
      return Offset(x, y);
    }

    final stagedProvinces = <_StagedProvinceRenderData>[];
    double minProjectedX = double.infinity;
    double maxProjectedX = double.negativeInfinity;
    double minProjectedY = double.infinity;
    double maxProjectedY = double.negativeInfinity;

    for (final province in provinces) {
      final paths = <Path>[];
      Rect? combinedBounds;

      for (final polygon in province.polygons) {
        final path = Path()..fillType = PathFillType.evenOdd;

        for (final ring in polygon.rings) {
          if (ring.length < 3) {
            continue;
          }

          final points = ring
              .map((point) => projectMainland(point.longitude, point.latitude))
              .toList(growable: false);

          path.moveTo(points.first.dx, points.first.dy);
          for (final point in points.skip(1)) {
            path.lineTo(point.dx, point.dy);
          }
          path.close();
        }

        if (path.getBounds() != Rect.zero) {
          final pathBounds = path.getBounds();
          paths.add(path);
          combinedBounds = combinedBounds == null
              ? pathBounds
              : combinedBounds.expandToInclude(pathBounds);
          minProjectedX = math.min(minProjectedX, pathBounds.left);
          maxProjectedX = math.max(maxProjectedX, pathBounds.right);
          minProjectedY = math.min(minProjectedY, pathBounds.top);
          maxProjectedY = math.max(maxProjectedY, pathBounds.bottom);
        }
      }

      stagedProvinces.add(
        _StagedProvinceRenderData(
          province: province,
          paths: paths,
          bounds: combinedBounds ?? Rect.zero,
        ),
      );
    }

    if (stagedProvinces.isEmpty ||
        minProjectedX == double.infinity ||
        minProjectedY == double.infinity) {
      return ProvinceMapScene(
        viewportSize: viewportSize,
        canvasSize: viewportSize,
        renderProvinces: const [],
        provinceById: const {},
      );
    }

    final translation = Offset(
      padding - minProjectedX,
      padding - minProjectedY,
    );
    final canvasSize = Size(
      math.max(
        (maxProjectedX - minProjectedX) + (padding * 2),
        viewportSize.width,
      ),
      math.max(
        (maxProjectedY - minProjectedY) + (padding * 2),
        viewportSize.height,
      ),
    );

    final renderProvinces = <ProvinceRenderData>[];
    final provinceById = <String, ProvinceRenderData>{};

    for (final stagedProvince in stagedProvinces) {
      final shiftedBounds = stagedProvince.bounds == Rect.zero
          ? Rect.zero
          : stagedProvince.bounds.shift(translation);
      final shiftedPaths = stagedProvince.paths
          .map((path) => path.shift(translation))
          .toList(growable: false);

      final renderData = ProvinceRenderData(
        province: stagedProvince.province,
        paths: shiftedPaths,
        bounds: shiftedBounds,
        labelAnchor: stagedProvince.bounds == Rect.zero
            ? null
            : Offset(shiftedBounds.center.dx, shiftedBounds.top + 14),
        hoverRegion:
            stagedProvince.province.isDerivedArchipelago &&
                stagedProvince.bounds != Rect.zero
            ? _buildArchipelagoHoverRegion(
                stagedProvince.province,
                shiftedBounds,
              )
            : null,
      );
      renderProvinces.add(renderData);
      provinceById[stagedProvince.province.id] = renderData;
    }

    return ProvinceMapScene(
      viewportSize: viewportSize,
      canvasSize: canvasSize,
      renderProvinces: renderProvinces,
      provinceById: provinceById,
    );
  }

  static Rect _buildArchipelagoHoverRegion(
    ProvinceModel province,
    Rect bounds,
  ) {
    final horizontalPadding = province.isHoangSaArchipelago ? 46.0 : 58.0;
    final verticalPadding = province.isHoangSaArchipelago ? 34.0 : 42.0;
    return bounds
        .inflate(0)
        .expandToInclude(
          Rect.fromCenter(
            center: bounds.center,
            width: math.max(bounds.width + horizontalPadding, 72),
            height: math.max(bounds.height + verticalPadding, 64),
          ),
        );
  }
}

class _StagedProvinceRenderData {
  const _StagedProvinceRenderData({
    required this.province,
    required this.paths,
    required this.bounds,
  });

  final ProvinceModel province;
  final List<Path> paths;
  final Rect bounds;
}

class ProvinceRenderData {
  const ProvinceRenderData({
    required this.province,
    required this.paths,
    required this.bounds,
    required this.labelAnchor,
    required this.hoverRegion,
  });

  final ProvinceModel province;
  final List<Path> paths;
  final Rect bounds;
  final Offset? labelAnchor;
  final Rect? hoverRegion;

  bool get isTiny {
    if (bounds == Rect.zero) {
      return false;
    }
    return bounds.width <= 18 || bounds.height <= 18;
  }

  bool get isTinyInteractive {
    if (bounds == Rect.zero) {
      return false;
    }
    return bounds.width <= 28 || bounds.height <= 28;
  }
}
