import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../campaigns/data/models/campaign_model.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../campaigns/presentation/widgets/status_chip.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsStreamProvider);
    final eventsAsync = ref.watch(adminAllEventsProvider);
    final theme = Theme.of(context);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    final mainDashboardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DASHBOARD QUẢN TRỊ',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: const Color(0xFF0F766E),
          ),
        ),
        const SizedBox(height: 24),
        
        // Summary cards
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Chiến dịch',
                  value: campaignsAsync.when(
                    data: (list) => list.length.toString(),
                    loading: () => '...',
                    error: (_, __) => 'Error',
                  ),
                  icon: Icons.campaign_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Sự kiện tuyển sinh',
                  value: eventsAsync.when(
                    data: (list) => list.length.toString(),
                    loading: () => '...',
                    error: (_, __) => 'Error',
                  ),
                  icon: Icons.event_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Tổng số lượt đăng ký',
                  value: eventsAsync.when(
                    data: (list) => list
                        .fold<int>(0, (sum, event) => sum + event.registeredCount)
                        .toString(),
                    loading: () => '...',
                    error: (_, __) => 'Error',
                  ),
                  icon: Icons.people_rounded,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _SummaryCard(
                title: 'Chiến dịch',
                value: campaignsAsync.when(
                  data: (list) => list.length.toString(),
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                icon: Icons.campaign_rounded,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Sự kiện tuyển sinh',
                value: eventsAsync.when(
                  data: (list) => list.length.toString(),
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                icon: Icons.event_rounded,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Tổng số lượt đăng ký',
                value: eventsAsync.when(
                  data: (list) => list
                      .fold<int>(0, (sum, event) => sum + event.registeredCount)
                      .toString(),
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                icon: Icons.people_rounded,
              ),
            ],
          ),
        const SizedBox(height: 32),

        // Quick actions and recent campaigns section
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _RecentCampaignsList(campaignsAsync: campaignsAsync),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _QuickActionsPanel(),
              ),
            ],
          )
        else
          Column(
            children: [
              _QuickActionsPanel(),
              const SizedBox(height: 24),
              _RecentCampaignsList(campaignsAsync: campaignsAsync),
            ],
          ),
      ],
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'VIETMAP GIS — QUẢN TRỊ',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: mainDashboardContent,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
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

class _RecentCampaignsList extends StatelessWidget {
  const _RecentCampaignsList({required this.campaignsAsync});

  final AsyncValue<List<CampaignModel>> campaignsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'CHIẾN DỊCH GẦN ĐÂY',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await context.push('/admin/campaigns');
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          campaignsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Chưa có chiến dịch nào được tạo.'),
                  ),
                );
              }
              final recent = list.take(5).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => Divider(
                  color: theme.colorScheme.outlineVariant,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = recent[index];
                  return ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: CampaignStatusChip(status: item.status),
                    onTap: () async {
                      await context.push('/admin/campaigns');
                    },
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'QUẢN TRỊ NHANH',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () async {
              await context.push('/admin/campaigns/new');
            },
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Tạo chiến dịch mới'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () async {
              await context.push('/admin/statistics');
            },
            icon: const Icon(Icons.bar_chart_outlined),
            label: const Text('Xem thống kê chi tiết'),
          ),
        ],
      ),
    );
  }
}
