import 'package:flutter/material.dart';
import '../utils/app_number_format.dart';

/// A reusable, theme-friendly numeric counter that animates from its previous value
/// to [value] using tabular figures, locale-aware thousands separators, and reduced-motion support.
/// If oldValue == newValue, no animation is triggered.
class AnimatedCounter extends StatefulWidget {
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
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  late double _oldValue;

  @override
  void initState() {
    super.initState();
    _oldValue = 0.0;
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final targetValue = widget.value.toDouble();
    final effectiveDuration =
        (disableAnimations || _oldValue == targetValue) ? Duration.zero : widget.duration;

    final resolvedStyle =
        (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: [
        ...?widget.style?.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _oldValue,
        end: targetValue,
      ),
      duration: effectiveDuration,
      curve: widget.curve,
      builder: (context, currentValue, child) {
        final formattedValue = AppNumberFormat.format(
          currentValue,
          locale: locale,
          fractionDigits: widget.fractionDigits,
        );

        return Text(
          '$formattedValue${widget.suffix}',
          style: resolvedStyle,
        );
      },
    );
  }
}
