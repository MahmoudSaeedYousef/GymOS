import 'package:flutter/material.dart';
import 'package:gym_os/core/theme/app_spacing.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/ui/gym_ambient_background.dart';

/// A theme-aware card component with neutral tone-based elevation (no heavy shadows or neon glows).
class GymCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final int elevationLevel; // 1, 2, or 3
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final Color? backgroundColor;

  const GymCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevationLevel = 1,
    this.borderRadius,
    this.padding,
    this.border,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppSpacing.borderRadiusMd;

    // In Light Mode, cards default to pure white surfaceLevel1 (#FFFFFF).
    // In Dark Mode, cards default to surfaceLevel1 (#141923).
    final resolvedBg = backgroundColor ?? colors.surfaceLevel1;

    final effectiveBorder = border ?? Border.all(color: colors.surfaceBorder);

    Widget content = onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: padding ?? AppSpacing.cardPadding,
              child: child,
            ),
          )
        : Padding(
            padding: padding ?? AppSpacing.cardPadding,
            child: child,
          );

    final cardBody = Material(
      color: resolvedBg,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: isDark
          ? Stack(
              fit: StackFit.passthrough,
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: GymMicroDotPainter(spacing: 24.0, radius: 0.8),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: effectiveBorder,
                  ),
                  child: content,
                ),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: effectiveBorder,
              ),
              child: content,
            ),
    );

    if (!isDark) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03 * elevationLevel),
              blurRadius: 4.0 * elevationLevel,
              offset: Offset(0, 1.0 * elevationLevel),
            ),
          ],
        ),
        child: cardBody,
      );
    }

    return cardBody;
  }
}
