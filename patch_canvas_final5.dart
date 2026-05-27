import 'dart:io';

void main() {
  final file = File('lib/features/map/presentation/widgets/province_map_canvas.dart');
  var content = file.readAsStringSync().replaceAll('\r\n', '\n');

  // Fix renderCommunes assignment
  content = content.replaceFirst(
      "final renderCommunes = _projectCommunes(communes, scene);",
      "final renderCommunes = communeMode ? _projectCommunes(communes, scene) : <CommuneRenderData>[];"
  );

  // Add rendering logic in paint
  content = content.replaceFirst(
'''        _drawProvinceLabel(canvas, province.labelAnchor!, labelText, baseColor);
      }
    }
  }''',
'''        _drawProvinceLabel(canvas, province.labelAnchor!, labelText, baseColor);
      }
    }

    if (communes.isNotEmpty) {
      final communeBorderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      final fillPaint = Paint()..style = PaintingStyle.fill;

      for (final communeData in communes) {
        final isHovered = communeData.commune.id == hoveredCommuneId;
        final baseColor = ProvinceRegionPalette.colorForRegion(
            scene.provinceById[selectedProvinceId]?.province.macroRegion ?? 'DongBangSongHong'
        );

        if (isHovered) {
          fillPaint.color = baseColor.withValues(alpha: 0.6);
        } else {
          fillPaint.color = baseColor.withValues(alpha: 0.3);
        }

        for (final pathData in communeData.paths) {
          canvas.drawPath(pathData.path, fillPaint);
          canvas.drawPath(pathData.path, communeBorderPaint);
        }
      }
    }
  }'''
  );

  file.writeAsStringSync(content);
}
