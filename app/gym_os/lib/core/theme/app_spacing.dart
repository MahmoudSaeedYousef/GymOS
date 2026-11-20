import 'package:flutter/widgets.dart';

class AppSpacing {
  // 8px Grid Base Spacing Tokens
  static const double xxs = 4.0;
  static const double xs = 4.0; // Backwards compatible alias for 4dp
  static const double sm = 8.0; // 1x grid
  static const double md = 16.0; // 2x grid
  static const double lg = 24.0; // 3x grid
  static const double xl = 32.0; // 4x grid
  static const double xxl = 48.0; // 6x grid

  // Explicit 8px-grid constants
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Radius Tokens (12, 16, 20)
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  // Common Layout Presets
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const BorderRadius borderRadius = borderRadiusSm;
}
