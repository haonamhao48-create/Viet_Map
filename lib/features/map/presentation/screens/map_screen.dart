import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/utils/auth_logout.dart';
import '../providers/school_provider.dart';
import '../providers/route_provider.dart';
import '../widgets/school_map.dart';
import '../widgets/route_info_card.dart';
import '../../../school_visits/presentation/widgets/school_visit_notes_section.dart';
import '../../../auth/presentation/widgets/user_account_header.dart';
import '../../data/models/high_school_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final selectedSchool = ref.watch(selectedSchoolProvider);
    final startSchool = ref.watch(startSchoolProvider);
    final endSchool = ref.watch(endSchoolProvider);
    
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    ref.listen<String>(schoolSearchQueryProvider, (prev, next) {
      if (!mounted) return;
      if (_searchController.text != next) {
        _searchController.text = next;
      }
    });

    return Scaffold(
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56 + 1),
              child: Column(
                children: [
                  AppBar(
                    toolbarHeight: 56,
                    elevation: 0,
                    title: Text(
                      'BẢN ĐỒ KHẢO SÁT TRƯỜNG HỌC',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFF0F766E),
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      if (userProfile != null || authState.valueOrNull != null)
                        IconButton(
                          icon: const Icon(Icons.campaign_outlined),
                          color: Colors.white,
                          tooltip: 'Chiến dịch tuyển sinh',
                          onPressed: () => context.push('/campaigns'),
                        ),
                      if (userProfile != null || authState.valueOrNull != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundImage: userProfile?.avatarUrl != null
                                      ? NetworkImage(userProfile!.avatarUrl!)
                                      : (authState.valueOrNull?.photoURL != null
                                          ? NetworkImage(authState.valueOrNull!.photoURL!)
                                          : null),
                                  child: (userProfile?.avatarUrl == null && authState.valueOrNull?.photoURL == null)
                                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userProfile?.fullName ?? authState.valueOrNull?.displayName ?? authState.valueOrNull?.email ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded),
                          color: Colors.white,
                          tooltip: 'Đăng xuất',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Đăng xuất'),
                                content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Hủy'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Đăng xuất'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await performSignOut(ref, context);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  Container(
                    height: 1,
                    color: const Color(0xFF0F766E).withValues(alpha: 0.4),
                  ),
                ],
              ),
            )
          : null,
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: const Color(0xFF0B1F1E),
              width: 320,
              child: SafeArea(
                child: _SidebarContent(searchController: _searchController),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isDesktop) {
            return Row(
              children: [
                // Left Panel: SidebarContent or SchoolDetailsPanel (Docked on Desktop)
                Container(
                  width: 320,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B1F1E),
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFF1A3330),
                      ),
                    ),
                  ),
                  child: selectedSchool != null
                      ? _SchoolDetailsPanel(school: selectedSchool)
                      : _SidebarContent(
                          searchController: _searchController,
                        ),
                ),
                
                // Center Area: OpenStreetMap with Floating Route Card
                Expanded(
                  child: Stack(
                    children: const [
                      Positioned.fill(
                        child: SchoolMap(),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: RouteInfoCard(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Mobile Responsive Stack
            final isRouteActive = startSchool != null && endSchool != null;
            return Stack(
              children: [
                const Positioned.fill(
                  child: SchoolMap(),
                ),
                
                // Floating Search Bar or Route Card
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: isRouteActive
                      ? SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: const RouteInfoCard(),
                          ),
                        )
                      : Builder(
                          builder: (innerContext) => _MobileSearchBar(
                            onTapMenu: () => Scaffold.of(innerContext).openDrawer(),
                          ),
                        ),
                ),
                
                // Floating School Details Bottom Sheet-like Card
                if (selectedSchool != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _MobileSchoolDetailsCard(school: selectedSchool),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _SidebarContent extends ConsumerWidget {
  const _SidebarContent({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startSchool = ref.watch(startSchoolProvider);
    final endSchool = ref.watch(endSchoolProvider);
    final routeInfo = ref.watch(routeInfoProvider);
    final selectedSchool = ref.watch(selectedSchoolProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: (startSchool != null || endSchool != null) ? 1 : 0,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF0F766E),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.list_alt_rounded, size: 20),
                  text: 'Danh sách',
                ),
                Tab(
                  icon: Icon(Icons.directions_rounded, size: 20),
                  text: 'Đường đi',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: School List
                _SchoolListTab(searchController: searchController),
                
                // Tab 2: Routing Flow
                _RoutingTab(
                  startSchool: startSchool,
                  endSchool: endSchool,
                  routeInfo: routeInfo,
                  selectedSchool: selectedSchool,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1A3330)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _CampaignNavSection(),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: UserAccountHeader(),
          ),
        ],
      ),
    );
  }
}

class _SchoolListTab extends ConsumerWidget {
  const _SchoolListTab({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final schoolsAsync = ref.watch(schoolsProvider);
    final filteredSchools = ref.watch(filteredSchoolsProvider);
    final selectedSchoolId = ref.watch(selectedSchoolIdProvider);
    final searchQuery = ref.watch(schoolSearchQueryProvider).trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm trường học...',
              hintStyle: const TextStyle(color: Color(0x99FFFFFF)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0x99FFFFFF)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0x99FFFFFF)),
                      onPressed: () {
                        searchController.clear();
                        ref.read(schoolSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (val) {
              ref.read(schoolSearchQueryProvider.notifier).state = val;
            },
          ),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        Expanded(
          child: searchQuery.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 48,
                        color: Color(0x4DFFFFFF),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nhập tên trường học để tìm kiếm...',
                        style: TextStyle(
                          color: Color(0x61FFFFFF),
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
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      itemBuilder: (context, index) {
                        final school = filteredSchools[index];
                        final isSelected = selectedSchoolId == school.id;
                        return ListTile(
                          title: Text(
                            school.tenTruong,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2DD4BF) : Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            school.diaChi,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
                          onTap: () {
                            ref.read(selectedSchoolIdProvider.notifier).state = school.id;
                            ref.read(schoolSearchQueryProvider.notifier).state = school.tenTruong;
                            final width = MediaQuery.of(context).size.width;
                            if (width < 800) {
                              Navigator.pop(context);
                            }
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
    );
  }
}

class _RoutingTab extends ConsumerWidget {
  const _RoutingTab({
    required this.startSchool,
    required this.endSchool,
    required this.routeInfo,
    required this.selectedSchool,
  });

  final HighSchoolModel? startSchool;
  final HighSchoolModel? endSchool;
  final RouteInfo? routeInfo;
  final HighSchoolModel? selectedSchool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LỘ TRÌNH ĐƯỜNG ĐI',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          // Start point Card
          _RoutePointSelectorCard(
            title: 'Điểm xuất phát',
            school: startSchool,
            icon: Icons.play_circle_fill_rounded,
            iconColor: Colors.green.shade600,
            onClear: () {
              ref.read(startSchoolProvider.notifier).state = null;
            },
            placeholder: 'Nhập tìm kiếm điểm xuất phát...',
            onSelected: (school) {
              ref.read(startSchoolProvider.notifier).state = school;
            },
          ),
          
          const SizedBox(height: 12),
          
          // End point Card
          _RoutePointSelectorCard(
            title: 'Điểm đến',
            school: endSchool,
            icon: Icons.flag_rounded,
            iconColor: Colors.red.shade600,
            onClear: () {
              ref.read(endSchoolProvider.notifier).state = null;
            },
            placeholder: 'Nhập tìm kiếm điểm đến...',
            onSelected: (school) {
              ref.read(endSchoolProvider.notifier).state = school;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Helper if a school is selected but route not complete
          if (selectedSchool != null && (startSchool == null || endSchool == null)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Đang chọn: ${selectedSchool!.tenTruong}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (startSchool == null)
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 14),
                            label: const Text('Làm Điểm đi', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              ref.read(startSchoolProvider.notifier).state = selectedSchool;
                            },
                          ),
                        ),
                      if (startSchool == null && endSchool == null) const SizedBox(width: 8),
                      if (endSchool == null)
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.flag_rounded, size: 14),
                            label: const Text('Làm Điểm đến', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              ref.read(endSchoolProvider.notifier).state = selectedSchool;
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Route Details Summary
          if (routeInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Khoảng cách', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${routeInfo!.distanceKm.toStringAsFixed(1)} km',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                      Column(
                        children: [
                          const Text('Thời gian đi', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${routeInfo!.durationMinutes.toStringAsFixed(0)} phút',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2DD4BF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Cancel route button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('HỦY LỘ TRÌNH', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(startSchoolProvider.notifier).state = null;
                ref.read(endSchoolProvider.notifier).state = null;
              },
            ),
          ] else if (startSchool == null && endSchool == null) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'Chọn trường học từ danh sách hoặc bản đồ để bắt đầu tìm đường.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutePointSelectorCard extends ConsumerWidget {
  const _RoutePointSelectorCard({
    required this.title,
    required this.school,
    required this.icon,
    required this.iconColor,
    required this.onClear,
    required this.placeholder,
    required this.onSelected,
  });

  final String title;
  final HighSchoolModel? school;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onClear;
  final String placeholder;
  final ValueChanged<HighSchoolModel> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final schoolsAsync = ref.watch(schoolsProvider);
    final schools = schoolsAsync.valueOrNull ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: school != null
                    ? Text(
                        school!.tenTruong,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Autocomplete<HighSchoolModel>(
                        displayStringForOption: (HighSchoolModel option) => option.tenTruong,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<HighSchoolModel>.empty();
                          }
                          return schools.where((HighSchoolModel option) {
                            return option.tenTruong.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                   option.diaChi.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        optionsViewBuilder: (overlayContext, onSelectedOption, options) {
                          // Use overlayContext (not outer context) to avoid ancestor assertion failure
                          // because the dropdown is rendered inside a separate Overlay widget tree.
                          final overlayTheme = Theme.of(overlayContext);
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(8),
                              color: overlayTheme.colorScheme.surfaceContainerLowest,
                              child: Container(
                                width: 260,
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(color: overlayTheme.colorScheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext listContext, int index) {
                                    final HighSchoolModel option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelectedOption(option),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option.tenTruong,
                                              style: overlayTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              option.diaChi,
                                              style: overlayTheme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: placeholder,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              border: InputBorder.none,
                              hintStyle: const TextStyle(color: Color(0x4DFFFFFF), fontStyle: FontStyle.italic, fontSize: 14),
                              filled: false,
                            ),
                          );
                        },
                        onSelected: onSelected,
                      ),
              ),
              if (school != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClear,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SchoolDetailsPanel extends ConsumerWidget {
  const _SchoolDetailsPanel({required this.school});

  final HighSchoolModel school;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFF0B1F1E),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  school.tenTruong,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2DD4BF),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  ref.read(selectedSchoolIdProvider.notifier).state = null;
                  ref.read(schoolSearchQueryProvider.notifier).state = '';
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Địa chỉ: ${school.diaChi}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          if (school.maTruong != null)
            Text(
              'Mã trường: ${school.maTruong}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
            ),
          const SizedBox(height: 16),
          // Route Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                  label: const Text('Đi từ đây'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ref.read(startSchoolProvider.notifier).state = school;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã đặt ${school.tenTruong} làm điểm đi'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    if (ref.read(endSchoolProvider) != null) {
                      ref.read(selectedSchoolIdProvider.notifier).state = null;
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.flag_rounded, size: 16),
                  label: const Text('Đến đây'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ref.read(endSchoolProvider.notifier).state = school;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã đặt ${school.tenTruong} làm điểm đến'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    if (ref.read(startSchoolProvider) != null) {
                      ref.read(selectedSchoolIdProvider.notifier).state = null;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          Expanded(
            child: SingleChildScrollView(
              child: SchoolVisitNotesSection(school: school),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSchoolDetailsCard extends ConsumerWidget {
  const _MobileSchoolDetailsCard({required this.school});

  final HighSchoolModel school;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.62,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1F1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.tenTruong,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2DD4BF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        school.diaChi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () {
                    ref.read(selectedSchoolIdProvider.notifier).state = null;
                    ref.read(schoolSearchQueryProvider.notifier).state = '';
                  },
                ),
              ],
            ),
          ),
          // Route Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                    label: const Text('Đi từ đây'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      ref.read(startSchoolProvider.notifier).state = school;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã đặt ${school.tenTruong} làm điểm đi'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      if (ref.read(endSchoolProvider) != null) {
                        ref.read(selectedSchoolIdProvider.notifier).state = null;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.flag_rounded, size: 16),
                    label: const Text('Đến đây'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      ref.read(endSchoolProvider.notifier).state = school;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã đặt ${school.tenTruong} làm điểm đến'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      if (ref.read(startSchoolProvider) != null) {
                        ref.read(selectedSchoolIdProvider.notifier).state = null;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SchoolVisitNotesSection(school: school),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSearchBar extends ConsumerStatefulWidget {
  const _MobileSearchBar({
    required this.onTapMenu,
  });

  final VoidCallback onTapMenu;

  @override
  ConsumerState<_MobileSearchBar> createState() => _MobileSearchBarState();
}

class _MobileSearchBarState extends ConsumerState<_MobileSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(schoolSearchQueryProvider);
    _controller = TextEditingController(text: currentQuery);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(schoolSearchQueryProvider);
    final filteredSchools = ref.watch(filteredSchoolsProvider);
    final schoolsAsync = ref.watch(schoolsProvider);

    // Sync external changes (e.g. clear button pressed in drawer)
    if (searchQuery != _controller.text) {
      _controller.text = searchQuery;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The input card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B1F1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A3330)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: widget.onTapMenu,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm trường học...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                          filled: false,
                        ),
                        onChanged: (val) {
                          ref.read(schoolSearchQueryProvider.notifier).state = val;
                        },
                      ),
                    ),
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 20),
                        onPressed: () {
                          _controller.clear();
                          ref.read(schoolSearchQueryProvider.notifier).state = '';
                        },
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(Icons.search_rounded, color: Color(0xFF2DD4BF), size: 22),
                      ),
                  ],
                ),
              ),
            ),
            
            // Floating suggestion list overlay under the search bar
            if (_isFocused && searchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              schoolsAsync.when(
                data: (_) {
                  if (filteredSchools.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1F1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A3330)),
                      ),
                      child: const Text(
                        'Không tìm thấy trường học nào.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1F1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1A3330)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: filteredSchools.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      itemBuilder: (context, index) {
                        final school = filteredSchools[index];
                        return ListTile(
                          title: Text(
                            school.tenTruong,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            school.diaChi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            ref.read(selectedSchoolIdProvider.notifier).state = school.id;
                            ref.read(schoolSearchQueryProvider.notifier).state = school.tenTruong;
                            _focusNode.unfocus();
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1F1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1A3330)),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2DD4BF)),
                    ),
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1F1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1A3330)),
                  ),
                  child: Text(
                    'Lỗi: $err',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CampaignNavSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    if (authUser == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.campaign_outlined, color: Color(0xFF2DD4BF)),
          title: const Text(
            'Chiến dịch tuyển sinh',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Xem chiến dịch và đăng ký sự kiện',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          onTap: () {
            Navigator.of(context).pop();
            context.push('/campaigns');
          },
        ),
        ListTile(
          leading: const Icon(Icons.event_note_outlined, color: Color(0xFF2DD4BF)),
          title: const Text(
            'Sự kiện của tôi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          onTap: () {
            Navigator.of(context).pop();
            context.push('/my-events');
          },
        ),
      ],
    );
  }
}
