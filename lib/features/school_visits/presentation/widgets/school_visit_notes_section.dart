import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/school_visit_note_model.dart';
import '../providers/school_visit_provider.dart';
import '../../../map/data/models/high_school_model.dart';

class SchoolVisitNotesSection extends ConsumerWidget {
  const SchoolVisitNotesSection({super.key, required this.school});

  final HighSchoolModel school;

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(schoolVisitNotesProvider(school.id));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Ghi chú thăm trường',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openNoteForm(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        notesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, _) {
            final message = error.toString().contains('failed-precondition')
                ? 'Hệ thống đang đồng bộ dữ liệu. Thử lại sau vài phút hoặc tạo ghi chú mới bằng nút Thêm.'
                : 'Không tải được ghi chú: $error';
            return Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
            );
          },
          data: (notes) {
            if (notes.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Chưa có ghi chú. Bấm Thêm để ghi lại dịp thăm, quà tặng và mục đích chuyến đi.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              );
            }

            return Column(
              children: notes
                  .map(
                    (note) => _VisitNoteTile(
                      note: note,
                      onDelete: () => _deleteNote(context, ref, note),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openNoteForm(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để thêm ghi chú.')),
      );
      return;
    }

    final result = await showModalBottomSheet<_VisitNoteFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _VisitNoteFormSheet(schoolName: school.tenTruong),
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      final authorName = profile?.fullName?.trim().isNotEmpty == true
          ? profile!.fullName!.trim()
          : (authUser.displayName ?? 'Người dùng');

      await ref.read(schoolVisitDataSourceProvider).create(
            SchoolVisitNoteModel(
              id: '',
              schoolId: school.id,
              schoolName: school.tenTruong,
              maXaPhuong: school.maXaPhuong,
              authorUid: authUser.uid,
              authorName: authorName,
              visitDate: result.visitDate,
              purpose: result.purpose,
              occasion: result.occasion,
              gift: result.gift,
              note: result.note,
            ),
          );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ghi chú thăm trường.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được ghi chú: $error')),
      );
    }
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    SchoolVisitNoteModel note,
  ) async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null || authUser.uid != note.authorUid) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: const Text('Ghi chú này sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(schoolVisitDataSourceProvider).delete(note.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa ghi chú.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xóa được: $error')),
      );
    }
  }
}

class _VisitNoteTile extends ConsumerWidget {
  const _VisitNoteTile({
    required this.note,
    required this.onDelete,
  });

  final SchoolVisitNoteModel note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isOwner = authUser?.uid == note.authorUid;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.authorName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ngày đến: ${SchoolVisitNotesSection._formatDate(note.visitDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Xóa',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _NoteChip(label: 'Mục đích', value: note.purpose.label),
          if (note.occasion != null && note.occasion!.isNotEmpty)
            _NoteChip(label: 'Dịp', value: note.occasion!),
          if (note.gift != null && note.gift!.isNotEmpty)
            _NoteChip(label: 'Quà', value: note.gift!),
          if (note.note != null && note.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note.note!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _VisitNoteFormResult {
  const _VisitNoteFormResult({
    required this.visitDate,
    required this.purpose,
    this.occasion,
    this.gift,
    this.note,
  });

  final DateTime visitDate;
  final SchoolVisitPurpose purpose;
  final String? occasion;
  final String? gift;
  final String? note;
}

class _VisitNoteFormSheet extends StatefulWidget {
  const _VisitNoteFormSheet({required this.schoolName});

  final String schoolName;

  @override
  State<_VisitNoteFormSheet> createState() => _VisitNoteFormSheetState();
}

class _VisitNoteFormSheetState extends State<_VisitNoteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _occasionController = TextEditingController();
  final _giftController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _visitDate = DateTime.now();
  SchoolVisitPurpose _purpose = SchoolVisitPurpose.recruitment;

  @override
  void dispose() {
    _occasionController.dispose();
    _giftController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày đến thăm',
    );
    if (picked != null) {
      setState(() => _visitDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _VisitNoteFormResult(
        visitDate: DateTime(_visitDate.year, _visitDate.month, _visitDate.day),
        purpose: _purpose,
        occasion: _occasionController.text.trim(),
        gift: _giftController.text.trim(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ghi chú thăm trường',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.schoolName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày đến'),
              subtitle: Text(
                SchoolVisitNotesSection._formatDate(_visitDate),
              ),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Mục đích',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SchoolVisitPurpose>(
                  isExpanded: true,
                  value: _purpose,
                  items: SchoolVisitPurpose.values
                      .map(
                        (purpose) => DropdownMenuItem(
                          value: purpose,
                          child: Text(purpose.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => _purpose = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _occasionController,
              decoration: const InputDecoration(
                labelText: 'Dịp',
                hintText: 'VD: Khai giảng, Tết Trung thu, 20/11...',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _giftController,
              decoration: const InputDecoration(
                labelText: 'Quà mang theo',
                hintText: 'VD: Bánh kẹo, sách vở, phần thưởng học sinh...',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú thêm (tuỳ chọn)',
                hintText: 'Thông tin bổ sung về chuyến thăm...',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Lưu ghi chú'),
            ),
          ],
        ),
      ),
    );
  }
}
