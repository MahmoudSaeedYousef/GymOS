import 'package:flutter/material.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/features/home/ui/dashboard_screen.dart';
import 'package:gym_os/features/settings/ui/settings_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../members/ui/members_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // الشاشات اللي هنتنقل بينها
  final List<Widget> _screens = const [
    DashboardScreen(), // 👈 الشاشة الفخمة الجديدة
    MembersScreen(),
    SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final l10n = context.l10n;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: colors.surfaceBackground,
        indicatorColor: colors.brandPrimary.withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: l10n.navMembers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
