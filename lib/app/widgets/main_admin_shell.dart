import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainAdminShell extends StatelessWidget {
  const MainAdminShell({super.key, required this.child});

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/admin') return 0;
    if (location.startsWith('/admin/campaigns')) return 1;
    if (location.startsWith('/admin/statistics')) return 2;
    if (location.startsWith('/admin/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/campaigns');
        break;
      case 2:
        context.go('/admin/statistics');
        break;
      case 3:
        context.go('/admin/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFF0F766E)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign, color: Color(0xFF0F766E)),
              label: 'Chiến dịch',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF0F766E)),
              label: 'Thống kê',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF0F766E)),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
