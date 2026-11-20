import 'package:flutter/material.dart';
import 'app_spacing.dart';

@immutable
class GymColorsExtension extends ThemeExtension<GymColorsExtension> {
  // Brand Colors (White-Labeling)
  final Color brandPrimary;
  final Color surfaceBackground;
  final Color textHighlight;

  // Semantic Status Colors (Desaturated)
  final Color active;
  final Color expired;
  final Color warning;

  // 3-Tier Surface Elevation Tokens (Neutral tone differentiation, no heavy shadows)
  final Color surfaceLevel0; // Canvas / Scaffold background
  final Color surfaceLevel1; // Base cards, list items
  final Color surfaceLevel2; // Nested cards, search inputs, chips
  final Color
  surfaceLevel3; // Popovers, active segmented tabs, elevated elements
  final Color
  surfaceBorder; // 1px subtle border: white at ~8% opacity in dark mode

  // Typography tokens
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const GymColorsExtension({
    required this.brandPrimary,
    required this.surfaceBackground,
    required this.textHighlight,
    required this.active,
    required this.expired,
    required this.warning,
    required this.surfaceLevel0,
    required this.surfaceLevel1,
    required this.surfaceLevel2,
    required this.surfaceLevel3,
    required this.surfaceBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  GymColorsExtension copyWith({
    Color? brandPrimary,
    Color? surfaceBackground,
    Color? textHighlight,
    Color? active,
    Color? expired,
    Color? warning,
    Color? surfaceLevel0,
    Color? surfaceLevel1,
    Color? surfaceLevel2,
    Color? surfaceLevel3,
    Color? surfaceBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return GymColorsExtension(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      textHighlight: textHighlight ?? this.textHighlight,
      active: active ?? this.active,
      expired: expired ?? this.expired,
      warning: warning ?? this.warning,
      surfaceLevel0: surfaceLevel0 ?? this.surfaceLevel0,
      surfaceLevel1: surfaceLevel1 ?? this.surfaceLevel1,
      surfaceLevel2: surfaceLevel2 ?? this.surfaceLevel2,
      surfaceLevel3: surfaceLevel3 ?? this.surfaceLevel3,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  GymColorsExtension lerp(
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
      active: Color.lerp(active, other.active, t)!,
      expired: Color.lerp(expired, other.expired, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      surfaceLevel0: Color.lerp(surfaceLevel0, other.surfaceLevel0, t)!,
      surfaceLevel1: Color.lerp(surfaceLevel1, other.surfaceLevel1, t)!,
      surfaceLevel2: Color.lerp(surfaceLevel2, other.surfaceLevel2, t)!,
      surfaceLevel3: Color.lerp(surfaceLevel3, other.surfaceLevel3, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension GymThemeContext on BuildContext {
  GymColorsExtension get gymColors =>
      Theme.of(this).extension<GymColorsExtension>()!;
}

class AppTheme {
  static const Color defaultPrimary = Color(
    0xFF1E3A8A,
  ); // Sporty navy for light theme
  static const Color defaultDarkPrimary = Color(
    0xFF60A5FA,
  ); // Blue 400 for dark theme
  static const Color defaultAccent = Color(0xFFF97316); // Energy accent

  // ==========================================
  // 1. Light Theme
  // ==========================================
  static ThemeData lightTheme({Color? tenantPrimaryColor}) {
    final primary = tenantPrimaryColor ?? defaultPrimary;
    const surfaceLevel0 = Color(0xFFF8FAFC);
    const surfaceLevel1 = Color(0xFFFFFFFF);
    const surfaceLevel2 = Color(0xFFF1F5F9);
    const surfaceLevel3 = Color(0xFFE2E8F0);
    const surfaceBorder = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF475569);
    const textMuted = Color(0xFF94A3B8);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: defaultAccent,
      brightness: Brightness.light,
      surface: surfaceLevel0,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceLevel0,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLevel0,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLevel1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
      ),
      extensions: [
        GymColorsExtension(
          brandPrimary: primary,
          surfaceBackground: surfaceLevel1,
          textHighlight: defaultAccent,
          active: const Color(0xFF16A34A),
          expired: const Color(0xFFDC2626),
          warning: const Color(0xFFD97706),
          surfaceLevel0: surfaceLevel0,
          surfaceLevel1: surfaceLevel1,
          surfaceLevel2: surfaceLevel2,
          surfaceLevel3: surfaceLevel3,
          surfaceBorder: surfaceBorder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
        ),
      ],
    );
  }

  // ==========================================
  // 2. Dark Theme
  // ==========================================
  static ThemeData darkTheme({Color? tenantPrimaryColor}) {
    final primary = tenantPrimaryColor ?? defaultDarkPrimary;

    // Neutral dark surfaces differentiated by tone (not shadows or neon tints)
    const surfaceLevel0 = Color(
      0xFF0A0E17,
    ); // Canvas / Scaffold deep neutral dark
    const surfaceLevel1 = Color(0xFF131926); // Base cards / lists
    const surfaceLevel2 = Color(0xFF1C2436); // Nested cards / search inputs
    const surfaceLevel3 = Color(0xFF263248); // Popovers / active segments
    const surfaceBorder = Color(
      0x14FFFFFF,
    ); // 1px subtle border (~8% opacity white)
    const textPrimary = Color(0xFFF9FAFB);
    const textSecondary = Color(0xFF9CA3AF);
    const textMuted = Color(0xFF6B7280);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: defaultAccent,
      brightness: Brightness.dark,
      surface: surfaceLevel0,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceLevel0,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLevel0,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLevel2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
      ),
      extensions: [
        GymColorsExtension(
          brandPrimary: primary,
          surfaceBackground: surfaceLevel1,
          textHighlight: defaultAccent,
          active: const Color(0xFF34D399), // Emerald 400 (desaturated, clean)
          expired: const Color(0xFFF87171), // Red 400 (desaturated, clean)
          warning: const Color(0xFFFBBF24), // Amber 400 (desaturated, clean)
          surfaceLevel0: surfaceLevel0,
          surfaceLevel1: surfaceLevel1,
          surfaceLevel2: surfaceLevel2,
          surfaceLevel3: surfaceLevel3,
          surfaceBorder: surfaceBorder,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
        ),
      ],
    );
  }
}
