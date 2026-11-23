import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_text_field.dart';
import 'package:gym_os/features/payments/services/payment_api_service.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/plan_model.dart';
import '../providers/members_provider.dart';

class AddMemberSheet extends ConsumerStatefulWidget {
  const AddMemberSheet({super.key});

  @override
  ConsumerState<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedPlanId;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  int _selectedGender = 0; // 0 = unspecified, 1 = male, 2 = female
  bool _isSubmitting = false;

  bool get _isDirty {
    return _nameController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _amountController.text.trim().isNotEmpty ||
        _selectedPlanId != null ||
        _selectedGender != 0;
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_isDirty) return true;

    final l10n = context.l10n;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 32,
          ),
          title: Text(l10n.discardChangesTitle),
          content: Text(l10n.discardChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.keepEditing),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10n.discard),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final planChosen = _selectedPlanId != null;
    final amount =
        planChosen ? double.tryParse(_amountController.text.trim()) : null;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(membersProvider.notifier)
          .addMember(
            fullName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            planId: _selectedPlanId,
            method: planChosen ? _selectedPaymentMethod.value : null,
            amountPaid: amount,
            gender: _selectedGender,
          );
      ref.read(membersProvider.notifier).resetFilters();
      ref.invalidate(membersSummaryProvider);
      if (mounted) {
        final colors = context.gymColors;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.memberAddedSuccess),
            backgroundColor: colors.active,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final colors = context.gymColors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.errorWithMessage(
                e.toString().replaceAll('Exception: ', ''),
              ),
            ),
            backgroundColor: colors.expired,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscardIfNeeded();
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        end: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          colors.brandPrimary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        color: colors.brandPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.addNewMemberTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.brandPrimary,
                          ),
                        ),
                        Text(
                          context.l10n.enterMemberDataHint,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                GymTextField(
                  controller: _nameController,
                  label: context.l10n.fullName,
                  hint: context.l10n.fullNameHint,
                  prefixIcon: Icons.person_outline_rounded,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? context.l10n.nameRequired
                              : null,
                ),
                const SizedBox(height: AppSpacing.md),
                GymTextField(
                  controller: _phoneController,
                  label: context.l10n.phoneNumber,
                  hint: '01X XXXX XXXX',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator:
                      (v) =>
                          (v == null || v.trim().length < 10)
                              ? context.l10n.phoneInvalid
                              : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Gender Selector (ذكر / أنثى)
                Text(
                  context.l10n.gender,
                  style: TextStyle(
                    color: textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment<int>(
                      value: 1,
                      label: Text(context.l10n.genderMale),
                      icon: const Icon(Icons.male_rounded, size: 18),
                    ),
                    ButtonSegment<int>(
                      value: 2,
                      label: Text(context.l10n.genderFemale),
                      icon: const Icon(Icons.female_rounded, size: 18),
                    ),
                  ],
                  selected: _selectedGender == 0 ? <int>{} : <int>{_selectedGender},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedGender = newSelection.isEmpty ? 0 : newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Styled Dropdown
                Text(
                  context.l10n.planOptional,
                  style: TextStyle(
                    color: textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                plansAsync.when(
                  data:
                      (plans) => DropdownButtonFormField<String>(
                        initialValue: _selectedPlanId,
                        dropdownColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color:
                              isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                        ),
                        decoration: InputDecoration(
                          hintText: context.l10n.chooseImmediatePlan,
                          prefixIcon: const Icon(Icons.card_membership_rounded),
                        ),
                        items:
                            plans
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      '${p.name} - ${p.price.toInt()} ${context.l10n.currency}',
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedPlanId = val;
                            if (val != null) {
                              final selectedPlan = plans
                                  .cast<PlanModel?>()
                                  .firstWhere(
                                    (p) => p?.id == val,
                                    orElse: () => null,
                                  );
                              if (selectedPlan != null) {
                                final price = selectedPlan.price;
                                _amountController.text =
                                    (price.truncateToDouble() == price)
                                        ? price.toInt().toString()
                                        : price.toString();
                              }
                            } else {
                              _amountController.clear();
                            }
                          });
                        },
                      ),
                  loading:
                      () => LinearProgressIndicator(
                        color: colors.brandPrimary,
                        backgroundColor:
                            colors.brandPrimary.withValues(alpha: 0.1),
                      ),
                  error:
                      (_, _) => Text(
                        context.l10n.failedToLoadPlans,
                        style: TextStyle(color: colors.expired),
                      ),
                ),

                if (_selectedPlanId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  // Payment Method Selector
                  Text(
                    context.l10n.paymentMethod,
                    style: TextStyle(
                      color: textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildPaymentMethodSelector(colors, context.l10n),
                  const SizedBox(height: AppSpacing.md),

                  // Amount Paid Field
                  GymTextField(
                    controller: _amountController,
                    label: context.l10n.amountPaid(context.l10n.currency),
                    hint: '0',
                    prefixIcon: Icons.payments_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (_selectedPlanId == null) return null;
                      final trimmed = v?.trim();
                      if (trimmed == null || trimmed.isEmpty) {
                        return context.l10n.pleaseEnterValidAmount;
                      }
                      final numVal = double.tryParse(trimmed);
                      if (numVal == null || numVal <= 0) {
                        return context.l10n.pleaseEnterValidAmount;
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                GymButton(
                  label: context.l10n.saveAndActivate,
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildPaymentMethodSelector(
    GymColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final methods = [
      PaymentMethod.cash,
      PaymentMethod.instaPay,
      PaymentMethod.vodafoneCash,
      PaymentMethod.visa,
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children:
          methods.map((method) {
            final isSelected = _selectedPaymentMethod == method;
            return InkWell(
              key: Key('payment_method_${method.name}'),
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
              borderRadius: AppSpacing.borderRadiusSm,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? colors.brandPrimary.withValues(alpha: 0.12)
                          : colors.surfaceLevel2,
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color:
                        isSelected
                            ? colors.brandPrimary
                            : colors.surfaceBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 16,
                      color:
                          isSelected
                              ? colors.brandPrimary
                              : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      method.localizedLabel(l10n),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected
                                ? colors.brandPrimary
                                : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
