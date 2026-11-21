import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/widgets/floating_nav_bar.dart';
import 'package:gym_os/features/home/ui/dashboard_screen.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/settings/ui/settings_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../members/ui/members_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  /// Optional [StatefulNavigationShell] when used within GoRouter StatefulShellRoute.
  final StatefulNavigationShell? navigationShell;

  /// Optional pre-built branch navigators if provided by StatefulShellRoute.
  final List<Widget>? children;

  const MainLayout({
    super.key,
    this.navigationShell,
    this.children,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  late int _currentIndex;
  late final PageController _pageController;
  bool _isAnimatingPage = false;

  // Default screens kept alive across tabs via AutomaticKeepAliveClientMixin
  static const List<Widget> _defaultScreens = [
    DashboardScreen(),
    MembersScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell?.currentIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shell = widget.navigationShell;
    if (shell != null &&
        shell.currentIndex != _currentIndex &&
        !_isAnimatingPage) {
      _currentIndex = shell.currentIndex;
      if (_pageController.hasClients) {
        _isAnimatingPage = true;
        _pageController
            .animateToPage(
              shell.currentIndex,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              if (mounted) {
                _isAnimatingPage = false;
              }
            });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      ref.read(membersProvider.notifier).resetFilters();
      setState(() => _currentIndex = index);
      widget.navigationShell?.goBranch(index);

      if (_pageController.hasClients) {
        _isAnimatingPage = true;
        _pageController
            .animateToPage(
              index,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              if (mounted) {
                _isAnimatingPage = false;
              }
            });
      }
    }
  }

  void _onPageChanged(int index) {
    if (!_isAnimatingPage && _currentIndex != index) {
      HapticFeedback.selectionClick();
      ref.read(membersProvider.notifier).resetFilters();
      setState(() => _currentIndex = index);
      widget.navigationShell?.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = widget.children ?? _defaultScreens;

    return Scaffold(
      extendBody: true,
      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: _onPageChanged,
        itemCount: pages.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = (_pageController.page! - index);
              } else {
                value = (_currentIndex - index).toDouble();
              }
              // Normalise distance from current page
              final pageOffset = value.abs().clamp(0.0, 1.0);
              // Scale from 0.96 (inactive adjacent page) to 1.0 (active page)
              final scale = 1.0 - (0.04 * pageOffset);
              // Fade from 0.85 (inactive adjacent page) to 1.0 (active page)
              final opacity = 1.0 - (0.15 * pageOffset);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: pages[index],
          );
        },
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: [
          FloatingNavItem(
            icon: LucideIcons.layoutDashboard,
            activeIcon: LucideIcons.layoutDashboard,
            label: l10n.navDashboard,
          ),
          FloatingNavItem(
            icon: LucideIcons.users,
            activeIcon: LucideIcons.users,
            label: l10n.navMembers,
          ),
          FloatingNavItem(
            icon: LucideIcons.slidersHorizontal,
            activeIcon: LucideIcons.slidersHorizontal,
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
