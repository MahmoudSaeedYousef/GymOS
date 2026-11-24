import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gym_os/core/theme/app_spacing.dart';
import 'package:gym_os/core/theme/app_theme.dart';

class GymTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const GymTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  @override
  State<GymTextField> createState() => _GymTextFieldState();
}

class _GymTextFieldState extends State<GymTextField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerTextChange);
  }

  @override
  void didUpdateWidget(covariant GymTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerTextChange);
      widget.controller?.addListener(_onControllerTextChange);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerTextChange);
    super.dispose();
  }

  void _onControllerTextChange() {
    final currentField = _fieldKey.currentState;
    if (currentField != null) {
      final text = widget.controller?.text ?? '';
      if (currentField.value != text) {
        currentField.didChange(text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.controller?.text ?? '',
      validator: widget.validator,
      builder: (FormFieldState<String> fieldState) {
        final hasError = fieldState.hasError;
        final errorText = fieldState.errorText;

        Widget fieldWidget = Container(
          decoration: BoxDecoration(
            color: colors.surfaceLevel2,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(
              color: hasError ? colors.expired : colors.surfaceBorder,
              width: hasError ? 1.2 : 1.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              fontSize: 14,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (value) {
              fieldState.didChange(value);
              if (widget.onChanged != null) widget.onChanged!(value);
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: colors.textMuted,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: hasError ? colors.expired : colors.textSecondary,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
            ),
          ),
        );

        if (hasError && !disableAnimations) {
          fieldWidget = fieldWidget
              .animate(key: ValueKey('${errorText}_${widget.controller?.text}'))
              .shakeX(
                amount: 6,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
              );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            fieldWidget,
            if (hasError && errorText != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: colors.expired,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: colors.expired,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
