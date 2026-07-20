import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/widgets/top_notification.dart';

import '../../../../shared/widgets/loading_indicator.dart';
import '../../../map/presentation/providers/school_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/models/event_participation_model.dart';
import '../providers/campaign_provider.dart';
import '../utils/date_formatters.dart';
import '../widgets/status_chip.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final participationAsync = ref.watch(eventParticipationProvider(eventId));
    final registrationState = ref.watch(eventRegistrationControllerProvider);

    ref.listen(eventRegistrationControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          TopNotification.show(context, participationErrorMessage(error), isError: true);
        },
      );
    });

    ref.listen(userCheckInControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          TopNotification.show(context, participationErrorMessage(error), isError: true);
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sự kiện'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: eventAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Đang tải sự kiện...'),
        error: (error, _) => Center(child: Text('Lỗi: $error')),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Không tìm thấy sự kiện.'));
          }

          final participation = participationAsync.valueOrNull;
          final isLoadingAction = registrationState.isLoading;
          final isLoadingCheckIn = ref.watch(userCheckInControllerProvider).isLoading;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (event.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        EventStatusChip(status: event.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(formatEventDateRange(event.startDate, event.endDate)),
                    const SizedBox(height: 12),
                    Text(event.description),
                    const SizedBox(height: 20),
                    _InfoTile(
                      icon: Icons.school_outlined,
                      title: 'Trường',
                      value: event.schoolName.isNotEmpty
                          ? event.schoolName
                          : 'Chưa cập nhật',
                    ),
                    if (event.address.isNotEmpty)
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        title: 'Địa chỉ',
                        value: event.address,
                      ),
                    _InfoTile(
                      icon: Icons.people_outline,
                      title: 'Số lượng đăng ký',
                      value: event.capacity > 0
                          ? '${event.registeredCount}/${event.capacity}'
                          : '${event.registeredCount}',
                    ),
                    if (participation != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Trạng thái của bạn: '),
                          ParticipationStatusChip(status: participation.status),
                        ],
                      ),
                      if (participation.status == ParticipationStatus.attended &&
                          participation.evidenceUrl != null &&
                          participation.evidenceUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Ảnh minh chứng check-in của bạn:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              participation.evidenceUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (event.schoolId.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(selectedSchoolIdProvider.notifier).state =
                              event.schoolId;
                          context.go('/home');
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Xem trên bản đồ'),
                      ),
                    if (event.schoolId.isNotEmpty) const SizedBox(height: 8),
                    _buildActionButton(
                      context: context,
                      ref: ref,
                      event: event,
                      participation: participation,
                      isFull: event.isFull,
                      isLoading: isLoadingAction,
                      isLoadingCheckIn: isLoadingCheckIn,
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

  Widget _buildActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required EventModel event,
    required EventParticipationModel? participation,
    required bool isFull,
    required bool isLoading,
    required bool isLoadingCheckIn,
  }) {
    final status = participation?.status;

    if (status == ParticipationStatus.registered) {
      final now = DateTime.now();
      final isHappening = event.status == EventStatus.ongoing ||
          (event.startDate != null && event.endDate != null &&
           now.isAfter(event.startDate!) && now.isBefore(event.endDate!));
      final canCheckIn = isHappening;

      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: isLoading || isLoadingCheckIn
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hủy đăng ký'),
                          content: const Text(
                            'Bạn có chắc muốn hủy đăng ký sự kiện này?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Không'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hủy đăng ký'),
                            ),
                          ],
                        ),
                      );
                        if (confirm == true && context.mounted) {
                          await ref
                              .read(eventRegistrationControllerProvider.notifier)
                              .cancel(eventId);
                          if (context.mounted) {
                            TopNotification.show(context, 'Đã hủy đăng ký.');
                          }
                        }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: const Text('Hủy đăng ký'),
            ),
          ),
          if (canCheckIn) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isLoading || isLoadingCheckIn
                    ? null
                    : () {
                        context.push('/events/$eventId/checkin');
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                label: const Text(
                  'Check-in',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (status == ParticipationStatus.attended ||
        status == ParticipationStatus.absent ||
        status == ParticipationStatus.cancelled) {
      return FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: null,
        child: Text(
          status == ParticipationStatus.cancelled
              ? 'Đã hủy đăng ký'
              : status!.label,
        ),
      );
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0F766E),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onPressed: isLoading || isFull
          ? null
          : () async {
              await ref
                  .read(eventRegistrationControllerProvider.notifier)
                  .register(eventId);
              if (context.mounted) {
                TopNotification.show(context, 'Đăng ký thành công!');
              }
            },
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.how_to_reg_outlined),
      label: Text(isFull ? 'Đã đủ chỗ' : 'Đăng ký tham gia'),
    );
  }

  Future<XFile?> _pickImageSource(BuildContext context) async {
    final theme = Theme.of(context);
    return await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CHỌN BẰNG CHỨNG CHECK-IN',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F766E),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0F766E)),
                title: const Text('Chụp ảnh trực tiếp'),
                onTap: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (context.mounted) Navigator.pop(context, file);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0F766E)),
                title: const Text('Chọn ảnh từ Thư viện'),
                onTap: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (context.mounted) Navigator.pop(context, file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
