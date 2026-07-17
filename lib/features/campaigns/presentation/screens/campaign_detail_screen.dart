import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/models/event_model.dart';
import '../providers/campaign_provider.dart';
import '../utils/date_formatters.dart';
import '../widgets/event_card.dart';
import '../widgets/status_chip.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final eventsAsync = ref.watch(filteredCampaignEventsProvider(campaignId));
    final filter = ref.watch(eventFilterStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chiến dịch'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: campaignAsync.when(
        loading: () => const AppLoadingIndicator(
          message: 'Đang tải chiến dịch...',
        ),
        error: (error, _) => Center(child: Text('Lỗi: $error')),
        data: (campaign) {
          if (campaign == null) {
            return const Center(child: Text('Không tìm thấy chiến dịch.'));
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(campaignDetailProvider(campaignId));
                    ref.invalidate(campaignEventsProvider(campaignId));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (campaign.bannerUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              campaign.bannerUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF0F766E)
                                    .withValues(alpha: 0.08),
                                child: const Icon(Icons.campaign_outlined),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              campaign.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          CampaignStatusChip(status: campaign.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatEventDateRange(
                          campaign.startDate,
                          campaign.endDate,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        campaign.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Danh sách sự kiện',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Tất cả'),
                              selected: filter == null,
                              onSelected: (_) {
                                ref
                                    .read(eventFilterStatusProvider.notifier)
                                    .state = null;
                              },
                            ),
                            const SizedBox(width: 8),
                            ...EventStatus.values
                                .where((status) => status != EventStatus.unknown)
                                .map(
                                  (status) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(status.label),
                                      selected: filter == status,
                                      onSelected: (_) {
                                        ref
                                            .read(
                                              eventFilterStatusProvider.notifier,
                                            )
                                            .state = status;
                                      },
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      eventsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: AppLoadingIndicator(
                            message: 'Đang tải sự kiện...',
                          ),
                        ),
                        error: (error, _) => Text('Lỗi tải sự kiện: $error'),
                        data: (events) {
                          if (events.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('Chưa có sự kiện trong chiến dịch này.'),
                            );
                          }

                          return Column(
                            children: events
                                .map(
                                  (event) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: EventCard(
                                      event: event,
                                      onTap: () async {
                                        await context.push(
                                          '/events/${event.id}',
                                        );
                                      },
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
