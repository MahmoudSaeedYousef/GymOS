import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/atoms/gym_button.dart';
import '../../models/member_model.dart';
import '../../providers/members_provider.dart';
import '../../services/gym_api_service.dart';

class EditMemberSheet extends ConsumerStatefulWidget {
  final MemberModel member;

  const EditMemberSheet({super.key, required this.member});

  @override
  ConsumerState<EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends ConsumerState<EditMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late int _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.fullName);
    _phoneController = TextEditingController(text: widget.member.phoneNumber);
    _selectedGender = widget.member.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();

    setState(() => _isLoading = true);

    try {
      final updated = await ref
          .read(gymApiServiceProvider)
          .updateMember(
            widget.member.id,
            fullName: fullName,
            phoneNumber: phoneNumber,
            gender: _selectedGender,
          );

      if (!mounted) return;

      ref.invalidate(membersProvider);
      ref.invalidate(membersSummaryProvider);

      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: context.gymColors.expired,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'تعديل بيانات المشترك',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'الاسم الكامل',
                style: TextStyle(
                  color: colors.textHighlight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.brandPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.brandPrimary,
                      width: 2,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'الرجاء إدخال اسم المشترك';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'رقم الهاتف',
                style: TextStyle(
                  color: colors.textHighlight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.brandPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.brandPrimary,
                      width: 2,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'الرجاء إدخال رقم الهاتف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.gender,
                style: TextStyle(
                  color: colors.textHighlight,
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
                selected: _selectedGender == 0
                    ? <int>{}
                    : <int>{_selectedGender},
                emptySelectionAllowed: true,
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _selectedGender = newSelection.isEmpty
                        ? 0
                        : newSelection.first;
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
              const SizedBox(height: AppSpacing.xl),
              GymButton(
                label: 'حفظ التعديلات',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleSave,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
