import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gym_os/core/theme/app_spacing.dart';
import 'package:gym_os/core/theme/app_theme.dart';

class GymButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final String? semanticLabel;

  const GymButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.semanticLabel,
  });

  @override
  State<GymButton> createState() => _GymButtonState();
}

class _GymButtonState extends State<GymButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.isLoading || widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isEnabled = !widget.isLoading && widget.onPressed != null;

    final effectiveScale = (disableAnimations || !_isPressed) ? 1.0 : 0.97;

    Widget content;
    if (widget.isLoading) {
      Widget dot = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: colors.brandPrimary,
          shape: BoxShape.circle,
        ),
      );

      if (!disableAnimations) {
        dot = dot
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.3, 1.3),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
      }

      content = Center(child: dot);
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 20,
              color: isEnabled ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.white : colors.textSecondary,
            ),
          ),
        ],
      );
    }

    final buttonBox = Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusSm,
        gradient: (widget.isLoading || !isEnabled)
            ? null
            : LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  colors.brandPrimary,
                  Color.lerp(colors.brandPrimary, Colors.black, 0.12)!,
                ],
              ),
        color: (widget.isLoading || !isEnabled)
            ? colors.surfaceLevel2
            : null,
        border: (widget.isLoading || !isEnabled)
            ? Border.all(color: colors.surfaceBorder)
            : null,
      ),
      child: content,
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: disableAnimations
            ? buttonBox
            : AnimatedScale(
                scale: effectiveScale,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                child: buttonBox,
              ),
      ),
    );
  }
}
