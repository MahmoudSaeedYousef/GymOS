import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/utils/whatsapp_helper.dart';
import 'package:lottie/lottie.dart';
import 'package:gym_os/features/attendance/services/attendance_api_service.dart';
import 'package:gym_os/features/attendance/ui/widgets/check_in_success_dialog.dart';
import 'package:gym_os/features/payments/ui/renew_subscription_sheet.dart';
import 'package:intl/intl.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';
import 'add_member_sheet.dart';
import 'widgets/member_avatar.dart';
import 'widgets/member_sort_sheet.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String? initialFilter;

  const MembersScreen({super.key, this.initialFilter});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      final filter = MemberFilter.fromString(widget.initialFilter);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(membersProvider.notifier).setFilter(filter);
      });
    }
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(membersProvider.notifier).loadMore();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MembersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != null &&
        widget.initialFilter != oldWidget.initialFilter) {
      final filter = MemberFilter.fromString(widget.initialFilter);
      ref.read(membersProvider.notifier).setFilter(filter);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddMemberSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddMemberSheet(),
    );
    ref.invalidate(membersSummaryProvider);
  }

  void _openSortSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MemberSortSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(membersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayMembers = state.filteredMembers;

    // Keep the search text field in sync with state if state was reset
    if (state.searchQuery.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.membersTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Subtle icon-only refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: context.l10n.refresh,
            onPressed: () {
              ref.invalidate(membersSummaryProvider);
              ref.read(membersProvider.notifier).loadInitial();
            },
          ),
          // Sleek primary pill button for "+ New Member"
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _openAddMemberSheet,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                context.l10n.newMemberButton,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: Column(
          children: [
            // Members summary card
            _MembersSummaryCard(
              fallbackMembers: state.allMembers.isNotEmpty
                  ? state.allMembers
                  : state.members,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Clean rounded search bar without redundant outer label
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {});
                  ref.read(membersProvider.notifier).onSearchChanged(val);
                },
                decoration: InputDecoration(
                  hintText: context.l10n.searchMemberHint,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            ref
                                .read(membersProvider.notifier)
                                .onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Cohesive Filter & Sort Strip
            Row(
              children: [
                _SortTriggerButton(
                  selectedSort: state.selectedSort,
                  onTap: _openSortSheet,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: [
                        _FilterChipItem(
                          label: context.l10n.filterAll,
                          isSelected: state.selectedFilter == MemberFilter.all,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(membersProvider.notifier)
                                .setFilter(MemberFilter.all);
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChipItem(
                          label: context.l10n.filterActive,
                          isSelected:
                              state.selectedFilter == MemberFilter.active,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(membersProvider.notifier)
                                .setFilter(MemberFilter.active);
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChipItem(
                          label: context.l10n.filterExpiringSoon,
                          isSelected:
                              state.selectedFilter == MemberFilter.expiringSoon,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(membersProvider.notifier)
                                .setFilter(MemberFilter.expiringSoon);
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChipItem(
                          label: context.l10n.filterExpired,
                          isSelected:
                              state.selectedFilter == MemberFilter.expired,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(membersProvider.notifier)
                                .setFilter(MemberFilter.expired);
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChipItem(
                          label: context.l10n.filterTodayAttendance,
                          isSelected:
                              state.selectedFilter == MemberFilter.today,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(membersProvider.notifier)
                                .setFilter(MemberFilter.today);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayMembers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            size: 64,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            state.searchQuery.isEmpty
                                ? context.l10n.noMembersYetList
                                : context.l10n.noMembersFound,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(membersSummaryProvider);
                        await ref.read(membersProvider.notifier).loadInitial();
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 110),
                        itemCount:
                            displayMembers.length +
                            (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index == displayMembers.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return _MemberCardItem(
                            member: displayMembers[index],
                            selectedSort: state.selectedSort,
                            isSearching: state.searchQuery.trim().isNotEmpty,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MemberCardItem extends ConsumerStatefulWidget {
  final MemberModel member;
  final MemberSortOption selectedSort;
  final bool isSearching;

  const _MemberCardItem({
    required this.member,
    this.selectedSort = MemberSortOption.newest,
    this.isSearching = false,
  });

  @override
  ConsumerState<_MemberCardItem> createState() => _MemberCardItemState();
}

class _MemberCardItemState extends ConsumerState<_MemberCardItem> {
  bool _isCheckingIn = false;

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);
    try {
      final message = await ref
          .read(attendanceApiProvider)
          .checkIn(widget.member.id);

      if (!mounted) return;

      ref.read(membersProvider.notifier).resetFilters();

      await showCheckInSuccessAnimation(
        context,
        memberName: widget.member.fullName,
        message: message,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: context.gymColors.expired,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  void _handleRenew() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RenewSubscriptionSheet(member: widget.member),
    );
    if (result == true) {
      ref.invalidate(membersSummaryProvider);
    }
  }

  int? get _daysRemaining {
    final endStr = widget.member.subscriptionEndDate;
    if (endStr == null || endStr.trim().isEmpty) return null;
    final endDate = DateTime.tryParse(endStr);
    if (endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    return endDay.difference(today).inDays;
  }

  String _formatDaysRemaining(int days) {
    if (days < 0) {
      final overdue = days.abs();
      return 'منتهي منذ $overdue ${overdue == 1 ? "يوم" : "أيام"}';
    } else if (days == 0) {
      return 'ينتهي اليوم';
    } else if (days == 1) {
      return 'ينتهي غداً';
    } else if (days == 2) {
      return 'باقي يومين';
    } else if (days <= 10) {
      return 'باقي $days أيام';
    } else {
      return 'باقي $days يوم';
    }
  }

  String _getContextualInfo() {
    final days = _daysRemaining;
    switch (widget.selectedSort) {
      case MemberSortOption.newest:
        // Use relative start time if available, or fall back to remaining days
        if (days != null) {
          return _formatDaysRemaining(days);
        }
        return 'عضو جديد';

      case MemberSortOption.expiringSoon:
        if (days != null) {
          if (days < 0) {
            final overdue = days.abs();
            return 'منتهي منذ $overdue ${overdue == 1 ? "يوم" : "أيام"}';
          } else if (days == 0) {
            return 'ينتهي اليوم';
          } else if (days == 1) {
            return 'ينتهي غداً';
          } else if (days <= 10) {
            return 'باقي $days أيام';
          } else {
            return 'باقي $days يوم';
          }
        }
        return 'بدون تاريخ انتهاء';

      case MemberSortOption.endDateDesc:
        final formattedDate = _formatExpiryDate(widget.member.subscriptionEndDate);
        if (formattedDate.isNotEmpty) {
          return 'ينتهي $formattedDate';
        }
        return 'بدون تاريخ انتهاء';

      case MemberSortOption.name:
      case MemberSortOption.plan:
        if (days != null) {
          return _formatDaysRemaining(days);
        }
        return '';

      case MemberSortOption.lastCheckIn:
        return 'لم يحضر بعد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = widget.member.status;
    final l10n = context.l10n;

    // Status colors and label (Exceptions Only: Expiring Soon or Expired)
    Color? statusColor;
    String? statusLabel;
    final days = _daysRemaining;

    if (status == MemberSubscriptionStatus.expiringSoon) {
      statusColor = const Color(0xFFD97706); // Crisp Amber
      if (days != null) {
        if (days == 0) {
          statusLabel = 'ينتهي اليوم';
        } else if (days == 1) {
          statusLabel = 'ينتهي غداً';
        } else if (days == 2) {
          statusLabel = 'باقي يومين';
        } else if (days <= 10) {
          statusLabel = 'باقي $days أيام';
        } else {
          statusLabel = 'باقي $days يوم';
        }
      } else {
        statusLabel = l10n.expiringSoonStatus;
      }
    } else if (status == MemberSubscriptionStatus.expired) {
      statusColor = const Color(0xFFDC2626); // Crisp Red
      if (days != null && days < 0) {
        final overdue = days.abs();
        statusLabel = 'منتهي منذ $overdue ${overdue == 1 ? "يوم" : "أيام"}';
      } else {
        statusLabel = l10n.expiredStatus;
      }
    } else if (status == MemberSubscriptionStatus.withoutPlan) {
      statusColor = colorScheme.outline;
      statusLabel = l10n.noPlan;
    }

    final planName = widget.member.activePlanName;
    final contextualInfo = _getContextualInfo();
    final isPlanSort = widget.selectedSort == MemberSortOption.plan;

    return GymCard(
      onTap: () {
        context.pushNamed('memberProfile', extra: widget.member);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Leading Avatar: 44dp circular network/fallback badge
          MemberAvatar(
            photoUrl: widget.member.photoUrl,
            fullName: widget.member.fullName,
            radius: 22,
            fontSize: 18,
          ),
          const SizedBox(width: AppSpacing.md),

          // 2. Middle Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Line 1: Member Full Name (bold, single line with ellipsis) + Optional Status Badge (Exceptions only)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.member.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (statusLabel != null && statusColor != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                // Line 2: Contextual Metadata (PlanName • ContextualInfo)
                Row(
                  children: [
                    if (planName != null && planName.trim().isNotEmpty) ...[
                      Text(
                        planName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isPlanSort ? FontWeight.w600 : FontWeight.normal,
                          color: isPlanSort
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.85,
                                ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contextualInfo.isNotEmpty) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            contextualInfo,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.75,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ] else ...[
                      Expanded(
                        child: Text(
                          contextualInfo.isNotEmpty
                              ? contextualInfo
                              : l10n.noPlan,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.75,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                // Subtle 3rd line: Phone Number (ONLY when search query is non-empty)
                if (widget.isSearching) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.member.phoneNumber,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // 3. Quick Action Trailing Button
          if (status == MemberSubscriptionStatus.active)
            IconButton.filledTonal(
              onPressed: _isCheckingIn ? null : _handleCheckIn,
              icon: _isCheckingIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint_rounded, size: 20),
              tooltip: l10n.checkIn,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(8),
              ),
            )
          else ...[
            IconButton.filledTonal(
              onPressed: _handleRenew,
              icon: const Icon(Icons.autorenew_rounded, size: 20),
              tooltip: l10n.renewPlan,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(8),
              ),
            ),
            IconButton(
              icon: Lottie.asset(
                'assets/animations/Whatsapp.json',
                width: 24,
                height: 24,
                repeat: false,
              ),
              tooltip: l10n.sendWhatsappReminder,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                WhatsAppHelper.sendRenewalReminder(
                  context,
                  phoneNumber: widget.member.phoneNumber,
                  memberName: widget.member.fullName,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SortTriggerButton extends StatelessWidget {
  final MemberSortOption selectedSort;
  final VoidCallback onTap;

  const _SortTriggerButton({required this.selectedSort, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCustomSort = selectedSort != MemberSortOption.newest;
    final sortLabel = selectedSort.label(context.l10n);

    return Tooltip(
      message: '${context.l10n.sortBy}: $sortLabel',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isCustomSort
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustomSort
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selectedSort.icon,
                    size: 18,
                    color: isCustomSort
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  if (isCustomSort)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 5),
              Text(
                sortLabel,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCustomSort ? FontWeight.bold : FontWeight.w600,
                  color: isCustomSort
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatExpiryDate(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) return '';
  final parsed = DateTime.tryParse(rawDate);
  if (parsed != null) {
    return DateFormat('yyyy-MM-dd').format(parsed);
  }
  // Fallback: if already starts with yyyy-MM-dd, take first 10 chars
  if (rawDate.length >= 10) {
    return rawDate.substring(0, 10);
  }
  return rawDate;
}

class _MembersSummaryCard extends ConsumerWidget {
  final List<MemberModel> fallbackMembers;

  const _MembersSummaryCard({
    required this.fallbackMembers,
  });

  Widget _buildStatusPill({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.gymColors;
    final l10n = context.l10n;

    final summaryAsync = ref.watch(membersSummaryProvider);
    final summaryData = summaryAsync.asData?.value;

    final int totalMembers;
    final int activeCount;
    final int expiredCount;
    final int expiringSoonCount;
    final List<MembersSummaryPlanItem> plans;

    if (summaryData != null) {
      totalMembers = summaryData.totalCount;
      activeCount = summaryData.activeCount;
      expiredCount = summaryData.expiredCount;
      expiringSoonCount = summaryData.expiringSoonCount;
      plans = summaryData.plans;
    } else {
      final nonGuestMembers =
          fallbackMembers.where((m) => !m.isGuest).toList();
      totalMembers = nonGuestMembers.length;
      activeCount = nonGuestMembers
          .where((m) => m.subscriptionStatus.toLowerCase() == 'active')
          .length;
      expiredCount = totalMembers - activeCount;
      expiringSoonCount = nonGuestMembers.where((m) => m.isExpiringSoon).length;

      final planMap = <String, int>{};
      for (final m in nonGuestMembers) {
        final rawPlan = m.activePlanName;
        final planName = (rawPlan != null && rawPlan.trim().isNotEmpty)
            ? rawPlan.trim()
            : '';
        planMap[planName] = (planMap[planName] ?? 0) + 1;
      }
      plans = planMap.entries
          .map((e) => MembersSummaryPlanItem(planName: e.key, count: e.value))
          .toList();
    }

    return GymCard(
      elevationLevel: 1,
      borderRadius: AppSpacing.borderRadiusMd,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Clean icon container + "إجمالي المشتركين" label + bold prominent total number on one side,
          // and compact status pills (نشط: X • ينتهي قريباً: Y • منتهي: Z) on the other side.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: colors.brandPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.totalMembers,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalMembers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildStatusPill(
                      label: '${l10n.activeStatus}: $activeCount',
                      color: const Color(0xFF16A34A),
                    ),
                    _buildStatusPill(
                      label: '${l10n.expiringSoonStatus}: $expiringSoonCount',
                      color: const Color(0xFFD97706),
                    ),
                    _buildStatusPill(
                      label: '${l10n.expiredStatus}: $expiredCount',
                      color: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (plans.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(
                height: 1,
                thickness: 1,
                color: colors.surfaceBorder.withValues(alpha: 0.7),
              ),
            ),
            // Bottom Section: Clean horizontal scrollable row of plan badges, each showing
            // plan name and crisp numeric pill badge for its count (e.g., [ شهري  45 ])
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: plans.map((planItem) {
                  final displayName = planItem.planName.trim().isEmpty
                      ? l10n.noPlan
                      : planItem.planName;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceLevel2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.surfaceBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.brandPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${planItem.count}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.brandPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
