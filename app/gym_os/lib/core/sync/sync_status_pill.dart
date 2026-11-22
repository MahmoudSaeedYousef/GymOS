import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import 'sync_provider.dart';

/// Compact circular icon button (38dp) displaying synchronization state
/// with rotating animation while syncing and corner dot/badge for pending/offline items.
class SyncStatusPill extends ConsumerStatefulWidget {
  const SyncStatusPill({super.key});

  @override
  ConsumerState<SyncStatusPill> createState() => _SyncStatusPillState();
}

class _SyncStatusPillState extends ConsumerState<SyncStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final l10n = context.l10n;
    final engine = ref.watch(syncEngineProvider);
    final syncStateAsync = ref.watch(syncStateProvider);
    final state = syncStateAsync.value ?? engine.currentState;

    if (state.isSyncing) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
        _rotationController.reset();
      }
    }

    // Determine tooltip/semantics, badge, and color based on state
    String tooltipText;
    Color iconColor;
    Color borderColor = colors.surfaceBorder;
    Color bgColor = colors.surfaceLevel2;
    Widget? badge;

    if (state.isSyncing) {
      tooltipText = l10n.syncStatusSyncing(state.pendingCount);
      iconColor = colors.brandPrimary;
      bgColor = colors.brandPrimary.withValues(alpha: 0.12);
      borderColor = colors.brandPrimary.withValues(alpha: 0.3);
    } else if (!state.isOnline) {
      if (state.pendingCount > 0) {
        tooltipText = l10n.syncStatusOfflineWithQueued(state.pendingCount);
        const amberColor = Color(0xFFF59E0B);
        iconColor = amberColor;
        bgColor = amberColor.withValues(alpha: 0.12);
        borderColor = amberColor.withValues(alpha: 0.35);

        badge = Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: amberColor,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surfaceLevel1, width: 1.5),
          ),
          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
          child: Center(
            child: Text(
              '${state.pendingCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        );
      } else {
        tooltipText = l10n.syncStatusOffline;
        iconColor = colors.textSecondary;
        badge = Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors.expired,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surfaceLevel1, width: 1.5),
          ),
        );
      }
    } else if (state.pendingCount > 0) {
      tooltipText = l10n.syncStatusSyncing(state.pendingCount);
      const amberColor = Color(0xFFF59E0B);
      iconColor = amberColor;
      badge = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: amberColor,
          shape: BoxShape.circle,
          border: Border.all(color: colors.surfaceLevel1, width: 1.5),
        ),
        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
        child: Center(
          child: Text(
            '${state.pendingCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
      );
    } else {
      tooltipText = l10n.syncStatusSynced;
      iconColor = colors.active;
      bgColor = colors.surfaceLevel2;
      borderColor = colors.surfaceBorder;
    }

    return Tooltip(
      message: tooltipText,
      child: Semantics(
        button: true,
        label: tooltipText,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(syncEngineProvider).syncNow();
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: Icon(
                      state.isOnline
                          ? Icons.sync_rounded
                          : Icons.cloud_off_rounded,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: badge,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
