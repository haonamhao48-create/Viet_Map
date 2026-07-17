import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainUserShell extends StatelessWidget {
  const MainUserShell({super.key, required this.child});

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/directions')) return 1;
    if (location.startsWith('/campaigns') || location.startsWith('/my-events')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/directions');
        break;
      case 2:
        context.go('/campaigns');
        break;
      case 3:
        context.go('/profile');
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
            top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0F766E),
          unselectedItemColor: Colors.grey.shade600,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
          unselectedLabelStyle: const TextStyle(letterSpacing: 0.2),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined, size: 22),
              activeIcon: Icon(Icons.map, size: 22),
              label: 'Bản đồ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_outlined, size: 22),
              activeIcon: Icon(Icons.directions, size: 22),
              label: 'Đường đi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined, size: 22),
              activeIcon: Icon(Icons.campaign, size: 22),
              label: 'Chiến dịch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 22),
              activeIcon: Icon(Icons.person, size: 22),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
