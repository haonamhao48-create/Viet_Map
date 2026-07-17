import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/school_provider.dart';
import '../providers/route_provider.dart';
import '../widgets/school_map.dart';
import '../widgets/route_info_card.dart';
import '../../../school_visits/presentation/widgets/school_visit_notes_section.dart';
import '../../../auth/presentation/widgets/user_account_header.dart';
import '../../data/models/high_school_model.dart';
import '../../../../app/widgets/top_notification.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSchool = ref.watch(selectedSchoolProvider);
    final startSchool = ref.watch(startSchoolProvider);
    final endSchool = ref.watch(endSchoolProvider);
    
    final size = MediaQuery.of(context).size;
    final isRouteActive = startSchool != null && endSchool != null;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF0F766E),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'VIETMAP GIS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.school_outlined),
                      title: const Text('Danh mục trường học'),
                      onTap: () async {
                        Navigator.pop(context);
                        await context.push('/schools');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.campaign_outlined),
                      title: const Text('Chiến dịch tuyển sinh'),
                      onTap: () async {
                        Navigator.pop(context);
                        await context.push('/campaigns');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event_note_outlined),
                      title: const Text('Sự kiện tuyển sinh của tôi'),
                      onTap: () async {
                        Navigator.pop(context);
                        await context.push('/my-events');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Hồ sơ cá nhân'),
                      onTap: () async {
                        Navigator.pop(context);
                        await context.push('/profile');
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: UserAccountHeader(),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
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
                : _FloatingHeaderSection(
                    onTapMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
          ),
          
          // Floating School Details bottom card
          if (selectedSchool != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _MobileSchoolDetailsCard(school: selectedSchool),
                ),
              ),
            ),

          // Floating Action Button (FAB) above details sheet or bottom nav
          Positioned(
            right: 16,
            bottom: selectedSchool != null 
                ? (size.height * 0.46) 
                : 16,
            child: FloatingActionButton(
              heroTag: 'my_location',
              onPressed: () {
                ref.read(mapMoveEventProvider.notifier).state = MapMoveEvent(
                  latitude: 15.8,
                  longitude: 108.0,
                  zoom: 6.0,
                  timestamp: DateTime.now(),
                );
                TopNotification.show(context, 'Đã đưa bản đồ về trung tâm Việt Nam.');
              },
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F766E),
              elevation: 3,
              shape: const CircleBorder(),
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingHeaderSection extends ConsumerWidget {
  const _FloatingHeaderSection({required this.onTapMenu});

  final VoidCallback onTapMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentQuery = ref.watch(schoolSearchQueryProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _MobileSearchBar(onTapMenu: onTapMenu),
              ),
            ),
          ),
          if (currentQuery.isEmpty)
            const SizedBox(
              height: 40,
              child: _FilterChipsScrollList(),
            ),
        ],
      ),
    );
  }
}

class FilterChipData {
  final String label;
  final String query;
  final IconData icon;

  const FilterChipData({
    required this.label,
    required this.query,
    required this.icon,
  });
}

const List<FilterChipData> filterChips = [
  FilterChipData(label: 'Trường THPT', query: 'THPT', icon: Icons.school_outlined),
  FilterChipData(label: 'Đông Nam Bộ', query: 'Đông Nam Bộ', icon: Icons.map_outlined),
  FilterChipData(label: 'Tây Nguyên', query: 'Tây Nguyên', icon: Icons.terrain_outlined),
  FilterChipData(label: 'Đồng bằng Sông Hồng', query: 'Sông Hồng', icon: Icons.water_outlined),
  FilterChipData(label: 'Đà Nẵng', query: 'Đà Nẵng', icon: Icons.location_city_outlined),
  FilterChipData(label: 'Cần Thơ', query: 'Cần Thơ', icon: Icons.location_city_outlined),
];

class _FilterChipsScrollList extends ConsumerWidget {
  const _FilterChipsScrollList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(schoolSearchQueryProvider);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filterChips.length,
      itemBuilder: (context, index) {
        final chip = filterChips[index];
        final isSelected = query.toLowerCase() == chip.query.toLowerCase();

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InputChip(
            label: Text(chip.label),
            avatar: Icon(
              chip.icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref.read(schoolSearchQueryProvider.notifier).state = chip.query;
              } else {
                ref.read(schoolSearchQueryProvider.notifier).state = '';
              }
            },
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF0F766E),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.05),
          ),
        );
      },
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
    final authUser = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    final displayName = profile?.fullName ?? authUser?.displayName ?? authUser?.email ?? '';
    final avatarUrl = profile?.avatarUrl ?? authUser?.photoURL;

    // Sync external changes
    if (searchQuery != _controller.text) {
      _controller.text = searchQuery;
    }

    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The input card
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.grey),
                  onPressed: widget.onTapMenu,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm trường học...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: false,
                    ),
                    onChanged: (val) {
                      ref.read(schoolSearchQueryProvider.notifier).state = val;
                    },
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                    onPressed: () {
                      _controller.clear();
                      ref.read(schoolSearchQueryProvider.notifier).state = '';
                    },
                  )
                else if (authUser != null)
                  GestureDetector(
                    onTap: () async {
                      await context.push('/profile');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Floating suggestion list overlay under the search bar
        if (_isFocused && searchQuery.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          schoolsAsync.when(
            data: (_) {
              if (filteredSchools.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Không tìm thấy trường học nào.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: filteredSchools.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final school = filteredSchools[index];
                    return ListTile(
                      leading: Icon(Icons.location_on_outlined, color: Colors.grey.shade500),
                      title: Text(
                        school.tenTruong,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        school.diaChi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                ),
              ),
            ),
            error: (err, _) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
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
        maxHeight: size.height * 0.44, 
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
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
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        school.diaChi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () {
                    ref.read(selectedSchoolIdProvider.notifier).state = null;
                    ref.read(schoolSearchQueryProvider.notifier).state = '';
                  },
                ),
              ],
            ),
          ),
          
          // Action Chips row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionChip(
                    context: context,
                    icon: Icons.directions_outlined,
                    label: 'Đường đi',
                    color: const Color(0xFF0F766E),
                    isSolid: true,
                    onTap: () {
                      ref.read(endSchoolProvider.notifier).state = school;
                      context.go('/directions');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionChip(
                    context: context,
                    icon: Icons.play_circle_fill_rounded,
                    label: 'Đi từ đây',
                    color: Colors.green.shade700,
                    onTap: () {
                      ref.read(startSchoolProvider.notifier).state = school;
                      TopNotification.show(context, 'Đã đặt điểm đi: ${school.tenTruong}');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionChip(
                    context: context,
                    icon: Icons.flag_rounded,
                    label: 'Đến đây',
                    color: Colors.red.shade700,
                    onTap: () {
                      ref.read(endSchoolProvider.notifier).state = school;
                      TopNotification.show(context, 'Đã đặt điểm đến: ${school.tenTruong}');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: Colors.grey.shade100),
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

  Widget _buildActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    bool isSolid = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSolid ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSolid ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSolid ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSolid ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
