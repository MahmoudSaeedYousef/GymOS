import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/theme/app_spacing.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/ui/gym_shimmer_box.dart';
import 'package:gym_os/features/attendance/models/current_inside_member_model.dart';
import 'package:gym_os/features/attendance/providers/attendance_provider.dart';
import 'package:gym_os/features/attendance/services/attendance_api_service.dart';
import 'package:gym_os/features/members/ui/widgets/member_avatar.dart';

class CurrentInsideSheet extends ConsumerStatefulWidget {
  const CurrentInsideSheet({super.key});

  @override
  ConsumerState<CurrentInsideSheet> createState() => _CurrentInsideSheetState();
}

class _CurrentInsideSheetState extends ConsumerState<CurrentInsideSheet> {
  final Set<String> _loadingRecordIds = {};

  Future<void> _handleCheckOut(CurrentInsideMemberModel member) async {
    setState(() => _loadingRecordIds.add(member.recordId));
    HapticFeedback.lightImpact();

    try {
      final message = await ref
          .read(attendanceApiProvider)
          .checkOut(member.recordId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: context.gymColors.active,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: context.gymColors.expired,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingRecordIds.remove(member.recordId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentInsideAsync = ref.watch(currentInsideProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.active.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sensors_rounded,
                  color: colors.active,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.currentInsideTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : colors.brandPrimary,
                ),
              ),
              const Spacer(),
              currentInsideAsync.maybeWhen(
                data: (members) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.active.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.active.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    context.l10n.memberCountBadge(members.length),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.active,
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Content List
          Flexible(
            child: currentInsideAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl * 1.5,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colors.brandPrimary.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.group_off_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.l10n.noMembersInside,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.realtimeGateUpdate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isCheckingOut = _loadingRecordIds.contains(
                      member.recordId,
                    );

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colors.surfaceBackground
                            : colors.brandPrimary.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      child: Row(
                        children: [
                          MemberAvatar(
                            photoUrl: member.photoUrl,
                            fullName: member.fullName,
                            radius: 20,
                            backgroundColor:
                                colors.brandPrimary.withValues(alpha: 0.1),
                            foregroundColor: colors.brandPrimary,
                            fontSize: 16,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.sm + 2),
                          child: Row(
                            children: [
                              // CircleAvatar(
                              //   radius: 20,
                              //   backgroundColor:
                              //       colors.brandPrimary.withValues(alpha: 0.1),
                              //   child: Text(
                              //     member.fullName.isNotEmpty
                              //         ? member.fullName[0]
                              //         : '?',
                              //     style: TextStyle(
                              //       color: colors.brandPrimary,
                              //       fontWeight: FontWeight.bold,
                              //       fontSize: 16,
                              //     ),
                              //   ),
                              // ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Transform.flip(
                                  flipX: isRtl,
                                  child: Image.asset(
                                    'assets/icons/app_icon.png',
                                    fit: BoxFit.cover,
                                    color: !isLight
                                        ? Color.lerp(
                                            Colors.white,
                                            colors.brandPrimary,
                                            0.12,
                                          )!
                                        : null,
                                    colorBlendMode: !isLight
                                        ? BlendMode.dstATop
                                        : null,
                                    semanticLabel:
                                        context.l10n.appLogoSemanticLabel,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm + 2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 13,
                                          color: colors.active,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          member.localizedElapsedTime(
                                            context.l10n,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colors.active,
                                          ),
                                        ),
                                        if (member.phoneNumber.isNotEmpty) ...[
                                          Text(
                                            ' • ',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            member.phoneNumber,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // Compact check-out button with subtle expired tint
                              InkWell(
                                onTap: isCheckingOut
                                    ? null
                                    : () => _handleCheckOut(member),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.expired.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colors.expired.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: isCheckingOut
                                      ? SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colors.expired,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.logout_rounded,
                                              size: 14,
                                              color: colors.expired,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              context.l10n.checkOut,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: colors.expired,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (index * 40).ms, duration: 250.ms)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                  },
                );
              },
              loading: () => Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  4,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: GymShimmerBox(height: 56, borderRadius: 14),
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                      onPressed: () => ref.invalidate(currentInsideProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
