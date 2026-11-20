import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// A theme-aware skeleton loading box animated with a smooth shimmer effect.
class GymShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const GymShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? colors.surfaceBackground
        : colors.brandPrimary.withValues(alpha: 0.06);

    final shimmerColor = isDark
        ? colors.brandPrimary.withValues(alpha: 0.2)
        : colors.surfaceBackground;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colors.brandPrimary.withValues(alpha: isDark ? 0.12 : 0.06),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: shimmerColor,
        );
  }
}
