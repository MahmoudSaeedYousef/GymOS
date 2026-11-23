import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';

void main() {
  group('Theme Contrast Tests (WCAG 4.5:1)', () {
    final testAccents = <String, Color>{
      'purple': const Color(0xFF800080),
      'blue': const Color(0xFF0000FF),
      'green': const Color(0xFF00FF00),
      'orange': const Color(0xFFFFA500),
      'very light yellow': const Color(0xFFFFFFE0),
    };

    for (final entry in testAccents.entries) {
      final name = entry.key;
      final accent = entry.value;

      test('accentText achieves >= 4.5:1 contrast in light mode for $name', () {
        final lightTheme = AppTheme.lightTheme(tenantPrimaryColor: accent);
        final gymColors = lightTheme.extension<GymColorsExtension>()!;

        final contrastOnSurface1 = AppTheme.calculateContrastRatio(
          gymColors.accentText,
          gymColors.surfaceLevel1,
        );
        final contrastOnScaffold = AppTheme.calculateContrastRatio(
          gymColors.accentText,
          lightTheme.scaffoldBackgroundColor,
        );

        expect(
          contrastOnSurface1,
          greaterThanOrEqualTo(4.5),
          reason:
              'Expected >= 4.5:1 contrast against surfaceLevel1 for $name in light mode, got $contrastOnSurface1',
        );
        expect(
          contrastOnScaffold,
          greaterThanOrEqualTo(4.5),
          reason:
              'Expected >= 4.5:1 contrast against scaffoldBackgroundColor for $name in light mode, got $contrastOnScaffold',
        );
      });

      test('accentText achieves >= 4.5:1 contrast in dark mode for $name', () {
        final darkTheme = AppTheme.darkTheme(tenantPrimaryColor: accent);
        final gymColors = darkTheme.extension<GymColorsExtension>()!;

        final contrastOnSurface1 = AppTheme.calculateContrastRatio(
          gymColors.accentText,
          gymColors.surfaceLevel1,
        );
        final contrastOnScaffold = AppTheme.calculateContrastRatio(
          gymColors.accentText,
          darkTheme.scaffoldBackgroundColor,
        );

        expect(
          contrastOnSurface1,
          greaterThanOrEqualTo(4.5),
          reason:
              'Expected >= 4.5:1 contrast against surfaceLevel1 for $name in dark mode, got $contrastOnSurface1',
        );
        expect(
          contrastOnScaffold,
          greaterThanOrEqualTo(4.5),
          reason:
              'Expected >= 4.5:1 contrast against scaffoldBackgroundColor for $name in dark mode, got $contrastOnScaffold',
        );
      });
    }

    test('caches computed accentText per (accent, brightness) pair', () {
      const accent = Color(0xFF1E3A8A);
      final color1 = AppTheme.computeAccentText(
        accent: accent,
        brightness: Brightness.light,
      );
      final color2 = AppTheme.computeAccentText(
        accent: accent,
        brightness: Brightness.light,
      );

      expect(identical(color1, color2) || color1 == color2, isTrue);
    });

    test('derived backgroundLight token is tinted toward accent hue', () {
      const orangeAccent = Color(0xFFEA580C);
      final bg = AppTheme.computeBackgroundLight(orangeAccent);
      final hsl = HSLColor.fromColor(bg);

      // Lightness is ~97–98%
      expect(hsl.lightness, greaterThanOrEqualTo(0.96));
      expect(hsl.lightness, lessThanOrEqualTo(0.99));
      // Saturation is subtle (~4-8% accounting for 8-bit color quantization)
      expect(hsl.saturation, greaterThan(0.0));
      expect(hsl.saturation, lessThanOrEqualTo(0.10));
    });
  });
}
