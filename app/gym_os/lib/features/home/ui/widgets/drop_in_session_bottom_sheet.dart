import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../payments/services/payment_api_service.dart';
import '../../../plans/providers/plans_provider.dart';
import '../../models/drop_in_visit_models.dart';
import '../../services/dashboard_api_service.dart';

/// Modal bottom sheet for recording a single drop-in session visit.
class DropInSessionBottomSheet extends ConsumerStatefulWidget {
  const DropInSessionBottomSheet({super.key});

  @override
  ConsumerState<DropInSessionBottomSheet> createState() =>
      _DropInSessionBottomSheetState();
}

class _DropInSessionBottomSheetState
    extends ConsumerState<DropInSessionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  late final String _operationId;
  String? _planId;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Unique operation ID for idempotency; preserved across retries in this sheet
    _operationId = UuidGenerator.v4();

    double initialAmount = 50.0;
    final plans = ref.read(plansProvider).asData?.value;
    if (plans != null && plans.isNotEmpty) {
      final singleVisitPlan = plans
          .where((p) =>
              p.isActive &&
              (p.durationInDays == 1 ||
                  p.maxSessions == 1 ||
                  p.name.contains('مفردة') ||
                  p.name.toLowerCase().contains('drop')))
          .firstOrNull;

      if (singleVisitPlan != null) {
        initialAmount = singleVisitPlan.price;
        _planId = singleVisitPlan.id;
      }
    }

    final formattedAmount = initialAmount.truncateToDouble() == initialAmount
        ? initialAmount.toInt().toString()
        : initialAmount.toStringAsFixed(2);

    _amountController = TextEditingController(text: formattedAmount);
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = context.l10n.amountRequired;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final request = RecordDropInRequest(
      operationId: _operationId,
      planId: _planId,
      customAmount: amount,
      method: _selectedPaymentMethod.value,
      guestName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      guestPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      final result = await ref
          .read(dashboardApiServiceProvider)
          .recordDropInVisit(request);

      if (!mounted) return;

      if (result.succeeded) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result.message.isNotEmpty
              ? result.message
              : context.l10n.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceBorder.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet Header: Icon, Title & Close Button
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.brandPrimary.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Icon(
                        Icons.flash_on_rounded,
                        color: colors.brandPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.dropInSessionTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Error message banner (if any)
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.expired.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(
                        color: colors.expired.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colors.expired,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colors.expired,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Amount Field
                Text(
                  l10n.amountPaid(l10n.currency),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      color: colors.brandPrimary,
                      size: 20,
                    ),
                    suffixText: l10n.currency,
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                    hintText: '50',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim();
                    if (trimmed == null || trimmed.isEmpty) {
                      return l10n.amountRequired;
                    }
                    final numVal = double.tryParse(trimmed);
                    if (numVal == null || numVal <= 0) {
                      return l10n.amountRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Payment Method Selector
                Text(
                  l10n.paymentMethod,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildPaymentMethodSelector(colors, l10n),
                const SizedBox(height: AppSpacing.md),

                // Guest Details Header
                Text(
                  l10n.guestNameOptional,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    hintText: l10n.guestNameOptional,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Guest Phone Field
                Text(
                  l10n.guestPhoneOptional,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    hintText: '01xxxxxxxxx',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Notes Field
                Text(
                  l10n.dropInNotesOptional,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _notesController,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    hintText: l10n.dropInNotesOptional,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Submit Action Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                l10n.recordAndCheckIn,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
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
      children: methods.map((method) {
        final isSelected = _selectedPaymentMethod == method;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedPaymentMethod = method;
            });
          },
          borderRadius: AppSpacing.borderRadiusSm,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.brandPrimary.withValues(alpha: 0.12)
                  : colors.surfaceLevel2,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                color: isSelected ? colors.brandPrimary : colors.surfaceBorder,
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
                      isSelected ? colors.brandPrimary : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  method.localizedLabel(l10n),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
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
