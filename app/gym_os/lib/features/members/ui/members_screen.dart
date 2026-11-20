import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/ui/atoms/gym_text_field.dart';
import 'package:gym_os/core/utils/whatsapp_helper.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';
import 'add_member_sheet.dart';
import 'widgets/member_sort_sheet.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String? initialFilter;

  const MembersScreen({super.key, this.initialFilter});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _scrollController = ScrollController();

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
    super.dispose();
  }

  void _openAddMemberSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddMemberSheet(),
    );
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
    final state = ref.watch(membersProvider);
    final colors = context.gymColors;
    final displayMembers = state.filteredMembers;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.membersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(membersProvider.notifier).loadInitial(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.brandPrimary,
        foregroundColor: Colors.white,
        onPressed: _openAddMemberSheet,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(
          context.l10n.newMemberButton,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            GymTextField(
              label: context.l10n.search,
              hint: context.l10n.searchMemberHint,
              prefixIcon: Icons.search_rounded,
              onChanged: (val) =>
                  ref.read(membersProvider.notifier).onSearchChanged(val),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Sort & Filter Chips Row
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
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _FilterChipItem(
                          label: context.l10n.filterAll,
                          isSelected: state.selectedFilter == MemberFilter.all,
                          color: colors.brandPrimary,
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
                          isSelected: state.selectedFilter == MemberFilter.active,
                          color: colors.active,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(membersProvider.notifier)
                                .setFilter(MemberFilter.active);
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChipItem(
                          label: context.l10n.filterExpired,
                          isSelected: state.selectedFilter == MemberFilter.expired,
                          color: colors.expired,
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
                          isSelected: state.selectedFilter == MemberFilter.today,
                          color: colors.brandPrimary,
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
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            state.searchQuery.isEmpty
                                ? context.l10n.noMembersYetList
                                : context.l10n.noMembersFound,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(membersProvider.notifier).loadInitial(),
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
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
                          return _MemberCardItem(member: displayMembers[index]);
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
  final Color color;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : color.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : color.withValues(alpha: isDark ? 0.25 : 0.18),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white.withValues(alpha: 0.9) : color),
          ),
        ),
      ),
    );
  }
}

class _MemberCardItem extends StatelessWidget {
  final MemberModel member;
  const _MemberCardItem({required this.member});

  @override
  Widget build(BuildContext context) {
    final gymColors = context.gymColors;
    final isActive = member.subscriptionStatus.toLowerCase() == 'active';
    final statusColor = isActive ? gymColors.active : gymColors.expired;

    return GymCard(
      onTap: () {
        context.pushNamed(
          'memberProfile',
          extra: member, // بنباصي الـ MemberModel هنا
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: gymColors.brandPrimary.withValues(alpha: 0.08),
            child: Text(
              member.fullName.trim().isNotEmpty
                  ? member.fullName.trim()[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: gymColors.brandPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      member.phoneNumber,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (member.activePlanName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${member.activePlanName} • ${context.l10n.expiresOn(member.subscriptionEndDate ?? '')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!isActive) ...[
            IconButton(
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: gymColors.active,
                size: 20,
              ),
              tooltip: context.l10n.sendWhatsappReminder,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              onPressed: () {
                WhatsAppHelper.sendRenewalReminder(
                  context,
                  phoneNumber: member.phoneNumber,
                  memberName: member.fullName,
                );
              },
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              isActive ? context.l10n.activeStatus : context.l10n.expiredStatus,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortTriggerButton extends StatelessWidget {
  final MemberSortOption selectedSort;
  final VoidCallback onTap;

  const _SortTriggerButton({
    required this.selectedSort,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCustomSort = selectedSort != MemberSortOption.newest;

    return Tooltip(
      message: '${context.l10n.sortBy}: ${selectedSort.label(context.l10n)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isCustomSort
                ? colors.brandPrimary.withValues(alpha: isDark ? 0.25 : 0.12)
                : colors.brandPrimary.withValues(alpha: isDark ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustomSort
                  ? colors.brandPrimary
                  : colors.brandPrimary.withValues(alpha: isDark ? 0.25 : 0.18),
              width: isCustomSort ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 18,
                    color: isCustomSort
                        ? colors.brandPrimary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : colors.brandPrimary),
                  ),
                  if (isCustomSort)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.active,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.surfaceBackground,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.sortBy,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCustomSort ? FontWeight.bold : FontWeight.w600,
                  color: isCustomSort
                      ? colors.brandPrimary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : colors.brandPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
