import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation item configuration for [FloatingNavBar].
class FloatingNavItem {
  /// Unselected/outlined icon.
  final IconData icon;

  /// Selected/filled or active icon.
  final IconData activeIcon;

  /// Localized label.
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A sleek, compact sporty floating dock bottom navigation bar with
/// modern rounded icons, gradient active pill, and crisp micro-animations.
class FloatingNavBar extends StatelessWidget {
  /// Index of the currently active tab.
  final int currentIndex;

  /// Callback when a tab is tapped.
  final ValueChanged<int> onTap;

  /// List of navigation destinations.
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Solid/elevated surface: surfaceContainerHighest in dark mode, surface in light mode
    final dockSurfaceColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surface;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: dockSurfaceColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = index == currentIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _NavBarItem(
                    item: item,
                    isActive: isActive,
                    onTap: () {
                      if (!isActive) {
                        HapticFeedback.selectionClick();
                        onTap(index);
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Rich two-stop LinearGradient built from colorScheme.primary to Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.35)!
    final secondaryGradientColor = Color.lerp(
      colorScheme.primary,
      colorScheme.tertiary,
      0.35,
    )!;

    final activeGradient = LinearGradient(
      colors: [colorScheme.primary, secondaryGradientColor],
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
    );

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            height: 44,
            constraints: const BoxConstraints(minWidth: 44),
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 14 : 10,
            ),
            decoration: BoxDecoration(
              gradient: isActive ? activeGradient : null,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1.0).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    key: ValueKey<bool>(isActive),
                    size: isActive ? 18 : 20,
                    color: isActive
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: AlignmentDirectional.centerStart,
                    child: isActive
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
