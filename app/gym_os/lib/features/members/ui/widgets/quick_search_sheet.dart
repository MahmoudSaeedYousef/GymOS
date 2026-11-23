import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/ui/atoms/gym_text_field.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/members/ui/widgets/member_avatar.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

class QuickSearchSheet extends ConsumerStatefulWidget {
  final String title;
  final ValueChanged<MemberModel> onMemberSelected;

  const QuickSearchSheet({
    super.key,
    required this.title,
    required this.onMemberSelected,
  });

  @override
  ConsumerState<QuickSearchSheet> createState() => _QuickSearchSheetState();
}

class _QuickSearchSheetState extends ConsumerState<QuickSearchSheet> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Reset filters so the quick search starts with all members
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(membersProvider.notifier).resetFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;

    // جلب المشتركين من الذاكرة لسرعة البحث اللحظي
    final allMembers = ref.watch(membersProvider).members;

    // فلترة بناءً على البحث أو عرض أول 10 لو مفيش بحث
    final filteredMembers = _query.isEmpty
        ? allMembers.take(10).toList()
        : allMembers
              .where(
                (m) =>
                    m.fullName.toLowerCase().contains(_query.toLowerCase()) ||
                    m.phoneNumber.contains(_query),
              )
              .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.brandPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GymTextField(
            label: context.l10n.searchForMember,
            hint: context.l10n.nameOrPhoneHint,
            prefixIcon: Icons.search_rounded,
            onChanged: (val) => setState(() => _query = val),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filteredMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                context.l10n.noMembersMatched,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filteredMembers.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              member.subscriptionStatus.toLowerCase() ==
                                  MemberSubscriptionStatus.active.name
                                      .toLowerCase()
                              ? const Color.fromARGB(255, 9, 137, 75)
                              : member.subscriptionStatus.toLowerCase() ==
                                    MemberSubscriptionStatus.expiringSoon.name
                                        .toLowerCase()
                              ? context.gymColors.warning
                              : context.gymColors.expired,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: MemberAvatar(
                        photoUrl: member.photoUrl,
                        fullName: member.fullName,
                        gender: member.gender,
                        radius: 20,
                        fontSize: 16,
                      ),
                    ),
                    // MemberAvatar(
                    //   photoUrl: member.photoUrl,
                    //   fullName: member.fullName,
                    //   gender: member.gender,
                    //   radius: 20,
                    //   fontSize: 16,
                    // ),
                    title: Text(
                      member.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      member.phoneNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    trailing: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_back_ios_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                    onTap: () => widget.onMemberSelected(member),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
