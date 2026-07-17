import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/school_provider.dart';

class SchoolListScreen extends ConsumerStatefulWidget {
  const SchoolListScreen({super.key});

  @override
  ConsumerState<SchoolListScreen> createState() => _SchoolListScreenState();
}

class _SchoolListScreenState extends ConsumerState<SchoolListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(schoolSearchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schoolsAsync = ref.watch(schoolsProvider);
    final filteredSchools = ref.watch(filteredSchoolsProvider);
    final selectedSchoolId = ref.watch(selectedSchoolIdProvider);
    final searchQuery = ref.watch(schoolSearchQueryProvider).trim();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'DANH SÁCH TRƯỜNG HỌC',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trường học...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(schoolSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(schoolSearchQueryProvider.notifier).state = val;
              },
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nhập tên trường học để tìm kiếm...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : schoolsAsync.when(
                    data: (_) {
                      if (filteredSchools.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Không tìm thấy trường học nào.'),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: filteredSchools.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          final school = filteredSchools[index];
                          final isSelected = selectedSchoolId == school.id;
                          return ListTile(
                            title: Text(
                              school.tenTruong,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF0F766E) : theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              school.diaChi,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            onTap: () {
                              ref.read(selectedSchoolIdProvider.notifier).state = school.id;
                              ref.read(schoolSearchQueryProvider.notifier).state = school.tenTruong;
                              context.go('/home'); // Go directly to Map tab to show school!
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Lỗi: $err')),
                  ),
          ),
        ],
      ),
    );
  }
}
