import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/province_provider.dart';
import '../widgets/map_explorer_panel.dart';
import '../widgets/map_canvas/province_map_canvas.dart';

class MapDesktopScreen extends ConsumerStatefulWidget {
  const MapDesktopScreen({super.key});

  @override
  ConsumerState<MapDesktopScreen> createState() => _MapDesktopScreenState();
}

class _MapDesktopScreenState extends ConsumerState<MapDesktopScreen> {
  static const double _desktopBreakpoint = 1100;
  static const double _tabletBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    // Tự động mở drawer khi chọn tỉnh/xã trên mobile
    ref.listen(selectedProvinceIdProvider, (previous, next) {
      if (next != null) {
        final width = MediaQuery.of(context).size.width;
        if (width < _tabletBreakpoint) {
          // Future.microtask ensures the Scaffold is built before opening drawer
          Future.microtask(() {
            if (!context.mounted) return;
            if (Scaffold.maybeOf(context) != null) {
               Scaffold.of(context).openDrawer();
            }
          });
        }
      }
    });
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= _desktopBreakpoint) {
          return const Scaffold(
            resizeToAvoidBottomInset: false,
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

        return const _MobileScaffold();
      },
    );
  }
}

class _MobileScaffold extends ConsumerWidget {
  const _MobileScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tự động đóng Drawer khi có lựa chọn
    ref.listen(selectedProvinceIdProvider, (previous, next) {
      if (next != null && Scaffold.maybeOf(context)?.isDrawerOpen == true) {
        Scaffold.of(context).closeDrawer();
      }
    });
    ref.listen(firstCompareProvinceIdProvider, (previous, next) {
      if (next != null && Scaffold.maybeOf(context)?.isDrawerOpen == true) {
        Scaffold.of(context).closeDrawer();
      }
    });
    ref.listen(secondCompareProvinceIdProvider, (previous, next) {
      if (next != null && Scaffold.maybeOf(context)?.isDrawerOpen == true) {
        Scaffold.of(context).closeDrawer();
      }
    });

    final selectedProvince = ref.watch(selectedProvinceProvider);
    final selectedCommune = ref.watch(selectedCommuneProvider);
    final compareMode = ref.watch(compareModeProvider);
    final firstProvince = ref.watch(firstCompareProvinceProvider);
    final secondProvince = ref.watch(secondCompareProvinceProvider);

    final bool hasSelection = compareMode
        ? (firstProvince != null || secondProvince != null)
        : (selectedProvince != null || selectedCommune != null);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const Drawer(
        child: SafeArea(
          child: MapExplorerPanel(
            compact: true,
            embedded: true,
            showSelectionCard: false,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: ProvinceMapCanvas(isMobile: true)),
            const Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: MapExplorerPanel(mobileOverlay: true),
            ),
            if (hasSelection)
              const Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _MobileSelectionPopup(),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileSelectionPopup extends ConsumerWidget {
  const _MobileSelectionPopup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.48, // Tối đa 48% chiều cao màn hình
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header có nút Đóng
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiết lựa chọn',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    final compareMode = ref.read(compareModeProvider);
                    if (compareMode) {
                      ref.read(firstCompareProvinceIdProvider.notifier).state = null;
                      ref.read(secondCompareProvinceIdProvider.notifier).state = null;
                    } else {
                      ref.read(selectedProvinceIdProvider.notifier).state = null;
                      ref.read(communeModeProvider.notifier).state = false;
                    }
                  },
                ),
              ],
            ),
          ),
          // Nội dung chi tiết cuộn được
          const Flexible(
            child: MapSelectionDetailsPanel(
              compact: true,
              mobilePopup: true,
            ),
          ),
        ],
      ),
    );
  }
}
