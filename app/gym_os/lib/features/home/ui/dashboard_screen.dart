import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/core/sync/sync_provider.dart';
import 'package:gym_os/core/sync/sync_status_pill.dart';
import 'package:gym_os/core/ui/animated_counter.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/ui/gym_ambient_background.dart';
import 'package:gym_os/core/ui/gym_shimmer_box.dart';
import 'package:gym_os/core/utils/app_number_format.dart';
import 'package:gym_os/features/attendance/providers/attendance_provider.dart';
import 'package:gym_os/features/attendance/services/attendance_api_service.dart';
import 'package:gym_os/features/attendance/ui/widgets/current_inside_sheet.dart';
import 'package:gym_os/features/home/providers/dashboard_provider.dart';
import 'package:gym_os/features/home/ui/widgets/drop_in_session_bottom_sheet.dart';
import 'package:gym_os/features/home/ui/widgets/weekly_activity_chart_card.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/ui/add_member_sheet.dart';
import 'package:gym_os/features/members/ui/widgets/member_avatar.dart';
import 'package:gym_os/features/members/ui/widgets/quick_search_sheet.dart';
import 'package:gym_os/features/payments/ui/renew_subscription_sheet.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../members/providers/members_provider.dart';

/// Segmented mode for Dashboard: Operations (Staff) vs Overview (Owner)
enum DashboardViewMode { operations, overview }

class DashboardScreen extends ConsumerStatefulWidget {
  final DashboardViewMode initialMode;

  const DashboardScreen({
    super.key,
    this.initialMode = DashboardViewMode.operations,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  late DashboardViewMode _viewMode;

  // Search controller for inline member search & check-in
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncLifecycleObserverProvider);
      ref.read(membersProvider.notifier).resetFilters();
    });
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (_searchQuery != text) {
        setState(() => _searchQuery = text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _viewMode = widget.initialMode;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. Open Add Member Sheet
  void _openAddMemberSheet() {
    ref.read(membersProvider.notifier).resetFilters();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceLevel1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddMemberSheet(),
    );
  }

  // 2. Open Renew Plan Sheet (with quick member selection)
  void _openRenewAction() {
    ref.read(membersProvider.notifier).resetFilters();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceLevel1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => QuickSearchSheet(
        title: context.l10n.renewPlan,
        onMemberSelected: (member) {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: context.gymColors.surfaceLevel1,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => RenewSubscriptionSheet(member: member),
          );
        },
      ),
    );
  }

  // 2b. Open Drop-in Session Sheet
  void _openDropInSessionSheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceLevel1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const DropInSessionBottomSheet(),
    ).then((result) {
      if (result == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.dropInSuccess),
              backgroundColor: context.gymColors.active,
            ),
          );
        }
      }
    });
  }

  // 3. Open Check-in Action Sheet
  void _openCheckInAction() {
    ref.read(membersProvider.notifier).resetFilters();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceLevel1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => QuickSearchSheet(
        title: context.l10n.quickCheckIn,
        onMemberSelected: (member) async {
          Navigator.pop(context);
          await _performDirectCheckIn(member);
        },
      ),
    );
  }

  // 4. Perform direct check-in for a member
  Future<void> _performDirectCheckIn(MemberModel member) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.checkingIn),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final message = await ref.read(attendanceApiProvider).checkIn(member.id);
      HapticFeedback.lightImpact();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.gymColors.active,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: context.gymColors.expired,
        ),
      );
    }
  }

  // 5. Open Current Inside Sheet
  void _openCurrentInsideSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceLevel1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CurrentInsideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.gymColors;
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: GymAmbientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: colors.brandPrimary,
            onRefresh: () async {
              final isArabic =
                  Localizations.localeOf(context).languageCode == 'ar';
              final messenger = ScaffoldMessenger.of(context);
              final syncEngine = ref.read(syncEngineProvider);
              final isOnline = await syncEngine.checkReachability();

              if (!isOnline) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'أنت غير متصل بالإنترنت — يتم عرض البيانات المحفوظة'
                            : "You're offline — showing cached data",
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                return;
              }

              try {
                await syncEngine.syncAll();
              } catch (_) {}
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Slim Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    child: _DashboardHeader(
                      mode: _viewMode,
                      onNotificationTap: () {
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ),

                // 2. Render View based on selected mode
                if (_viewMode == DashboardViewMode.operations)
                  ..._buildOperationsSlivers(colors, statsAsync)
                else
                  ..._buildOverviewSlivers(colors, statsAsync),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Operations View Slivers
  // ==========================================
  List<Widget> _buildOperationsSlivers(
    GymColorsExtension colors,
    AsyncValue<DashboardStatsModel> statsAsync,
  ) {
    final membersState = ref.watch(membersProvider);

    return [
      // 1. Inline Search Field
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: _InlineSearchBar(
            controller: _searchController,
            query: _searchQuery,
            onClear: () {
              _searchController.clear();
            },
          ),
        ),
      ),

      // 2. Inline Search Results (if user entered text)
      if (_searchQuery.isNotEmpty) ...[
        _buildInlineSearchResults(membersState, colors),
      ] else ...[
        // 3. Large Primary "Check in" + Secondary Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: _PrimaryCheckInCard(
              onCheckInTap: _openCheckInAction,
              onNewMemberTap: _openAddMemberSheet,
              onRenewTap: _openRenewAction,
              onDropInTap: _openDropInSessionSheet,
            ),
          ),
        ),

        // 4. Slim Currently in Gym Strip
        statsAsync.when(
          data: (stats) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: _SlimPresenceStrip(
                stats: stats,
                onTap: _openCurrentInsideSheet,
              ),
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: GymShimmerBox(
                height: 52,
                width: double.infinity,
                borderRadius: 16,
              ),
            ),
          ),
          error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        // 5. Recent List: "Latest Members"
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.latestMembers,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/members'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 36),
                  ),
                  child: Text(
                    context.l10n.viewAll,
                    style: TextStyle(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        _buildLatestMembersList(membersState, colors),
      ],
    ];
  }

  // ==========================================
  // Overview View Slivers (Owner Read-Only)
  // ==========================================
  List<Widget> _buildOverviewSlivers(
    GymColorsExtension colors,
    AsyncValue<DashboardStatsModel> statsAsync,
  ) {
    return [
      // 1. Slim Presence Strip
      statsAsync.when(
        data: (stats) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: _SlimPresenceStrip(
              stats: stats,
              onTap: _openCurrentInsideSheet,
            ),
          ),
        ),
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: GymShimmerBox(
              height: 52,
              width: double.infinity,
              borderRadius: 16,
            ),
          ),
        ),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),

      // 2. Revenue Card (Monthly Revenue)
      statsAsync.when(
        data: (stats) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: _OverviewRevenueCard(
              monthlyRevenue: stats.monthlyRevenue,
              monthlyDropInRevenue: stats.monthlyDropInRevenue,
              onTap: () => context.push('/payments'),
            ),
          ),
        ),
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: GymShimmerBox(
              height: 80,
              width: double.infinity,
              borderRadius: 16,
            ),
          ),
        ),
        error: (err, _) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.l10n.errorLoadingStats(err.toString()),
              style: TextStyle(color: colors.expired),
            ),
          ),
        ),
      ),

      // 3. Compact KPI Stat Cards Grid (reduced to ~half height)
      statsAsync.when(
        data: (stats) => SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.2, // Compact ~72dp high
            children: [
              _CompactStatCard(
                title: context.l10n.activeMembers,
                numericValue: stats.activeMembersCount,
                icon: Icons.people_outline_rounded,
                accentColor: colors.brandPrimary,
                onTap: () => context.push('/members?filter=active'),
              ),
              _CompactStatCard(
                title: context.l10n.todayCheckIns,
                numericValue: stats.todayCheckInsCount,
                icon: Icons
                    .event_available_outlined, // Outlined calendar-check icon
                accentColor: colors.brandPrimary,
                onTap: () => context.push('/members?filter=today'),
              ),
              _CompactStatCard(
                title: context.l10n.expiredSubscriptions,
                numericValue: stats.expiredSubscriptionsCount,
                icon: Icons.exit_to_app_rounded,
                accentColor: colors.expired,
                onTap: () => context.push('/members?filter=expired'),
              ),
              _CompactStatCard(
                title: context.l10n.todayRevenue,
                numericValue: stats.todayRevenue,
                icon: Icons.payments_outlined,
                accentColor: colors.brandPrimary,
                suffix: ' ${context.l10n.currency}',
                onTap: () => context.push('/payments'),
              ),
            ],
          ),
        ),
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _StatsSkeleton(),
          ),
        ),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),

      // 4. Last 7 Days Activity Chart Card (Attendance & Revenue)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: WeeklyActivityChartCard(),
        ),
      ),
    ];
  }

  // ==========================================
  // Inline Search Results List
  // ==========================================
  Widget _buildInlineSearchResults(
    MembersState membersState,
    GymColorsExtension colors,
  ) {
    final query = _searchQuery.toLowerCase();
    final matches = membersState.members.where((m) {
      return m.fullName.toLowerCase().contains(query) ||
          m.phoneNumber.contains(query);
    }).toList();

    if (matches.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Text(
              context.l10n.noMembersFound,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final member = matches[index];
        final isActive = member.subscriptionStatus.toLowerCase() == 'active';

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          child: GymCard(
            elevationLevel: 1,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Avatar at START side, fixed size 40dp
                MemberAvatar(
                  photoUrl: member.photoUrl,
                  fullName: member.fullName,
                  radius: 20,
                  fontSize: 16,
                ),
                const SizedBox(width: AppSpacing.sm),

                // 2. Name & Phone & Subscription Badge UNDER name in one column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        member.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.phoneNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Badge sits UNDER name & phone
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isActive ? colors.active : colors.expired)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive
                              ? context.l10n.activeStatus
                              : context.l10n.expiredStatus,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? colors.active : colors.expired,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // 3. "Check in" button at the END side, min height 48dp, does not shrink
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _performDirectCheckIn(member),
                    icon: const Icon(
                      Icons.event_available_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      context.l10n.checkInMember,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      minimumSize: const Size(80, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: matches.length),
    );
  }

  // ==========================================
  // Latest Members List
  // ==========================================
  Widget _buildLatestMembersList(
    MembersState membersState,
    GymColorsExtension colors,
  ) {
    if (membersState.isLoading && membersState.members.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (membersState.members.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Text(
              context.l10n.noMembersYet,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

    final latest = membersState.members.take(4).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final member = latest[index];
        final isActive = member.subscriptionStatus.toLowerCase() == 'active';

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          child: GymCard(
            elevationLevel: 1,
            onTap: () => context.pushNamed('memberProfile', extra: member),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                MemberAvatar(
                  photoUrl: member.photoUrl,
                  fullName: member.fullName,
                  radius: 20,
                  fontSize: 16,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            member.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive ? colors.active : colors.expired)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive
                                  ? context.l10n.activeStatus
                                  : context.l10n.expiredStatus,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? colors.active
                                    : colors.expired,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_back_ios_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        );
      }, childCount: latest.length),
    );
  }
}

// ==========================================
// Sub-Widgets for Home Screen
// ==========================================

/// Slim Header displaying greeting and notification bell
class _DashboardHeader extends StatelessWidget {
  final DashboardViewMode mode;
  final VoidCallback onNotificationTap;

  const _DashboardHeader({required this.mode, required this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final title = mode == DashboardViewMode.operations
        ? context.l10n.quickOperations
        : context.l10n.gymOverview;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.brandPrimary.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.brandPrimary.withValues(alpha: 0.07),
                    blurRadius: isLight ? 12 : 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Transform.flip(
                  flipX: isRtl,
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.cover,
                    color: !isLight
                        ? Color.lerp(Colors.white, colors.brandPrimary, 0.12)!
                        : null,
                    colorBlendMode: !isLight ? BlendMode.dstATop : null,
                    semanticLabel: context.l10n.appLogoSemanticLabel,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.goodMorningCaptain,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.brandPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Sync Status Pill + Notification bell with >= 48dp tap target
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [const SyncStatusPill()],
        ),
      ],
    );
  }
}

/// Inline search field for finding members and checking in
class _InlineSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final VoidCallback onClear;

  const _InlineSearchBar({
    required this.controller,
    required this.query,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    const radius = AppSpacing.borderRadiusMd;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: radius,
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14, color: colors.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surfaceLevel1,
          hintText: context.l10n.searchByNameOrPhone,
          hintStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.textSecondary,
            size: 20,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear,
                  color: colors.textSecondary,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

/// Large primary check-in card with secondary quick actions
class _PrimaryCheckInCard extends StatelessWidget {
  final VoidCallback onCheckInTap;
  final VoidCallback onNewMemberTap;
  final VoidCallback onRenewTap;
  final VoidCallback onDropInTap;

  const _PrimaryCheckInCard({
    required this.onCheckInTap,
    required this.onNewMemberTap,
    required this.onRenewTap,
    required this.onDropInTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;

    return Column(
      children: [
        // Large Primary Check-in Action
        Material(
          color: colors.brandPrimary,
          borderRadius: AppSpacing.borderRadiusMd,
          child: InkWell(
            onTap: onCheckInTap,
            borderRadius: AppSpacing.borderRadiusMd,
            child: Container(
              constraints: const BoxConstraints(minHeight: 66),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.l10n.quickCheckIn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Secondary actions: New Member, Renew Plan, Drop-in Session
        Row(
          children: [
            const SizedBox(height: AppSpacing.xl),

            Expanded(
              child: _SecondaryActionButton(
                icon: Icons.person_add_alt_1_outlined,
                label: context.l10n.newMember,
                onTap: onNewMemberTap,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _SecondaryActionButton(
                icon: Icons.payment_outlined,
                label: context.l10n.renewPlan,
                onTap: onRenewTap,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _SecondaryActionButton(
                icon: Icons.flash_on_outlined,
                label: context.l10n.dropInSession,
                onTap: onDropInTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;

    return GymCard(
      elevationLevel: 1,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 12,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colors.brandPrimary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim Live Presence Strip (no neon glow, subtle pulse)
class _SlimPresenceStrip extends ConsumerWidget {
  final DashboardStatsModel stats;
  final VoidCallback onTap;

  const _SlimPresenceStrip({required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.gymColors;
    final currentInsideAsync = ref.watch(currentInsideProvider);
    final liveCount =
        currentInsideAsync.value?.length ?? stats.currentInsideCount;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final dotWidget = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: colors.active, shape: BoxShape.circle),
    );

    final breathingDot = disableAnimations
        ? dotWidget
        : dotWidget
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.3, 1.3),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              );

    return GymCard(
      elevationLevel: 1,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          // Subtle breathing green dot
          RepaintBoundary(child: breathingDot),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.currentlyInGym,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedCounter(
                value: liveCount,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.active,
                ),
              ),
              // const SizedBox(width: 4),
              // Text(
              //   context.l10n.memberUnit,
              //   style: TextStyle(
              //     fontSize: 11,
              //     color: colors.textSecondary,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_ios_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 11,
                color: colors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Overview Revenue Card
class _OverviewRevenueCard extends StatelessWidget {
  final double monthlyRevenue;
  final double monthlyDropInRevenue;
  final VoidCallback onTap;

  const _OverviewRevenueCard({
    required this.monthlyRevenue,
    this.monthlyDropInRevenue = 0.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;

    return GymCard(
      elevationLevel: 1,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: colors.brandPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.revenueSummary,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.monthlyRevenue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedCounter(
                value: monthlyRevenue,
                suffix: ' ${context.l10n.currency}',
                fractionDigits: 0,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          if (monthlyDropInRevenue > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceLevel2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flash_on_rounded,
                        size: 13,
                        color: colors.brandPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        context.l10n.includesDropIns(
                          AppNumberFormat.formatWithCurrency(
                            monthlyDropInRevenue,
                            locale: Localizations.localeOf(context).toString(),
                            currencySuffix: context.l10n.currency,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact KPI Stat Card (approx half height, ~72dp high)
class _CompactStatCard extends StatefulWidget {
  final String title;
  final num numericValue;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final String? suffix;

  const _CompactStatCard({
    required this.title,
    required this.numericValue,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.suffix,
  });

  @override
  State<_CompactStatCard> createState() => _CompactStatCardState();
}

class _CompactStatCardState extends State<_CompactStatCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceLevel1,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(color: colors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(widget.icon, size: 16, color: widget.accentColor),
                ],
              ),
              AnimatedCounter(
                value: widget.numericValue,
                suffix: widget.suffix ?? '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for compact stats grid
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: GymShimmerBox(height: 72, borderRadius: 12)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: GymShimmerBox(height: 72, borderRadius: 12)),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: GymShimmerBox(height: 72, borderRadius: 12)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}
