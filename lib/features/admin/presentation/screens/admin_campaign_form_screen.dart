import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/top_notification.dart';

import '../../../campaigns/data/models/campaign_model.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../campaigns/presentation/utils/date_formatters.dart';

class AdminCampaignFormScreen extends ConsumerStatefulWidget {
  const AdminCampaignFormScreen({super.key, this.campaignId});

  final String? campaignId;

  @override
  ConsumerState<AdminCampaignFormScreen> createState() => _AdminCampaignFormScreenState();
}

class _AdminCampaignFormScreenState extends ConsumerState<AdminCampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  CampaignStatus _status = CampaignStatus.draft;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEdit = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.campaignId != null;
    if (_isEdit) {
      _loadCampaignData();
    }
  }

  Future<void> _loadCampaignData() async {
    setState(() => _isLoadingData = true);
    final campaign = await ref.read(campaignRepositoryProvider).getCampaignById(widget.campaignId!);
    if (campaign != null) {
      _titleController.text = campaign.title;
      _descController.text = campaign.description;
      setState(() {
        _status = campaign.status;
        _startDate = campaign.startDate;
        _endDate = campaign.endDate;
      });
    }
    setState(() => _isLoadingData = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
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
    if (_startDate == null || _endDate == null) {
      TopNotification.show(context, 'Vui lòng chọn thời gian diễn ra chiến dịch.', isError: true);
      return;
    }

    final campaign = CampaignModel(
      id: widget.campaignId ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      bannerUrl: '',
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
    );

    bool success;
    if (_isEdit) {
      success = await ref.read(adminCampaignControllerProvider.notifier).updateCampaign(campaign);
    } else {
      success = await ref.read(adminCampaignControllerProvider.notifier).create(campaign);
    }

    if (success && mounted) {
      TopNotification.show(
        context,
        _isEdit
            ? 'Đã cập nhật chiến dịch thành công.'
            : 'Đã tạo chiến dịch mới thành công.',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = ref.watch(adminCampaignControllerProvider).isLoading;

    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'CHỈNH SỬA CHIẾN DỊCH' : 'TẠO CHIẾN DỊCH MỚI'),
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
                  labelText: 'Tiêu đề chiến dịch *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
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
                    val == null || val.trim().isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<CampaignStatus>(
                key: ValueKey(_status),
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái chiến dịch',
                  border: OutlineInputBorder(),
                ),
                items: CampaignStatus.values
                    .where((s) => s != CampaignStatus.unknown)
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
              
              // Date picker display
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
                              fontWeight: FontWeight.w600,
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
                    : Text(_isEdit ? 'Cập nhật chiến dịch' : 'Tạo chiến dịch mới'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
