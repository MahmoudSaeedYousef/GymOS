import 'package:flutter/material.dart';
import '../utils/app_number_format.dart';

/// A reusable, theme-friendly numeric counter that animates from 0 to [value]
/// using tabular figures, locale-aware thousands separators, and reduced-motion support.
class AnimatedCounter extends StatelessWidget {
  final num value;
  final String suffix;
  final int fractionDigits;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.fractionDigits = 0,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveDuration = disableAnimations ? Duration.zero : duration;

    final resolvedStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: [
        ...?style?.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: disableAnimations ? value.toDouble() : 0.0,
        end: value.toDouble(),
      ),
      duration: effectiveDuration,
      curve: curve,
      builder: (context, currentValue, child) {
        final formattedValue = AppNumberFormat.format(
          currentValue,
          locale: locale,
          fractionDigits: fractionDigits,
        );

        return Text(
          '$formattedValue$suffix',
          style: resolvedStyle,
        );
      },
    );
  }
}
