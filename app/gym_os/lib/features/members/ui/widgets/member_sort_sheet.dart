import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/members_provider.dart';

/// Modal bottom sheet allowing users to select a sort option for the members list.
class MemberSortSheet extends ConsumerWidget {
  const MemberSortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSort = ref.watch(membersProvider).selectedSort;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Sheet Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.brandPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sort_rounded,
                    color: colors.brandPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.sortBy,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.brandPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Options List
            ...MemberSortOption.values.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = option == currentSort;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: InkWell(
                  onTap: () {
                    ref.read(membersProvider.notifier).setSort(option);
                    Navigator.pop(context);
                  },
                  borderRadius: AppSpacing.borderRadius,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.brandPrimary
                              .withValues(alpha: isDark ? 0.2 : 0.08)
                          : Colors.transparent,
                      borderRadius: AppSpacing.borderRadius,
                      border: Border.all(
                        color: isSelected
                            ? colors.brandPrimary.withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.brandPrimary.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            option.icon,
                            size: 18,
                            color: isSelected
                                ? colors.brandPrimary
                                : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            option.label(context.l10n),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? colors.brandPrimary
                                  : null,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.brandPrimary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: (30 * index).ms,
                    duration: 250.ms,
                  )
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  );
            }),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
