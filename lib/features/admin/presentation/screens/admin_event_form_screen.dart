import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/top_notification.dart';

import '../../../campaigns/data/models/event_model.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../campaigns/presentation/utils/date_formatters.dart';
import '../../../map/data/models/high_school_model.dart';
import '../widgets/school_picker_widget.dart';

class AdminEventFormScreen extends ConsumerStatefulWidget {
  const AdminEventFormScreen({super.key, this.campaignId, this.eventId});

  final String? campaignId;
  final String? eventId;

  @override
  ConsumerState<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends ConsumerState<AdminEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _capacityController = TextEditingController(text: '50');

  String _campaignId = '';
  String _schoolId = '';
  String _schoolName = '';
  String _address = '';
  EventStatus _status = EventStatus.upcoming;
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool _isEdit = false;
  bool _isLoadingData = false;
  int _registeredCount = 0;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.eventId != null;
    _campaignId = widget.campaignId ?? '';
    if (_isEdit) {
      _loadEventData();
    }
  }

  Future<void> _loadEventData() async {
    setState(() => _isLoadingData = true);
    final event = await ref.read(eventRepositoryProvider).getEventById(widget.eventId!);
    if (event != null) {
      _titleController.text = event.title;
      _descController.text = event.description;
      _capacityController.text = event.capacity.toString();
      setState(() {
        _campaignId = event.campaignId;
        _schoolId = event.schoolId;
        _schoolName = event.schoolName;
        _address = event.address;
        _status = event.status;
        _startDate = event.startDate;
        _endDate = event.endDate;
        _registeredCount = event.registeredCount;
      });
    }
    setState(() => _isLoadingData = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickSchool(BuildContext context) async {
    final HighSchoolModel? picked = await showDialog<HighSchoolModel>(
      context: context,
      builder: (context) => const SchoolPickerDialog(),
    );

    if (picked != null) {
      setState(() {
        _schoolId = picked.id;
        _schoolName = picked.tenTruong;
        _address = picked.diaChi;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F766E),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_schoolId.isEmpty) {
      TopNotification.show(context, 'Vui lòng chọn trường tổ chức.', isError: true);
      return;
    }
    if (_startDate == null || _endDate == null) {
      TopNotification.show(context, 'Vui lòng chọn thời gian diễn ra.', isError: true);
      return;
    }

    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

    final event = EventModel(
      id: widget.eventId ?? '',
      campaignId: _campaignId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      imageUrl: '',
      schoolId: _schoolId,
      schoolName: _schoolName,
      address: _address,
      capacity: capacity,
      registeredCount: _registeredCount,
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
    );

    bool success;
    if (_isEdit) {
      success = await ref.read(adminEventControllerProvider.notifier).updateEvent(event);
    } else {
      success = await ref.read(adminEventControllerProvider.notifier).create(event);
    }

    if (success && mounted) {
      TopNotification.show(
        context,
        _isEdit
            ? 'Đã cập nhật sự kiện thành công.'
            : 'Đã tạo sự kiện mới thành công.',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = ref.watch(adminEventControllerProvider).isLoading;

    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'CHỈNH SỬA SỰ KIỆN' : 'TẠO SỰ KIỆN MỚI'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề sự kiện *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề sự kiện' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Vui lòng nhập mô tả sự kiện' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng tối đa (Capacity) *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số lượng';
                  final num = int.tryParse(val);
                  if (num == null || num <= 0) return 'Số lượng phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<EventStatus>(
                key: ValueKey(_status),
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái sự kiện',
                  border: OutlineInputBorder(),
                ),
                items: EventStatus.values
                    .where((s) => s != EventStatus.unknown)
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _status = val);
                  }
                },
              ),
              const SizedBox(height: 20),

              // School Selector Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trường THPT tổ chức *',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _schoolName.isNotEmpty
                                ? '$_schoolName\n$_address'
                                : 'Chưa chọn trường',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: _schoolName.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () => _pickSchool(context),
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Chọn trường'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Date Picker Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thời gian diễn ra *',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _startDate != null && _endDate != null
                                ? formatEventDateRange(_startDate, _endDate)
                                : 'Chưa chọn thời gian',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () => _selectDateRange(context),
                      icon: const Icon(Icons.date_range_outlined),
                      label: const Text('Chọn ngày'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEdit ? 'Cập nhật sự kiện' : 'Tạo sự kiện mới'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
