import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../map/presentation/providers/school_provider.dart';

class SchoolPickerDialog extends ConsumerStatefulWidget {
  const SchoolPickerDialog({super.key});

  @override
  ConsumerState<SchoolPickerDialog> createState() => _SchoolPickerDialogState();
}

class _SchoolPickerDialogState extends ConsumerState<SchoolPickerDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CHỌN TRƯỜNG THPT',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F766E),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm tên trường, địa chỉ...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: schoolsAsync.when(
                  data: (schools) {
                    final filtered = schools.where((s) {
                      if (_searchQuery.isEmpty) return true;
                      return s.tenTruong.toLowerCase().contains(_searchQuery) ||
                          s.diaChi.toLowerCase().contains(_searchQuery) ||
                          s.tenTinhTp.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('Không tìm thấy trường nào phù hợp.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(
                        color: theme.colorScheme.outlineVariant,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final school = filtered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          title: Text(
                            school.tenTruong,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${school.diaChi}, ${school.tenXaPhuong}, ${school.tenTinhTp}',
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () => Navigator.pop(context, school),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Text('Lỗi tải danh sách trường: $err'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
