import 'package:flutter/material.dart';
import 'package:gym_os/core/theme/app_theme.dart';

class GymLabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;

  const GymLabeledInput({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    final gymColors = context.gymColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: gymColors.textHighlight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: gymColors.surfaceBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: gymColors.brandPrimary.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: gymColors.brandPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
