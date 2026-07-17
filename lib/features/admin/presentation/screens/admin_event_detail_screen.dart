import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../campaigns/presentation/utils/date_formatters.dart';
import '../../../campaigns/presentation/widgets/status_chip.dart';
import '../../../../shared/widgets/loading_indicator.dart';

class AdminEventDetailScreen extends ConsumerWidget {
  const AdminEventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('CHI TIẾT SỰ KIỆN (ADMIN)'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: eventAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Đang tải thông tin...'),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Không tìm thấy sự kiện.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (event.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            event.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                              child: const Icon(Icons.event_outlined, size: 48),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        EventStatusChip(status: event.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    _InfoRow(
                      icon: Icons.school_outlined,
                      label: 'Trường tổ chức',
                      value: event.schoolName,
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Địa chỉ',
                      value: event.address,
                    ),
                    _InfoRow(
                      icon: Icons.date_range_outlined,
                      label: 'Thời gian',
                      value: formatEventDateRange(event.startDate, event.endDate),
                    ),
                    _InfoRow(
                      icon: Icons.people_outline_rounded,
                      label: 'Số lượng đăng ký',
                      value: '${event.registeredCount} / ${event.capacity > 0 ? event.capacity : "Không giới hạn"}',
                    ),
                  ],
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => context.push('/admin/events/${event.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Chỉnh sửa'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => context.push('/admin/events/${event.id}/participants'),
                        icon: const Icon(Icons.people_alt_outlined),
                        label: const Text('Danh sách đăng ký'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
