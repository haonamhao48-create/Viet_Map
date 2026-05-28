// ignore_for_file: unused_element
part of 'travel_places_screen.dart';

/// CustomPainter vẽ bản đồ tỉnh chi tiết với từng xã/phường.
class _DetailedProvincePainter extends CustomPainter {
  const _DetailedProvincePainter({
    required this.province,
    required this.communes,
    required this.isCommuneMode,
    required this.selectedCommuneName,
    required this.scaledCommunePaths,
    required this.scaledProvincePath,
    required this.combinedBounds,
  });

  final ProvinceModel province;
  final List<_CommuneArea> communes;
  final bool isCommuneMode;
  final String? selectedCommuneName;
  final Map<String, Path> scaledCommunePaths;
  final Path scaledProvincePath;
  final Rect? combinedBounds;

  Color _colorForCommune(String communeName, Color provinceColor) {
    final hash = communeName.hashCode;
    final hue = (hash * 137.5) % 360.0;
    return HSVColor.fromAHSV(1.0, hue, 0.45, 0.95).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (communes.isEmpty || scaledCommunePaths.isEmpty) {
      return;
    }

    final provinceColor = _colorForRegion(province.macroRegion);

    if (isCommuneMode) {
      for (final commune in communes) {
        final path = scaledCommunePaths[commune.name];
        if (path == null) continue;

        final isSelectedCommune = commune.name == selectedCommuneName;
        final communeColor = _colorForCommune(commune.name, provinceColor);

        final fillPaint = Paint()
          ..color = isSelectedCommune
              ? Colors.black.withValues(alpha: 0.70)
              : communeColor.withValues(alpha: 0.65)
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = isSelectedCommune ? Colors.black : Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelectedCommune ? 3 : 1.2;

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
      }
    } else {
      final fillPaint = Paint()
        ..color = provinceColor.withValues(alpha: 0.52)
        ..style = PaintingStyle.fill;
      canvas.drawPath(scaledProvincePath, fillPaint);
    }

    final outerBorderPaint = Paint()
      ..color = provinceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(scaledProvincePath, outerBorderPaint);

    if (combinedBounds == null) return;

    if (!isCommuneMode) {
      _drawProvinceLabel(
        canvas,
        combinedBounds!.center,
        province.displayName,
        provinceColor,
      );
    }
  }

  void _drawProvinceLabel(
    Canvas canvas,
    Offset center,
    String text,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 260);

    const padding = EdgeInsets.symmetric(horizontal: 18, vertical: 10);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 20),
        width: textPainter.width + padding.horizontal,
        height: textPainter.height + padding.vertical,
      ),
      const Radius.circular(999),
    );

    final paint = Paint()..color = color.withValues(alpha: 0.95);
    canvas.drawRRect(rect, paint);
    textPainter.paint(
      canvas,
      Offset(rect.left + padding.left, rect.top + padding.top / 2),
    );
  }

  Color _colorForRegion(String region) {
    switch (region) {
      case 'northern_midlands':
        return const Color(0xFF4C8BF5);
      case 'red_river_delta':
        return const Color(0xFF11A579);
      case 'central_coast':
        return const Color(0xFFF39C35);
      case 'central_highlands':
        return const Color(0xFF9B6D3F);
      case 'southeast':
        return const Color(0xFFE14ECA);
      case 'mekong_delta':
        return const Color(0xFF0D9488);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  bool shouldRepaint(covariant _DetailedProvincePainter oldDelegate) {
    return oldDelegate.province != province ||
        oldDelegate.communes != communes ||
        oldDelegate.isCommuneMode != isCommuneMode ||
        oldDelegate.selectedCommuneName != selectedCommuneName ||
        oldDelegate.scaledCommunePaths != scaledCommunePaths;
  }
}

/// CustomPainter vẽ nền bản đồ (gradient + lưới).
class _TravelMapBackgroundPainter extends CustomPainter {
  const _TravelMapBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE8F5F3), Color(0xFFF0F9F8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final gridPaint = Paint()
      ..color = Colors.teal.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const gridGap = 40.0;
    for (double x = 0; x <= size.width; x += gridGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
