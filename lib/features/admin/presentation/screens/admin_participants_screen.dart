import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaigns/data/models/event_participation_model.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../campaigns/presentation/utils/date_formatters.dart';
import '../../../campaigns/presentation/widgets/status_chip.dart';
import '../../../../shared/widgets/loading_indicator.dart';

class AdminParticipantsScreen extends ConsumerStatefulWidget {
  const AdminParticipantsScreen({
    super.key,
    required this.eventId,
    this.initialTabIndex = 0,
  });

  final String eventId;
  final int initialTabIndex;

  @override
  ConsumerState<AdminParticipantsScreen> createState() => _AdminParticipantsScreenState();
}

class _AdminParticipantsScreenState extends ConsumerState<AdminParticipantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Tất cả', 'Đăng ký', 'Tham dự', 'Vắng mặt', 'Đã hủy'];

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex.clamp(0, _tabs.length - 1);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final participationsAsync = ref.watch(adminEventParticipationsProvider(widget.eventId));
    final actionState = ref.watch(adminParticipationControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: eventAsync.when(
          data: (event) => Text('NGƯỜI ĐĂNG KÝ: ${event?.title.toUpperCase() ?? ''}'),
          loading: () => const Text('ĐANG TẢI...'),
          error: (_, __) => const Text('LỖI'),
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: participationsAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Đang tải danh sách đăng ký...'),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (list) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(list, null, theme, actionState.isLoading),
              _buildList(list, ParticipationStatus.registered, theme, actionState.isLoading),
              _buildList(list, ParticipationStatus.attended, theme, actionState.isLoading),
              _buildList(list, ParticipationStatus.absent, theme, actionState.isLoading),
              _buildList(list, ParticipationStatus.cancelled, theme, actionState.isLoading),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    List<EventParticipationModel> allList,
    ParticipationStatus? filterStatus,
    ThemeData theme,
    bool isActionLoading,
  ) {
    final filtered = filterStatus == null
        ? allList
        : allList.where((p) => p.status == filterStatus).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('Không có người đăng ký ở trạng thái này.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.userName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ParticipationStatusChip(status: item.status),
                ],
              ),
              if (item.userEmail != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.userEmail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (item.registeredAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Đăng ký lúc: ${formatEventDate(item.registeredAt)}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
              if (item.evidenceUrl != null && item.evidenceUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBar(
                              title: const Text('BẰNG CHỨNG CHECK-IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              automaticallyImplyLeading: false,
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            Container(
                              color: Colors.black,
                              constraints: const BoxConstraints(maxHeight: 450),
                              width: double.infinity,
                              child: InteractiveViewer(
                                maxScale: 3.0,
                                child: Image.network(
                                  item.evidenceUrl!,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(48.0),
                                        child: CircularProgressIndicator(color: Colors.white),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(48.0),
                                        child: Text(
                                          'Không thể tải ảnh bằng chứng',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 160,
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              item.evidenceUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.6),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Xem ảnh check-in',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (item.status == ParticipationStatus.registered) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: isActionLoading
                            ? null
                            : () => ref
                                .read(adminParticipationControllerProvider.notifier)
                                .markAbsent(item.id, widget.eventId),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Vắng mặt'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: isActionLoading
                            ? null
                            : () => ref
                                .read(adminParticipationControllerProvider.notifier)
                                .confirm(item.id, widget.eventId),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Tham dự'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
