import 'package:flutter/material.dart';

class GymColorsExtension extends ThemeExtension<GymColorsExtension> {
  final Color brandPrimary;
  final Color surfaceBackground;
  final Color textHighlight;

  const GymColorsExtension({
    required this.brandPrimary,
    required this.surfaceBackground,
    required this.textHighlight,
  });

  @override
  ThemeExtension<GymColorsExtension> copyWith({
    Color? brandPrimary,
    Color? surfaceBackground,
    Color? textHighlight,
  }) {
    return GymColorsExtension(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      textHighlight: textHighlight ?? this.textHighlight,
    );
  }

  @override
  ThemeExtension<GymColorsExtension> lerp(
    covariant ThemeExtension<GymColorsExtension>? other,
    double t,
  ) {
    if (other is! GymColorsExtension) return this;
    return GymColorsExtension(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      surfaceBackground: Color.lerp(
        surfaceBackground,
        other.surfaceBackground,
        t,
      )!,
      textHighlight: Color.lerp(textHighlight, other.textHighlight, t)!,
    );
  }
}
