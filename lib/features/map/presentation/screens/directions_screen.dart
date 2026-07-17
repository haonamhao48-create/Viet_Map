import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/high_school_model.dart';
import '../providers/route_provider.dart';
import '../providers/school_provider.dart';

class DirectionsScreen extends ConsumerWidget {
  const DirectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final startSchool = ref.watch(startSchoolProvider);
    final endSchool = ref.watch(endSchoolProvider);
    final routeInfo = ref.watch(routeInfoProvider);
    final selectedSchool = ref.watch(selectedSchoolProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'TÌM ĐƯỜNG ĐI',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'LỘ TRÌNH ĐƯỜNG ĐI',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 20),
            
            // Start point Card
            _RoutePointSelector(
              title: 'Điểm xuất phát',
              school: startSchool,
              icon: Icons.play_circle_fill_rounded,
              iconColor: Colors.green.shade600,
              onClear: () {
                ref.read(startSchoolProvider.notifier).state = null;
              },
              placeholder: 'Nhập tìm kiếm điểm xuất phát...',
              onSelected: (school) {
                ref.read(startSchoolProvider.notifier).state = school;
              },
            ),
            const SizedBox(height: 16),
            
            // End point Card
            _RoutePointSelector(
              title: 'Điểm kết thúc',
              school: endSchool,
              icon: Icons.flag_rounded,
              iconColor: Colors.red.shade600,
              onClear: () {
                ref.read(endSchoolProvider.notifier).state = null;
              },
              placeholder: 'Nhập tìm kiếm điểm kết thúc...',
              onSelected: (school) {
                ref.read(endSchoolProvider.notifier).state = school;
              },
            ),
            const SizedBox(height: 20),

            // Help instruction if a school is selected on map but route not complete
            if (startSchool == null && endSchool == null && selectedSchool != null) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ref.read(startSchoolProvider.notifier).state = selectedSchool;
                },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text('Chọn "${selectedSchool.tenTruong}" làm điểm xuất phát'),
              ),
              const SizedBox(height: 24),
            ],

            // Route Details Summary
            if (routeInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Khoảng cách',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${routeInfo.distanceKm.toStringAsFixed(1)} km',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        Column(
                          children: [
                            Text(
                              'Thời gian đi',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${routeInfo.durationMinutes.toStringAsFixed(0)} phút',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        context.go('/home'); // Go directly to Map tab to show the path!
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Xem lộ trình trên bản đồ'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Cancel route button
            if (startSchool != null || endSchool != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ref.read(startSchoolProvider.notifier).state = null;
                  ref.read(endSchoolProvider.notifier).state = null;
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Hủy lộ trình'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutePointSelector extends ConsumerWidget {
  const _RoutePointSelector({
    required this.title,
    required this.school,
    required this.icon,
    required this.iconColor,
    required this.onClear,
    required this.placeholder,
    required this.onSelected,
  });

  final String title;
  final HighSchoolModel? school;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onClear;
  final String placeholder;
  final ValueChanged<HighSchoolModel> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final schoolsAsync = ref.watch(schoolsProvider);
    final schools = schoolsAsync.valueOrNull ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: school != null
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              school!.tenTruong,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 20),
                            onPressed: onClear,
                          ),
                        ],
                      )
                    : Autocomplete<HighSchoolModel>(
                        displayStringForOption: (HighSchoolModel option) => option.tenTruong,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<HighSchoolModel>.empty();
                          }
                          return schools.where((HighSchoolModel option) {
                            return option.tenTruong.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                   option.diaChi.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        optionsViewBuilder: (overlayContext, onSelectedOption, options) {
                          final overlayTheme = Theme.of(overlayContext);
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(8),
                              color: overlayTheme.colorScheme.surfaceContainerLowest,
                              child: Container(
                                width: 280,
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(color: overlayTheme.colorScheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext listContext, int index) {
                                    final HighSchoolModel option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelectedOption(option),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option.tenTruong,
                                              style: overlayTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              option.diaChi,
                                              style: overlayTheme.textTheme.bodySmall?.copyWith(color: overlayTheme.colorScheme.onSurfaceVariant),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: placeholder,
                              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: InputBorder.none,
                            ),
                          );
                        },
                        onSelected: onSelected,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
