import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/top_notification.dart';

import '../../../campaigns/data/models/event_participation_model.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';

class AdminStatisticsScreen extends ConsumerStatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  ConsumerState<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends ConsumerState<AdminStatisticsScreen> {
  String _selectedEventId = 'all';

  Future<void> _openParticipantsTab(int tabIndex) async {
    if (_selectedEventId == 'all') {
      TopNotification.show(
        context,
        'Vui lòng chọn một sự kiện cụ thể để xem danh sách đăng ký.',
        isError: true,
      );
      return;
    }

    await context.push('/admin/events/$_selectedEventId/participants?tab=$tabIndex');
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminAllEventsProvider);
    final participationsAsync = ref.watch(allParticipationsProvider);
    final theme = Theme.of(context);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('THỐNG KÊ BÁO CÁO'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (events) {
          return participationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Lỗi: $err')),
            data: (participations) {
              if (events.isEmpty) {
                return const Center(
                  child: Text('Chưa có sự kiện nào để thống kê.'),
                );
              }

              // Guard selected ID
              if (_selectedEventId != 'all' && !events.any((e) => e.id == _selectedEventId)) {
                _selectedEventId = 'all';
              }

              // Filter participations by selected event
              final filteredParticipations = _selectedEventId == 'all'
                  ? participations
                  : participations.where((p) => p.eventId == _selectedEventId).toList();

              // Compute ratios
              final registeredCount = filteredParticipations
                  .where((p) => p.status == ParticipationStatus.registered)
                  .length;
              final attendedCount = filteredParticipations
                  .where((p) => p.status == ParticipationStatus.attended)
                  .length;
              final absentCount = filteredParticipations
                  .where((p) => p.status == ParticipationStatus.absent)
                  .length;
              final cancelledCount = filteredParticipations
                  .where((p) => p.status == ParticipationStatus.cancelled)
                  .length;
              final total = filteredParticipations.length;

              // Compute registration per event spots (always show overall trend in line chart)
              final spots = <FlSpot>[];
              final sortedEvents = List.from(events)
                ..sort((a, b) => (a.startDate ?? DateTime.now())
                    .compareTo(b.startDate ?? DateTime.now()));
              double maxRegistered = 5.0;
              for (var i = 0; i < sortedEvents.length; i++) {
                final count = sortedEvents[i].registeredCount.toDouble();
                spots.add(FlSpot(i.toDouble(), count));
                if (count > maxRegistered) {
                  maxRegistered = count;
                }
              }

              final pieChartTitle = _selectedEventId == 'all'
                  ? 'TỶ LỆ THAM GIA TOÀN HỆ THỐNG'
                  : 'TỶ LỆ THAM GIA SỰ KIỆN';

              final pieChartContainer = Container(
                height: 360,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pieChartTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: total == 0
                          ? const Center(
                              child: Text(
                                'Sự kiện này chưa có lượt đăng ký tham gia nào.',
                                style: TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                            )
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    color: const Color(0xFF0F766E),
                                    value: registeredCount.toDouble(),
                                    title: registeredCount > 0 ? '$registeredCount' : '',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: attendedCount.toDouble(),
                                    title: attendedCount > 0 ? '$attendedCount' : '',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.orange,
                                    value: absentCount.toDouble(),
                                    title: absentCount > 0 ? '$absentCount' : '',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: cancelledCount.toDouble(),
                                    title: cancelledCount > 0 ? '$cancelledCount' : '',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    const _ChartLegends(),
                  ],
                ),
              );

              final lineChartContainer = Container(
                height: 360,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'XU HƯỚNG ĐĂNG KÝ CÁC SỰ KIỆN',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxRegistered + 1,
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (val, _) {
                                  if (val % 1 == 0) {
                                    return Text(
                                      val.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1.0,
                                getTitlesWidget: (val, _) {
                                  final index = val.toInt();
                                  if (index >= 0 && index < sortedEvents.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        sortedEvents[index].title,
                                        style: const TextStyle(fontSize: 9),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: const Color(0xFF0F766E),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final selectedEvent = _selectedEventId == 'all'
                  ? null
                  : events.firstWhere((e) => e.id == _selectedEventId);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector Dropdown Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_selectedEventId),
                          initialValue: _selectedEventId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Chọn sự kiện để xem thống kê',
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'all',
                              child: Text(
                                'Tất cả các sự kiện (Toàn hệ thống)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...events.map(
                              (e) => DropdownMenuItem<String>(
                                value: e.id,
                                child: Text(
                                  e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedEventId = val ?? 'all';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Specific Event Details Panel if selected
                    if (selectedEvent != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHI TIẾT SỰ KIỆN',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF0F766E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              selectedEvent.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (selectedEvent.schoolName.isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.school_outlined,
                                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedEvent.schoolName,
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            if (selectedEvent.capacity > 0)
                              Row(
                                children: [
                                  Icon(Icons.people_alt_outlined,
                                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sức chứa tối đa: ${selectedEvent.capacity} học sinh',
                                    style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      _selectedEventId == 'all' ? 'TỔNG QUAN HỆ THỐNG' : 'TỔNG QUAN SỰ KIỆN',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats boxes
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Tổng số đăng ký',
                              value: total.toString(),
                              color: const Color(0xFF0F766E),
                              onTap: () => _openParticipantsTab(0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Đã tham dự',
                              value: attendedCount.toString(),
                              color: Colors.green,
                              onTap: () => _openParticipantsTab(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Vắng mặt',
                              value: absentCount.toString(),
                              color: Colors.orange,
                              onTap: () => _openParticipantsTab(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Đã hủy',
                              value: cancelledCount.toString(),
                              color: Colors.red,
                              onTap: () => _openParticipantsTab(4),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Tổng số đăng ký',
                                  value: total.toString(),
                                  color: const Color(0xFF0F766E),
                                  onTap: () => _openParticipantsTab(0),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  label: 'Đã tham dự',
                                  value: attendedCount.toString(),
                                  color: Colors.green,
                                  onTap: () => _openParticipantsTab(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Vắng mặt',
                                  value: absentCount.toString(),
                                  color: Colors.orange,
                                  onTap: () => _openParticipantsTab(3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  label: 'Đã hủy',
                                  value: cancelledCount.toString(),
                                  color: Colors.red,
                                  onTap: () => _openParticipantsTab(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),

                    // Charts Layout
                    if (_selectedEventId == 'all')
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: pieChartContainer),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: lineChartContainer),
                          ],
                        )
                      else
                        Column(
                          children: [
                            pieChartContainer,
                            const SizedBox(height: 24),
                            lineChartContainer,
                          ],
                        )
                    else
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: pieChartContainer,
                        ),
                      ),

                    // ── Danh sách người đăng ký ──────────────────────────
                    if (_selectedEventId != 'all' && filteredParticipations.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Text(
                            'DANH SÁCH NGƯỜI ĐĂNG KÝ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${filteredParticipations.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            // Header row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E), // nền xanh đậm — chữ trắng rõ
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                border: Border(
                                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 28),
                                  Expanded(
                                    flex: 3,
                                    child: Text('HỌ VÀ TÊN', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text('EMAIL', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('TRẠNG THÁI', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                                  ),
                                  if (isDesktop)
                                    Expanded(
                                      flex: 2,
                                      child: Text('NGÀY ĐĂNG KÝ', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                                    ),
                                ],
                              ),
                            ),
                            // Data rows
                            ...filteredParticipations.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final p = entry.value;
                              final isLast = idx == filteredParticipations.length - 1;

                              Color statusColor;
                              switch (p.status) {
                                case ParticipationStatus.attended:
                                  statusColor = Colors.green;
                                  break;
                                case ParticipationStatus.cancelled:
                                  statusColor = Colors.red;
                                  break;
                                case ParticipationStatus.absent:
                                  statusColor = Colors.orange;
                                  break;
                                default:
                                  statusColor = const Color(0xFF0F766E);
                              }

                              final regDate = p.registeredAt;
                              final dateStr = regDate != null
                                  ? '${regDate.day.toString().padLeft(2, '0')}/'
                                    '${regDate.month.toString().padLeft(2, '0')}/'
                                    '${regDate.year}'
                                  : '—';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: idx.isOdd ? const Color(0xFFF5F5F5) : Colors.white,
                                  border: isLast
                                      ? null
                                      : Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: statusColor.withValues(alpha: 0.15),
                                      child: Text(
                                        p.userName.isNotEmpty ? p.userName[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        p.userName,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        p.userEmail ?? '—',
                                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                p.status.label,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          if (p.evidenceUrl != null && p.evidenceUrl!.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            GestureDetector(
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
                                                              p.evidenceUrl!,
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
                                              child: const Icon(
                                                Icons.image_search_rounded,
                                                size: 20,
                                                color: Color(0xFF0F766E),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isDesktop)
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          dateStr,
                                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartLegends extends StatelessWidget {
  const _ChartLegends();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(color: Color(0xFF0F766E), label: 'Đăng ký'),
        _LegendItem(color: Colors.green, label: 'Tham dự'),
        _LegendItem(color: Colors.orange, label: 'Vắng'),
        _LegendItem(color: Colors.red, label: 'Hủy'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
