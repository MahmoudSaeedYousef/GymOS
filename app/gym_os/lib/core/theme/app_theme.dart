import 'package:flutter/material.dart';
import 'app_spacing.dart';

@immutable
class GymColorsExtension extends ThemeExtension<GymColorsExtension> {
  // Brand Colors (White-Labeling)
  final Color brandPrimary;
  final Color surfaceBackground;
  final Color textHighlight;

  // Semantic Status Colors
  final Color active;
  final Color expired;
  final Color warning;

  const GymColorsExtension({
    required this.brandPrimary,
    required this.surfaceBackground,
    required this.textHighlight,
    required this.active,
    required this.expired,
    required this.warning,
  });

  @override
  GymColorsExtension copyWith({
    Color? brandPrimary,
    Color? surfaceBackground,
    Color? textHighlight,
    Color? active,
    Color? expired,
    Color? warning,
  }) {
    return GymColorsExtension(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      textHighlight: textHighlight ?? this.textHighlight,
      active: active ?? this.active,
      expired: expired ?? this.expired,
      warning: warning ?? this.warning,
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
  ); // كحلي رياضي (للثيم الفاتح)
  static const Color defaultDarkPrimary = Color(
    0xFF60A5FA,
  ); // أزرق فاتح مشرق (للثيم الداكن)
  static const Color defaultAccent = Color(0xFFF97316); // برتقالي طاقة

  // ==========================================
  // 1. الثيم الفاتح (Light Theme)
  // ==========================================
  static ThemeData lightTheme({Color? tenantPrimaryColor}) {
    final primary = tenantPrimaryColor ?? defaultPrimary;
    const surfaceBg = Color(0xFFF8FAFC);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: defaultAccent,
      brightness: Brightness.light,
      surface: surfaceBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadius,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadius,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadius,
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
      ),
      extensions: [
        GymColorsExtension(
          brandPrimary: primary,
          surfaceBackground: surfaceBg,
          textHighlight: defaultAccent,
          active: const Color(0xFF16A34A),
          expired: const Color(0xFFDC2626),
          warning: const Color(0xFFD97706),
        ),
      ],
    );
  }

  // ==========================================
  // 2. الثيم الداكن (Dark Theme)
  // ==========================================
  static ThemeData darkTheme({Color? tenantPrimaryColor}) {
    // 💡 التعديل الجذري هنا: لو مفيش لون من السيرفر، بنستخدم اللون الفاتح المشرق المخصص للدارك مود
    final primary = tenantPrimaryColor ?? defaultDarkPrimary;

    // خلفيات داكنة مريحة للعين (مش أسود صريح)
    const darkSurfaceBg = Color(0xFF0F172A); // Slate 900
    const darkInputBg = Color(0xFF1E293B); // Slate 800

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: defaultAccent,
      brightness: Brightness.dark,
      surface: darkSurfaceBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkSurfaceBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfaceBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadius,
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadius,
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadius,
          borderSide: BorderSide(
            color: primary,
            width: 1.8,
          ), // 👈 الـ Focus هيبقى أزرق فاتح
        ),
      ),
      extensions: [
        GymColorsExtension(
          brandPrimary:
              primary, // 👈 كل التطبيق هيقرأ الأزرق الفاتح في الدارك مود
          surfaceBackground: darkInputBg,
          textHighlight: defaultAccent,
          active: const Color(0xFF22C55E), // Green 500
          expired: const Color(0xFFEF4444), // Red 500
          warning: const Color(0xFFF59E0B), // Amber 500
        ),
      ],
    );
  }
}
