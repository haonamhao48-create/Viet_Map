import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/widgets/top_notification.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/campaign_provider.dart';
import '../providers/user_location_provider.dart';

class CheckInVerificationScreen extends ConsumerStatefulWidget {
  const CheckInVerificationScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<CheckInVerificationScreen> createState() =>
      _CheckInVerificationScreenState();
}

class _CheckInVerificationScreenState
    extends ConsumerState<CheckInVerificationScreen> {
  late DateTime _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  Future<XFile?> _pickImageSource(BuildContext context) async {
    final picker = ImagePicker();
    return showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới (Camera)'),
              onTap: () async {
                final file = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (context.mounted) Navigator.pop(context, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện (Gallery)'),
              onTap: () async {
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (context.mounted) Navigator.pop(context, file);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final locationStatusAsync = ref.watch(userLocationStatusProvider(widget.eventId));
    final checkInState = ref.watch(userCheckInControllerProvider);

    ref.listen(userCheckInControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          TopNotification.show(context, error.toString().replaceAll('Exception: ', ''), isError: true);
        },
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'CHẤM VÀO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFC20E2C),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: eventAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Đang tải thông tin...'),
        error: (err, _) => Center(child: Text('Lỗi tải dữ liệu: $err')),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Không tìm thấy sự kiện.'));
          }

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: locationStatusAsync.when(
                      loading: () => _buildVerificationCircle(
                        color: Colors.grey.shade400,
                        locationName: event.schoolName,
                        middleText: 'ĐANG XÁC ĐỊNH VỊ TRÍ...',
                        bottomText: 'Vui lòng chờ thiết bị kết nối GPS...',
                      ),
                      error: (err, _) => _buildVerificationCircle(
                        color: Colors.grey.shade600,
                        locationName: event.schoolName,
                        middleText: 'LỖI ĐỊNH VỊ',
                        bottomText: err.toString(),
                      ),
                      data: (locationStatus) {
                        final inRange = locationStatus.type == LocationStatusType.inRange;
                        final lat = locationStatus.latitude?.toStringAsFixed(6) ?? '0.0';
                        final lng = locationStatus.longitude?.toStringAsFixed(6) ?? '0.0';

                        final circleColor = inRange ? const Color(0xFF10B981) : const Color(0xFFC20E2C);
                        final middleText = inRange
                            ? 'Đã đúng vị trí'
                            : 'Vui lòng di chuyển đến đúng vị trí được phép check-in.';
                        final bottomText = 'Tọa độ: $lat, $lng';

                        return _buildVerificationCircle(
                          color: circleColor,
                          locationName: event.schoolName,
                          middleText: middleText,
                          bottomText: bottomText,
                        );
                      },
                    ),
                  ),
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(20),
                child: locationStatusAsync.when(
                  loading: () => _buildBottomButton(
                    label: 'Đang đợi GPS...',
                    color: Colors.grey,
                    onPressed: null,
                    isLoading: false,
                  ),
                  error: (err, _) => _buildBottomButton(
                    label: 'Cập nhật lại vị trí',
                    color: const Color(0xFFC20E2C),
                    onPressed: () {
                      ref.invalidate(userLocationStatusProvider(widget.eventId));
                    },
                    isLoading: false,
                  ),
                  data: (locationStatus) {
                    final inRange = locationStatus.type == LocationStatusType.inRange;
                    final isBusy = checkInState.isLoading;

                    if (inRange) {
                      return _buildBottomButton(
                        label: 'Tiến hành Check-in',
                        color: const Color(0xFF10B981),
                        isLoading: isBusy,
                        onPressed: isBusy
                            ? null
                            : () async {
                                final image = await _pickImageSource(context);
                                if (image == null) {
                                  if (context.mounted) {
                                    TopNotification.show(
                                      context,
                                      'Bạn cần cung cấp ảnh chụp làm bằng chứng.',
                                      isError: true,
                                    );
                                  }
                                  return;
                                }
                                final ok = await ref
                                    .read(userCheckInControllerProvider.notifier)
                                    .checkIn(widget.eventId, image);
                                if (ok && context.mounted) {
                                  context.pop(); // Go back on success
                                }
                              },
                      );
                    } else {
                      return _buildBottomButton(
                        label: 'Cập nhật vị trí',
                        color: const Color(0xFFC20E2C),
                        isLoading: false,
                        onPressed: () {
                          ref.invalidate(userLocationStatusProvider(widget.eventId));
                          TopNotification.show(context, 'Đang cập nhật lại vị trí...');
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVerificationCircle({
    required Color color,
    required String locationName,
    required String middleText,
    required String bottomText,
  }) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                locationName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text(
                _formatDate(_currentTime),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(_currentTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                middleText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                bottomText,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
