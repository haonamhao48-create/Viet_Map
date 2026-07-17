import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/top_notification.dart';

import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../campaigns/presentation/utils/date_formatters.dart';
import '../../../campaigns/presentation/widgets/status_chip.dart';

class AdminEventListScreen extends ConsumerWidget {
  const AdminEventListScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final eventsAsync = ref.watch(campaignEventsProvider(campaignId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: campaignAsync.when(
          data: (campaign) => Text('SỰ KIỆN: ${campaign?.title.toUpperCase() ?? ''}'),
          loading: () => const Text('ĐANG TẢI...'),
          error: (_, __) => const Text('LỖI'),
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Chưa có sự kiện nào trong chiến dịch này.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      await context.push('/admin/campaigns/$campaignId/events/new');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo sự kiện mới'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      EventStatusChip(status: event.status),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trường: ${event.schoolName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thời gian: ${formatEventDateRange(event.startDate, event.endDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đăng ký: ${event.registeredCount} / ${event.capacity > 0 ? event.capacity : "Không giới hạn"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: event.isFull ? Colors.red : const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.people_alt_outlined),
                        tooltip: 'Danh sách đăng ký',
                        onPressed: () async {
                          await context.push('/admin/events/${event.id}/participants');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Chỉnh sửa',
                        onPressed: () async {
                          await context.push('/admin/events/${event.id}/edit');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Xóa',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xóa sự kiện'),
                              content: const Text(
                                'Bạn có chắc chắn muốn xóa sự kiện này không? '
                                'Hành động này không thể hoàn tác.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref
                                .read(adminEventControllerProvider.notifier)
                                .delete(event.id, campaignId);
                            if (context.mounted) {
                              TopNotification.show(context, 'Đã xóa sự kiện thành công.');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    await context.push('/admin/events/${event.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push('/admin/campaigns/$campaignId/events/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm sự kiện'),
      ),
    );
  }
}
