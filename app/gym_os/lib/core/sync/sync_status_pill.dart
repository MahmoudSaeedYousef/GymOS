import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'sync_provider.dart';

/// Compact circular icon button (38dp) displaying synchronization state
/// with rotating animation while syncing and corner dot/badge for pending/failed items.
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

  void _showFailedItemsSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.gymColors.surfaceBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _FailedSyncOperationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final engine = ref.watch(syncEngineProvider);
    final syncStateAsync = ref.watch(syncStateProvider);
    final failedCountAsync = ref.watch(syncFailedCountProvider);
    final state = syncStateAsync.value ?? engine.currentState;
    final failedCount = failedCountAsync.value ?? state.failedCount;

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

    if (failedCount > 0) {
      // 1. Failed items exist: STRICTLY RED icon/badge (NEVER green!)
      tooltipText = isArabic
          ? 'فشل مزامنة $failedCount عنصر — انقر للتفاصيل وإعادة المحاولة'
          : 'Sync failed for $failedCount item(s) — tap to view and retry';
      final redColor = colors.expired;
      iconColor = redColor;
      bgColor = redColor.withValues(alpha: 0.12);
      borderColor = redColor.withValues(alpha: 0.4);

      badge = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: redColor,
          shape: BoxShape.circle,
          border: Border.all(color: colors.surfaceLevel1, width: 1.5),
        ),
        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
        child: Center(
          child: Text(
            '$failedCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
      );
    } else if (state.isSyncing) {
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
              if (failedCount > 0) {
                _showFailedItemsSheet(context);
              } else {
                HapticFeedback.lightImpact();
                ref.read(syncEngineProvider).syncNow();
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
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
                      failedCount > 0
                          ? Icons.sync_problem_rounded
                          : (state.isOnline
                                ? Icons.sync_rounded
                                : Icons.cloud_off_rounded),
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  if (badge != null)
                    Positioned(top: -2, right: -2, child: badge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FailedSyncOperationsSheet extends ConsumerStatefulWidget {
  const _FailedSyncOperationsSheet();

  @override
  ConsumerState<_FailedSyncOperationsSheet> createState() =>
      _FailedSyncOperationsSheetState();
}

class _FailedSyncOperationsSheetState
    extends ConsumerState<_FailedSyncOperationsSheet> {
  bool _isRetrying = false;

  String _formatEntityType(String entityType, bool isArabic) {
    switch (entityType) {
      case 'member_create':
        return isArabic ? 'إضافة مشترك جديد' : 'New Member';
      case 'member_renew':
        return isArabic ? 'تجديد اشتراك' : 'Member Renewal';
      case 'dropin':
        return isArabic ? 'جلسة زيارة حرة' : 'Drop-in Visit';
      case 'checkin':
        return isArabic ? 'تسجيل دخول' : 'Check-in';
      case 'checkout':
        return isArabic ? 'تسجيل خروج' : 'Check-out';
      default:
        return entityType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final db = ref.watch(appDatabaseProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: FutureBuilder<List<SyncOutboxData>>(
          future: db.syncOutboxDao.getFailedOperations(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colors.expired,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isArabic ? 'العمليات غير المزامنة' : 'Failed Sync Items',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.expired.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          color: colors.expired,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isArabic
                      ? 'حدث خطأ أثناء مزامنة هذه العمليات مع الخادم. يمكنك مراجعة سبب الخطأ وإعادة المحاولة.'
                      : 'These actions failed to sync to the server. You can review the error and retry.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child:
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const CircularProgressIndicator.adaptive()
                                : Text(
                                    isArabic
                                        ? 'لا توجد عمليات فاشلة'
                                        : 'No failed operations',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final errorMsg =
                                item.lastError ??
                                (isArabic ? 'خطأ غير معروف' : 'Unknown error');

                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: colors.surfaceLevel1,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.surfaceBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatEntityType(
                                          item.entityType,
                                          isArabic,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        isArabic
                                            ? 'محاولات: ${item.retryCount}'
                                            : 'Retries: ${item.retryCount}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    errorMsg,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.expired,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _isRetrying
                      ? null
                      : () async {
                          setState(() => _isRetrying = true);
                          try {
                            await ref.read(syncEngineProvider).retryFailed();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } finally {
                            if (mounted) setState(() => _isRetrying = false);
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    isArabic ? 'إعادة المحاولة' : 'Retry',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
