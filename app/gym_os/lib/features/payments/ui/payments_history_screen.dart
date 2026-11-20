import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/animated_counter.dart';
import '../../../core/ui/atoms/gym_card.dart';
import '../../../core/ui/gym_ambient_background.dart';
import '../../../core/ui/gym_shimmer_box.dart';
import '../providers/payments_provider.dart';

/// Screen displaying revenue summary and transaction history for GymOS.
class PaymentsHistoryScreen extends ConsumerWidget {
  const PaymentsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.gymColors;
    final selectedPeriod = ref.watch(paymentsPeriodProvider);
    final summaryAsync = ref.watch(paymentsSummaryProvider);

    return GymAmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            context.l10n.paymentsHistory,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(paymentsSummaryProvider);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => ref.refresh(paymentsSummaryProvider.future),
          color: colors.brandPrimary,
          child: Column(
            children: [
              // Period Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: _PeriodFilterSelector(
                  selectedPeriod: selectedPeriod,
                  onPeriodChanged: (period) {
                    HapticFeedback.selectionClick();
                    ref.read(paymentsPeriodProvider.notifier).setPeriod(period);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Content Body
              Expanded(
                child: summaryAsync.when(
                  data: (summary) => _PaymentsContent(summary: summary),
                  loading: () => const _PaymentsSkeleton(),
                  error: (error, _) => _PaymentsErrorState(
                    errorMessage: error.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.invalidate(paymentsSummaryProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selector row for Today / This Month / All Time periods.
class _PeriodFilterSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const _PeriodFilterSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final periods = [
      (key: 'today', label: context.l10n.periodToday),
      (key: 'month', label: context.l10n.periodThisMonth),
      (key: 'all', label: context.l10n.periodAllTime),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceBackground.withValues(alpha: 0.6)
            : colors.brandPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.brandPrimary.withValues(alpha: isDark ? 0.15 : 0.08),
        ),
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = selectedPeriod == p.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPeriodChanged(p.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.brandPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.brandPrimary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Main content when data is loaded successfully.
class _PaymentsContent extends StatelessWidget {
  final PaymentsSummaryModel summary;

  const _PaymentsContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // 1. Register & Revenue Summary Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: _RegisterSummaryCard(summary: summary)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          ),
        ),

        // 2. Section Header: Transactions Count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: context.gymColors.brandPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.paymentsHistory,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.gymColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${summary.items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.gymColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Transactions List or Empty State
        if (summary.items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: _EmptyPaymentsView()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = summary.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PaymentTransactionTile(item: item)
                        .animate()
                        .fadeIn(
                          delay: (30 * index).ms,
                          duration: 300.ms,
                        )
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                  );
                },
                childCount: summary.items.length,
              ),
            ),
          ),
      ],
    );
  }
}

/// Register summary card showing total collected and payment method breakdown.
class _RegisterSummaryCard extends StatelessWidget {
  final PaymentsSummaryModel summary;

  const _RegisterSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return GymCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Collected Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.active.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: colors.active,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.totalCollected,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Total Number with Counter Animation
          AnimatedCounter(
            value: summary.totalAmount,
            suffix: ' ${context.l10n.currency}',
            fractionDigits: 0,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colors.active,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            height: 1,
          ),
          const SizedBox(height: AppSpacing.md),

          // Register Breakdown Title
          Text(
            context.l10n.registerBreakdown,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              color: secondaryTextColor,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // 2x2 Grid of Method Breakdown
          Row(
            children: [
              Expanded(
                child: _MethodBreakdownItem(
                  label: context.l10n.cashBreakdown,
                  amount: summary.cashTotal,
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MethodBreakdownItem(
                  label: context.l10n.instaPayBreakdown,
                  amount: summary.instaPayTotal,
                  icon: Icons.send_to_mobile_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MethodBreakdownItem(
                  label: context.l10n.vodafoneCashBreakdown,
                  amount: summary.vodafoneCashTotal,
                  icon: Icons.phone_android_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MethodBreakdownItem(
                  label: context.l10n.visaBreakdown,
                  amount: summary.visaTotal,
                  icon: Icons.credit_card_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small pill displaying payment method breakdown.
class _MethodBreakdownItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _MethodBreakdownItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.gymColors;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceBackground.withValues(alpha: 0.4)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${amount.toStringAsFixed(0)} ${context.l10n.currency}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: amount > 0 ? color : secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction list tile for an individual payment record.
class _PaymentTransactionTile extends StatelessWidget {
  final PaymentItemModel item;

  const _PaymentTransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final methodColor = _getMethodColor(item.method);
    final formattedDate = DateFormat('yyyy/MM/dd - hh:mm a').format(item.paymentDate);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: AppSpacing.borderRadius,
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Method Icon Avatar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getMethodIcon(item.method),
                  size: 20,
                  color: methodColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Member Details & Plan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.memberName.isNotEmpty
                          ? item.memberName
                          : '-',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.memberPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.memberPhone,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Amount Paid
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${item.amount.toStringAsFixed(0)} ${context.l10n.currency}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.active,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Badges: Plan Name + Payment Method Badge + Notes
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Plan Badge
              if (item.planName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brandPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_membership_rounded,
                        size: 12,
                        color: colors.brandPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.planName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Method Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.method.localizedLabel(context.l10n),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: methodColor,
                  ),
                ),
              ),

              // Notes preview if present
              if (item.notes != null && item.notes!.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 12,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.notes!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _getMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return const Color(0xFF10B981);
      case PaymentMethod.visa:
        return const Color(0xFF3B82F6);
      case PaymentMethod.instaPay:
        return const Color(0xFF8B5CF6);
      case PaymentMethod.vodafoneCash:
        return const Color(0xFFEF4444);
      case PaymentMethod.other:
        return Colors.grey;
    }
  }

  static IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.visa:
        return Icons.credit_card_rounded;
      case PaymentMethod.instaPay:
        return Icons.send_to_mobile_rounded;
      case PaymentMethod.vodafoneCash:
        return Icons.phone_android_rounded;
      case PaymentMethod.other:
        return Icons.receipt_rounded;
    }
  }
}

/// Clean localized empty state when no payments are found.
class _EmptyPaymentsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.brandPrimary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 36,
            color: colors.brandPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.noPaymentsFound,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

/// Shimmer skeleton loader for payments summary and list.
class _PaymentsSkeleton extends StatelessWidget {
  const _PaymentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          // Register Summary Card Skeleton
          const GymShimmerBox(height: 200),
          const SizedBox(height: AppSpacing.md),

          // Header Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              GymShimmerBox(width: 140, height: 20),
              GymShimmerBox(width: 36, height: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // List Items Skeleton
          ...List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: GymShimmerBox(height: 84),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean error state with retry button.
class _PaymentsErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _PaymentsErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colors.expired,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
