import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/theme/app_spacing.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_text_field.dart';
import '../../providers/plans_provider.dart';

class UpsertPlanSheet extends ConsumerStatefulWidget {
  final PlanModel? plan;

  const UpsertPlanSheet({super.key, this.plan});

  @override
  ConsumerState<UpsertPlanSheet> createState() => _UpsertPlanSheetState();
}

class _UpsertPlanSheetState extends ConsumerState<UpsertPlanSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late bool _isActive;
  bool _isSubmitting = false;

  final List<int> _commonDurations = const [30, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toInt().toString() : '',
    );
    _durationController = TextEditingController(
      text: p != null ? p.durationInDays.toString() : '30',
    );
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    try {
      await ref
          .read(plansApiServiceProvider)
          .upsertPlan(
            id: widget.plan?.id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            price: price,
            durationInDays: duration,
            isActive: _isActive,
          );

      // Invalidate providers
      ref.invalidate(allPlansProvider);
      ref.invalidate(activePlansProvider);
      ref.invalidate(plansProvider);

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.planSavedSuccess),
          backgroundColor: context.gymColors.active,
          behavior: SnackBarBehavior.floating,
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getDurationChipLabel(int days, BuildContext context) {
    switch (days) {
      case 30:
        return context.l10n.days30;
      case 90:
        return context.l10n.days90;
      case 180:
        return context.l10n.days180;
      case 365:
        return context.l10n.days365;
      default:
        return context.l10n.durationDays(days);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.plan != null;

    return Container(
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.brandPrimary.withValues(alpha: 0.1),
                    child: Icon(
                      isEdit
                          ? Icons.edit_note_rounded
                          : Icons.card_membership_rounded,
                      color: colors.brandPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isEdit ? context.l10n.editPlan : context.l10n.addPlan,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.brandPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Active toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isActive
                            ? context.l10n.activePlan
                            : context.l10n.inactivePlan,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isActive ? colors.active : colors.expired,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch.adaptive(
                        value: _isActive,
                        activeTrackColor: colors.active,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _isActive = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 1. Plan Name
              GymTextField(
                controller: _nameController,
                label: context.l10n.planName,
                hint: context.l10n.planNameHint,
                prefixIcon: Icons.badge_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.planNameRequired
                    : null,
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Price
              GymTextField(
                controller: _priceController,
                label: context.l10n.planPrice(context.l10n.currency),
                hint: '0',
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return context.l10n.planPriceRequired;
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) {
                    return context.l10n.planPriceRequired;
                  }
                  return null;
                },
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Duration in Days
              GymTextField(
                controller: _durationController,
                label: context.l10n.durationInDays,
                hint: '30',
                prefixIcon: Icons.calendar_month_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return context.l10n.durationRequired;
                  }
                  final parsed = int.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return context.l10n.durationRequired;
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Quick-Pick Duration Chips
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _commonDurations.map((days) {
                  final isSelected =
                      _durationController.text.trim() == days.toString();
                  return ChoiceChip(
                    label: Text(
                      _getDurationChipLabel(days, context),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colors.brandPrimary,
                    backgroundColor: colors.brandPrimary.withValues(
                      alpha: isDark ? 0.12 : 0.05,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? colors.brandPrimary
                            : colors.brandPrimary.withValues(alpha: 0.15),
                      ),
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _durationController.text = days.toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Description (Optional)
              GymTextField(
                controller: _descriptionController,
                label: context.l10n.planDescriptionOptional,
                hint: context.l10n.planDescriptionHint,
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),

              // 5. Submit Button
              GymButton(
                label: context.l10n.savePlan,
                icon: Icons.check_circle_rounded,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
