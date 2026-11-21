import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/utils/whatsapp_helper.dart';
import 'package:intl/intl.dart';
import 'package:gym_os/features/attendance/ui/widgets/check_in_success_dialog.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/payments/ui/renew_subscription_sheet.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../attendance/services/attendance_api_service.dart';
import '../models/member_model.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  final MemberModel member;

  const MemberProfileScreen({super.key, required this.member});

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  bool _isCheckingIn = false;

  // Future<void> _handleCheckIn() async {
  //   setState(() => _isCheckingIn = true);
  //   try {
  //     final message = await ref
  //         .read(attendanceApiProvider)
  //         .checkIn(widget.member.id);

  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(message),
  //         backgroundColor: context.gymColors.active,
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.toString().replaceAll('Exception: ', '')),
  //         backgroundColor: context.gymColors.expired,
  //       ),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isCheckingIn = false);
  //   }
  // }
  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);
    try {
      final message = await ref
          .read(attendanceApiProvider)
          .checkIn(widget.member.id);

      if (!mounted) return;

      ref.read(membersProvider.notifier).resetFilters();

      // تشغيل أنيميشن تسجيل الحضور
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

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isActive =
        widget.member.subscriptionStatus.toLowerCase() == 'active';
    final statusColor = isActive ? colors.active : colors.expired;

    bool isExpiringSoon = false;
    if (widget.member.subscriptionEndDate != null) {
      final endDate = DateTime.tryParse(widget.member.subscriptionEndDate!);
      if (endDate != null) {
        final daysRemaining = endDate.difference(DateTime.now()).inDays;
        if (daysRemaining <= 3) {
          isExpiringSoon = true;
        }
      }
    }
    final shouldShowReminder = !isActive || isExpiringSoon;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.memberProfileTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // 1. الهيدر (بيانات العميل)
          GymCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colors.brandPrimary.withValues(alpha: 0.1),
                  child: Text(
                    widget.member.fullName[0],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colors.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.member.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.member.phoneNumber,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive
                        ? context.l10n.activeSubscription
                        : context.l10n.expiredSubscription,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. تفاصيل الباقة
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.subscriptionDetails,
                  style: TextStyle(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _DetailRow(
                  icon: Icons.card_membership_rounded,
                  label: context.l10n.plan,
                  value:
                      widget.member.activePlanName ?? context.l10n.noPlan,
                ),
                if (widget.member.subscriptionEndDate != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: context.l10n.endDate,
                    value: _formatProfileEndDate(widget.member.subscriptionEndDate!),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 3. الإجراءات (Actions)
          GymButton(
            label: context.l10n.recordAttendance,
            icon: Icons.fingerprint_rounded,
            isLoading: _isCheckingIn,
            onPressed: isActive
                ? _handleCheckIn
                : null, // الزر مقفول لو الاشتراك منتهي
          ),
          const SizedBox(height: AppSpacing.md),
          GymButton(
            label: context.l10n.renewSubscription,
            icon: Icons.payment_rounded,
            onPressed: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: context.gymColors.surfaceBackground,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => RenewSubscriptionSheet(member: widget.member),
              );

              if (!context.mounted) return;
              if (result == true) {
                ref.read(membersProvider.notifier).resetFilters();
                context.pop();
              }
            },
          ),
          if (shouldShowReminder) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => WhatsAppHelper.sendRenewalReminder(
                  context,
                  phoneNumber: widget.member.phoneNumber,
                  memberName: widget.member.fullName,
                ),
                icon: Icon(Icons.chat_rounded, color: colors.active, size: 20),
                label: Text(
                  context.l10n.sendWhatsappReminder,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.active,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: colors.active.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  backgroundColor: colors.active.withValues(alpha: 0.08),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadius,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

String _formatProfileEndDate(String rawDate) {
  final parsed = DateTime.tryParse(rawDate);
  if (parsed != null) {
    return DateFormat('yyyy-MM-dd').format(parsed);
  }
  if (rawDate.length >= 10) {
    return rawDate.substring(0, 10);
  }
  return rawDate;
}

