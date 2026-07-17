import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/route_provider.dart';

class RouteInfoCard extends ConsumerWidget {
  const RouteInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startSchool = ref.watch(startSchoolProvider);
    final endSchool = ref.watch(endSchoolProvider);
    final routeInfo = ref.watch(routeInfoProvider);
    
    if (startSchool == null || endSchool == null || routeInfo == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      color: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width >= 800 ? 340 : null,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car_rounded, color: const Color(0xFF0F766E), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'TÌM ĐƯỜNG NHANH NHẤT',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ref.read(startSchoolProvider.notifier).state = null;
                    ref.read(endSchoolProvider.notifier).state = null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Start School Line
            Row(
              children: [
                Icon(Icons.play_circle_fill_rounded, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    routeInfo.startName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 7.0),
              child: Container(
                width: 2,
                height: 16,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            // End School Line
            Row(
              children: [
                Icon(Icons.flag_rounded, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    routeInfo.endName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Route details info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Khoảng cách',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${routeInfo.distanceKm.toStringAsFixed(1)} km',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: theme.colorScheme.outlineVariant,
                ),
                Column(
                  children: [
                    Text(
                      'Thời gian đi',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${routeInfo.durationMinutes.toStringAsFixed(0)} phút',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(startSchoolProvider.notifier).state = null;
                  ref.read(endSchoolProvider.notifier).state = null;
                },
                icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                label: const Text(
                  'HỦY LỘ TRÌNH',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
