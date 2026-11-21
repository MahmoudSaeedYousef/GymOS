import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'sync_provider.dart';

/// Compact, Material 3 styled status pill displaying synchronization state.
class SyncStatusPill extends ConsumerWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.gymColors;
    final engine = ref.watch(syncEngineProvider);
    final syncStateAsync = ref.watch(syncStateProvider);
    final state = syncStateAsync.value ?? engine.currentState;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    Widget pillContent;
    Color bgColor;
    Color borderColor;

    if (state.isSyncing) {
      // 1. Syncing state: Spinner + label with count
      final label = isArabic
          ? 'جاري المزامنة (${state.pendingCount})'
          : 'Syncing (${state.pendingCount})';

      bgColor = colors.brandPrimary.withValues(alpha: 0.12);
      borderColor = colors.brandPrimary.withValues(alpha: 0.3);

      pillContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.brandPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.brandPrimary,
            ),
          ),
        ],
      );
    } else if (!state.isOnline) {
      if (state.pendingCount > 0) {
        // 2. Offline with pending items: Amber badge
        final label = isArabic
            ? 'أوفلاين • ${state.pendingCount} بالانتظار'
            : 'Offline • ${state.pendingCount} queued';

        const amberColor = Color(0xFFF59E0B);
        bgColor = amberColor.withValues(alpha: 0.14);
        borderColor = amberColor.withValues(alpha: 0.35);

        pillContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 13, color: amberColor),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: amberColor,
              ),
            ),
          ],
        );
      } else {
        // 3. Offline without pending items: Muted gray badge
        final label = isArabic ? 'أوفلاين' : 'Offline';

        bgColor = colors.surfaceLevel2;
        borderColor = colors.surfaceBorder;

        pillContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 13, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        );
      }
    } else {
      // 4. Online and synced (pending == 0)
      final label = isArabic ? 'متزامن' : 'Synced';

      bgColor = colors.active.withValues(alpha: 0.12);
      borderColor = colors.active.withValues(alpha: 0.3);

      pillContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colors.active,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.active,
            ),
          ),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(syncEngineProvider).syncNow();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: pillContent,
        ),
      ),
    );
  }
}
