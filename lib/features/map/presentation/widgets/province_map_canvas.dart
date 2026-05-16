import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/province_model.dart';
import '../providers/province_provider.dart';
import 'map_explorer_panel.dart';

class ProvinceMapCanvas extends ConsumerStatefulWidget {
  const ProvinceMapCanvas({super.key, this.isMobile = false});

  final bool isMobile;

  @override
  ConsumerState<ProvinceMapCanvas> createState() => _ProvinceMapCanvasState();
}

class _ProvinceMapCanvasState extends ConsumerState<ProvinceMapCanvas> {
  static const double _mapPadding = 28;

  late final TransformationController _transformationController;
  ProvinceMapScene? _scene;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    final selectedId = ref.watch(selectedProvinceIdProvider);
    final hoveredId = ref.watch(hoveredProvinceIdProvider);
    final matchingIds = ref.watch(matchingProvinceIdsProvider);
    final hasActiveFilter = ref
        .watch(provinceSearchQueryProvider)
        .trim()
        .isNotEmpty;

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
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1,
                      maxScale: 18,
                      boundaryMargin: const EdgeInsets.all(280),
                      child: SizedBox(
                        width: scene.canvasSize.width,
                        height: scene.canvasSize.height,
                        child: CustomPaint(
                          painter: _ProvinceMapPainter(
                            scene: scene,
                            selectedProvinceId: selectedId,
                            hoveredProvinceId: hoveredId,
                            matchingProvinceIds: matchingIds,
                            hasActiveFilter: hasActiveFilter,
                            colorScheme: Theme.of(context).colorScheme,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerHover: (event) {
                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );
                          ref.read(hoveredProvinceIdProvider.notifier).state =
                              provinceId;
                        },
                        onPointerDown: (event) {
                          final provinceId = _provinceIdAtPosition(
                            scene,
                            event.localPosition,
                          );
                          ref.read(selectedProvinceIdProvider.notifier).state =
                              provinceId;
                        },
                      ),
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

  String? _provinceIdAtPosition(ProvinceMapScene scene, Offset localPosition) {
    if (_viewportSize.isEmpty) {
      return null;
    }

    final scenePoint = _transformationController.toScene(localPosition);

    for (final province in scene.renderProvinces.reversed) {
      for (final path in province.paths) {
        if (path.contains(scenePoint)) {
          return province.province.id;
        }
      }
    }

    return null;
  }
}

class _ProvinceMapPainter extends CustomPainter {
  const _ProvinceMapPainter({
    required this.scene,
    required this.selectedProvinceId,
    required this.hoveredProvinceId,
    required this.matchingProvinceIds,
    required this.hasActiveFilter,
    required this.colorScheme,
  });

  final ProvinceMapScene scene;
  final String? selectedProvinceId;
  final String? hoveredProvinceId;
  final Set<String> matchingProvinceIds;
  final bool hasActiveFilter;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFEAF6FF),
          colorScheme.surfaceContainerLowest,
          const Color(0xFFDDF3F1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

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
      if (province.province.isDerivedArchipelago) {
        _drawArchipelago(
          canvas,
          province,
          isSelected: province.province.id == selectedProvinceId,
          isHovered: province.province.id == hoveredProvinceId,
        );
        continue;
      }

      final isSelected = province.province.id == selectedProvinceId;
      final isHovered = province.province.id == hoveredProvinceId;
      final isMatch = matchingProvinceIds.contains(province.province.id);
      final baseColor = ProvinceRegionPalette.colorForRegion(
        province.province.macroRegion,
      );

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = _fillColor(
          baseColor: baseColor,
          isSelected: isSelected,
          isHovered: isHovered,
          isMatch: isMatch,
        );

      final borderPaint = Paint()
        ..color = _borderColor(
          baseColor: baseColor,
          isSelected: isSelected,
          isHovered: isHovered,
          isMatch: isMatch,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.8 : (isHovered ? 2.2 : 1.1);

      for (final path in province.paths) {
        canvas.drawShadow(
          path,
          Colors.black.withValues(alpha: 0.08),
          2.5,
          true,
        );
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
      }

      if ((isSelected || isHovered) && province.labelAnchor != null) {
        _drawProvinceLabel(
          canvas,
          province.labelAnchor!,
          province.province.displayName,
          baseColor,
        );
      }
    }
  }

  void _drawArchipelago(
    Canvas canvas,
    ProvinceRenderData province, {
    required bool isSelected,
    required bool isHovered,
  }) {
    final center = province.archipelagoAnchor ?? province.labelAnchor;
    if (center == null) {
      return;
    }

    final baseColor = const Color(0xFFE02424);
    final emphasis = isSelected || isHovered;
    final dotPaint = Paint()
      ..color = emphasis
          ? baseColor.withValues(alpha: 1)
          : baseColor.withValues(alpha: 0.9);

    final offsets = province.province.displayName.contains('Hoang')
        ? const [
            Offset(-14, -8),
            Offset(-2, -12),
            Offset(10, -6),
            Offset(18, 2),
            Offset(6, 10),
            Offset(-10, 8),
            Offset(0, 18),
          ]
        : const [
            Offset(-18, -6),
            Offset(-8, -18),
            Offset(8, -14),
            Offset(20, -2),
            Offset(14, 12),
            Offset(-2, 16),
            Offset(-16, 12),
          ];

    for (final offset in offsets) {
      final rect = Rect.fromCenter(
        center: center + offset,
        width: emphasis ? 8 : 6,
        height: emphasis ? 8 : 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        dotPaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: province.province.displayName,
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 180);

    final subtitlePainter = TextPainter(
      text: const TextSpan(
        text: '(Viet Nam)',
        style: TextStyle(
          color: Color(0xFF374151),
          fontSize: 12,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelOffset = province.province.displayName.contains('Hoang')
        ? const Offset(-34, -54)
        : const Offset(-18, 28);

    textPainter.paint(canvas, center + labelOffset);
    subtitlePainter.paint(
      canvas,
      center + labelOffset + Offset(4, textPainter.height - 2),
    );
  }

  Color _fillColor({
    required Color baseColor,
    required bool isSelected,
    required bool isHovered,
    required bool isMatch,
  }) {
    if (isSelected) {
      return baseColor.withValues(alpha: 0.72);
    }
    if (isHovered) {
      return baseColor.withValues(alpha: 0.58);
    }
    if (hasActiveFilter && !isMatch) {
      return baseColor.withValues(alpha: 0.18);
    }
    return baseColor.withValues(alpha: 0.46);
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
        oldDelegate.hoveredProvinceId != hoveredProvinceId ||
        oldDelegate.hasActiveFilter != hasActiveFilter ||
        oldDelegate.colorScheme != colorScheme ||
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

    final mainlandWidth = (lonRange * scale) + (padding * 2);
    final mainlandHeight = (latRange * scale) + (padding * 2);
    final archipelagoLaneWidth = math.min(viewportSize.width * 0.22, 220.0);
    final canvasSize = Size(
      mainlandWidth + archipelagoLaneWidth,
      mainlandHeight,
    );

    Offset projectMainland(double longitude, double latitude) {
      final x = ((longitude - minLon) * scale) + padding;
      final y = ((maxLat - latitude) * scale) + padding;
      return Offset(x, y);
    }

    final hoangSaAnchor = Offset(
      mainlandWidth + (archipelagoLaneWidth * 0.45),
      canvasSize.height * 0.33,
    );
    final truongSaAnchor = Offset(
      mainlandWidth + (archipelagoLaneWidth * 0.5),
      canvasSize.height * 0.74,
    );

    final renderProvinces = <ProvinceRenderData>[];
    final provinceById = <String, ProvinceRenderData>{};

    for (final province in provinces) {
      final paths = <Path>[];
      Rect? combinedBounds;
      Offset? archipelagoAnchor;

      if (!province.isDerivedArchipelago) {
        for (final polygon in province.polygons) {
          final path = Path()..fillType = PathFillType.evenOdd;

          for (final ring in polygon.rings) {
            if (ring.length < 3) {
              continue;
            }

            final points = ring
                .map(
                  (point) => projectMainland(point.longitude, point.latitude),
                )
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
          }
        }
      } else if (province.displayName.contains('Hoang')) {
        archipelagoAnchor = hoangSaAnchor;
      } else {
        archipelagoAnchor = truongSaAnchor;
      }

      final renderData = ProvinceRenderData(
        province: province,
        paths: paths,
        bounds: combinedBounds ?? Rect.zero,
        labelAnchor: combinedBounds == null
            ? archipelagoAnchor
            : Offset(combinedBounds.center.dx, combinedBounds.top + 14),
        archipelagoAnchor: archipelagoAnchor,
      );
      renderProvinces.add(renderData);
      provinceById[province.id] = renderData;
    }

    return ProvinceMapScene(
      viewportSize: viewportSize,
      canvasSize: canvasSize,
      renderProvinces: renderProvinces,
      provinceById: provinceById,
    );
  }
}

class ProvinceRenderData {
  const ProvinceRenderData({
    required this.province,
    required this.paths,
    required this.bounds,
    required this.labelAnchor,
    required this.archipelagoAnchor,
  });

  final ProvinceModel province;
  final List<Path> paths;
  final Rect bounds;
  final Offset? labelAnchor;
  final Offset? archipelagoAnchor;
}
