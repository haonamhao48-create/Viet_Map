import 'package:flutter/material.dart';

import '../widgets/map_explorer_panel.dart';
import '../widgets/province_map_canvas.dart';

class MapDesktopScreen extends StatelessWidget {
  const MapDesktopScreen({super.key});

  static const double _desktopBreakpoint = 1100;
  static const double _tabletBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= _desktopBreakpoint) {
          return const Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: MapExplorerPanel(showSelectionCard: false),
                  ),
                  Expanded(child: ProvinceMapCanvas()),
                  SizedBox(width: 360, child: MapSelectionDetailsPanel()),
                ],
              ),
            ),
          );
        }

        if (width >= _tabletBreakpoint) {
          return const Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: MapExplorerPanel(
                      compact: true,
                      showSelectionCard: false,
                    ),
                  ),
                  Expanded(child: ProvinceMapCanvas()),
                  SizedBox(
                    width: 320,
                    child: MapSelectionDetailsPanel(compact: true),
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: ProvinceMapCanvas(isMobile: true)),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: MapExplorerPanel(mobileOverlay: true),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MobilePanelSheet(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobilePanelSheet extends StatelessWidget {
  const _MobilePanelSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.18,
      maxChildSize: 0.72,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: MapExplorerPanel(
            compact: true,
            embedded: true,
            scrollController: scrollController,
          ),
        );
      },
    );
  }
}
