import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/campaign_provider.dart';
import '../utils/date_formatters.dart';
import '../widgets/status_chip.dart';

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(myEventsTabProvider);
    final myEventsAsync = ref.watch(filteredMyEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sự kiện của tôi'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: MyEventsTab.values
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: tab == item,
                        onSelected: (_) {
                          ref.read(myEventsTabProvider.notifier).state = item;
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          Expanded(
            child: myEventsAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Đang tải sự kiện của bạn...',
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _myEventsErrorMessage(error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          ref.invalidate(myEventsWithDetailsProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Không có sự kiện trong mục "${tab.label}".',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myEventsWithDetailsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final event = item.event;

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => context.push('/events/${item.eventId}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event?.title ?? 'Sự kiện #${item.eventId}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    ParticipationStatusChip(
                                      status: item.status,
                                    ),
                                  ],
                                ),
                                if (event?.schoolName.isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    event!.schoolName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  formatEventDateRange(
                                    event?.startDate,
                                    event?.endDate,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (item.registeredAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Đăng ký lúc: ${formatEventDate(item.registeredAt)}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _myEventsErrorMessage(Object error) {
  final message = error.toString().toLowerCase();
  if (message.contains('permission-denied')) {
    return 'Không có quyền đọc event_participations.\n'
        'Deploy firestore.rules lên Firebase và đảm bảo mỗi document '
        'có field user_id (hoặc userId) = UID của bạn.';
  }
  return 'Lỗi: $error';
}
