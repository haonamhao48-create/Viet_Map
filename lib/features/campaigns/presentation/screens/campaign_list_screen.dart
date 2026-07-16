import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/campaign_provider.dart';
import '../widgets/campaign_card.dart';

class CampaignListScreen extends ConsumerStatefulWidget {
  const CampaignListScreen({super.key});

  @override
  ConsumerState<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends ConsumerState<CampaignListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(campaignSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campaignsAsync = ref.watch(filteredCampaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chiến dịch tuyển sinh'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sự kiện của tôi',
            onPressed: () => context.push('/my-events'),
            icon: const Icon(Icons.event_note_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm chiến dịch...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(campaignSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: campaignsAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Đang tải chiến dịch...',
              ),
              error: (error, _) => _ErrorState(
                message: 'Không thể tải chiến dịch.\n$error',
                onRetry: () => ref.invalidate(campaignsStreamProvider),
              ),
              data: (campaigns) {
                if (campaigns.isEmpty) {
                  final searchQuery =
                      ref.read(campaignSearchQueryProvider).trim();
                  return _EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'Chưa có chiến dịch',
                    subtitle: searchQuery.isEmpty
                        ? 'Các chiến dịch sẽ hiển thị tại đây.'
                        : 'Không tìm thấy chiến dịch phù hợp.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(campaignsStreamProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return CampaignCard(
                        campaign: campaign,
                        onTap: () => context.push('/campaigns/${campaign.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/my-events'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('Sự kiện của tôi'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
