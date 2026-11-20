import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_text_field.dart';
import 'package:gym_os/features/home/providers/dashboard_provider.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../members/models/member_model.dart';
import '../services/payment_api_service.dart';

class RenewSubscriptionSheet extends ConsumerStatefulWidget {
  final MemberModel member;

  const RenewSubscriptionSheet({super.key, required this.member});

  @override
  ConsumerState<RenewSubscriptionSheet> createState() =>
      _RenewSubscriptionSheetState();
}

class _RenewSubscriptionSheetState
    extends ConsumerState<RenewSubscriptionSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedPlanId;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectPlan),
          backgroundColor: context.gymColors.expired,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterValidAmount),
          backgroundColor: context.gymColors.expired,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final message = await ref
          .read(paymentApiProvider)
          .renewSubscription(
            memberId: widget.member.id,
            planId: _selectedPlanId!,
            paymentMethod: _selectedPaymentMethod.value,
            amountPaid: amount,
            notes: _notesController.text.trim(),
          );

      ref.invalidate(dashboardStatsProvider);
      if (!mounted) return;
      Navigator.pop(context, true); // نقفل الشيت ونبعت true عشان نحدث الشاشة
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final plansAsync = ref.watch(plansProvider); // جلب الباقات

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              context.l10n.renewSubscriptionFor(widget.member.fullName),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.brandPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 1. اختيار الباقة
            Text(
              context.l10n.plan,
              style: TextStyle(
                color: colors.brandPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            plansAsync.when(
              data: (plans) => DropdownButtonFormField<String>(
                initialValue: _selectedPlanId,
                decoration: InputDecoration(
                  hintText: context.l10n.selectPlanToRenew,
                  prefixIcon: const Icon(Icons.card_membership_rounded),
                  filled: true,
                ),
                items: plans
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} - ${p.price.toInt()} ${context.l10n.currency}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPlanId = val;
                    // أول ما يختار الباقة، نكتب سعرها أوتوماتيك في حقل المبلغ عشان نسهل على الكابتن
                    final selectedPlan = plans.firstWhere((p) => p.id == val);
                    _amountController.text = selectedPlan.price
                        .toInt()
                        .toString();
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(
                context.l10n.failedToLoadPlans,
                style: TextStyle(color: context.gymColors.expired),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. طريقة الدفع (كاش، إنستاباي، ...)
            Text(
              context.l10n.paymentMethod,
              style: TextStyle(
                color: colors.brandPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _selectedPaymentMethod,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                filled: true,
              ),
              items: PaymentMethod.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.localizedLabel(context.l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. المبلغ والملاحظات
            GymTextField(
              controller: _amountController,
              label: context.l10n.amountPaid(context.l10n.currency),
              hint: '0',
              prefixIcon: Icons.payments_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            GymTextField(
              controller: _notesController,
              label: context.l10n.notesOptional,
              hint: context.l10n.notesHint,
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: AppSpacing.xl),

            // 4. زرار التأكيد
            GymButton(
              label: context.l10n.confirmPaymentAndRenew,
              icon: Icons.check_circle_rounded,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
