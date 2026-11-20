import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/theme/app_spacing.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/ui/gym_ambient_background.dart';
import 'package:gym_os/core/ui/gym_shimmer_box.dart';
import '../providers/plans_provider.dart';
import 'widgets/upsert_plan_sheet.dart';

class PlansManagementScreen extends ConsumerStatefulWidget {
  const PlansManagementScreen({super.key});

  @override
  ConsumerState<PlansManagementScreen> createState() =>
      _PlansManagementScreenState();
}

class _PlansManagementScreenState extends ConsumerState<PlansManagementScreen> {
  final Set<String> _togglingIds = {};

  void _openUpsertSheet([PlanModel? plan]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UpsertPlanSheet(plan: plan),
    );
  }

  Future<void> _toggleStatus(PlanModel plan) async {
    if (_togglingIds.contains(plan.id)) return;

    setState(() => _togglingIds.add(plan.id));
    HapticFeedback.lightImpact();

    try {
      await ref.read(plansApiServiceProvider).togglePlanStatus(plan.id);

      // Invalidate providers
      ref.invalidate(allPlansProvider);
      ref.invalidate(activePlansProvider);
      ref.invalidate(plansProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.planStatusUpdated),
          backgroundColor: context.gymColors.active,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.errorWithMessage(
              e.toString().replaceAll('Exception: ', ''),
            ),
          ),
          backgroundColor: context.gymColors.expired,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _togglingIds.remove(plan.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plansAsync = ref.watch(allPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.managePlans),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allPlansProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.brandPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _openUpsertSheet(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          context.l10n.addPlan,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: GymAmbientBackground(
        child: RefreshIndicator(
          color: colors.brandPrimary,
          onRefresh: () async {
            ref.invalidate(allPlansProvider);
            await ref.read(allPlansProvider.future);
          },
          child: plansAsync.when(
            data: (plans) {
              if (plans.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: colors.brandPrimary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.card_membership_rounded,
                              size: 64,
                              color: colors.brandPrimary.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            context.l10n.noPlansYet,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  96, // Bottom space for FAB
                ),
                itemCount: plans.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isToggling = _togglingIds.contains(plan.id);

                  return GymCard(
                    onTap: () => _openUpsertSheet(plan),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Title, Duration Badge, Active Switch
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colors.brandPrimary.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.card_membership_rounded,
                                color: colors.brandPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.brandPrimary.withValues(
                                        alpha: isDark ? 0.2 : 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      context.l10n.durationDays(
                                        plan.durationInDays,
                                      ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colors.brandPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (isToggling)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Switch.adaptive(
                                value: plan.isActive,
                                activeTrackColor: colors.active,
                                onChanged: (_) => _toggleStatus(plan),
                              ),
                          ],
                        ),

                        // Description if present
                        if (plan.description != null &&
                            plan.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            plan.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.sm),

                        // Bottom Row: Price & Status Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price
                            Text(
                              context.l10n.planPriceFormatted(
                                plan.price.toInt().toString(),
                                context.l10n.currency,
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: colors.brandPrimary,
                              ),
                            ),

                            // Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (plan.isActive
                                        ? colors.active
                                        : colors.expired)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: (plan.isActive
                                          ? colors.active
                                          : colors.expired)
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: plan.isActive
                                          ? colors.active
                                          : colors.expired,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    plan.isActive
                                        ? context.l10n.activePlan
                                        : context.l10n.inactivePlan,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: plan.isActive
                                          ? colors.active
                                          : colors.expired,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: (index * 50).ms,
                        duration: 300.ms,
                      )
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        curve: Curves.easeOutCubic,
                      );
                },
              );
            },
            loading: () => ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                96,
              ),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, _) => const GymShimmerBox(
                height: 116,
                borderRadius: 16,
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.errorWithMessage(err.toString()),
                      style: TextStyle(color: colors.expired),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(allPlansProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
