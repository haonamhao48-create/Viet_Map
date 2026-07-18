import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/widgets/top_notification.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';

class AdminNotificationScreen extends ConsumerStatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  ConsumerState<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends ConsumerState<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _audienceType = 'all'; // 'all' or 'event'
  String? _selectedEventId;

  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<int> _getActiveTokensCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isNull: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Lỗi đếm token hoạt động: $e');
      return 0;
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    // Xác nhận gửi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('XÁC NHẬN GỬI THÔNG BÁO'),
        content: const Text(
          'Hành động này sẽ gửi thông báo đẩy đến toàn bộ thiết bị mục tiêu. '
          'Bạn có chắc chắn muốn thực hiện?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('GỬI'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Lưu yêu cầu thông báo vào Firestore
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'route': '/notifications', // Luôn điều hướng về trang thông báo
        'audienceType': _audienceType,
        'targetEventId': _audienceType == 'event' ? _selectedEventId : null,
        'status': 'pending', // Cloud Function sẽ kích hoạt khi thấy 'pending'
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('notification_requests').add(data);

      if (mounted) {
        TopNotification.show(context, 'Đã gửi yêu cầu thông báo đẩy lên hệ thống thành công.');
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _audienceType = 'all';
          _selectedEventId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(context, 'Gửi thông báo thất bại: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminAllEventsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('GỬI THÔNG BÁO HÀNG LOẠT (FCM)'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thống kê số lượng token
              FutureBuilder<int>(
                future: _getActiveTokensCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.05),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.devices_other_rounded, color: Color(0xFF0F766E), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hiện tại có $count thiết bị đang kích hoạt nhận thông báo trên hệ thống.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Form Nhập nội dung
              Text('NỘI DUNG THÔNG BÁO', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề thông báo',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Nội dung thông báo',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập nội dung thông báo' : null,
              ),
              const SizedBox(height: 24),

              // Cấu hình Đối tượng nhận
              Text('ĐỐI TƯỢNG NHẬN TIN', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _audienceType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Gửi đến',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả mọi người (Broadcast)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  DropdownMenuItem(value: 'event', child: Text('Người đăng ký tham gia sự kiện cụ thể', overflow: TextOverflow.ellipsis, maxLines: 1)),
                ],
                onChanged: (val) {
                  setState(() {
                    _audienceType = val ?? 'all';
                    _selectedEventId = null;
                  });
                },
              ),
              if (_audienceType == 'event') ...[
                const SizedBox(height: 16),
                eventsAsync.when(
                  data: (events) => DropdownButtonFormField<String>(
                    initialValue: _selectedEventId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn sự kiện mục tiêu',
                      border: OutlineInputBorder(),
                    ),
                    items: events.map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.title, overflow: TextOverflow.ellipsis, maxLines: 1),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedEventId = val;
                      });
                    },
                    validator: (val) => _audienceType == 'event' && val == null ? 'Vui lòng chọn sự kiện' : null,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Lỗi tải danh sách sự kiện: $err', style: const TextStyle(color: Colors.red)),
                ),
              ],
              const SizedBox(height: 32),

              // Nút gửi
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _isSending ? null : _sendNotification,
                icon: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSending ? 'ĐANG GỬI...' : 'GỬI THÔNG BÁO NGAY',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
