import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/locale_provider.dart';

export '../l10n/locale_provider.dart';

const String _kThemeModeStorageKey = 'gym_os_selected_theme_mode';
const String _kAppFontStorageKey = 'gym_os_selected_font';
const String _kAppColorPresetStorageKey = 'gym_os_selected_color_preset';

enum AppFontOption {
  systemDefault(null),
  azer('Azer'),
  alyamama('Alyamama');

  final String? fontFamily;
  const AppFontOption(this.fontFamily);
}

enum AppColorPreset {
  royalBlue(Color.fromARGB(255, 93, 133, 243)),
  violet(Color.fromARGB(255, 110, 47, 218)),
  emerald(Color.fromARGB(255, 17, 198, 140)),
  energyOrange(Color(0xFFEA580C)),
  crimson(Color.fromARGB(255, 159, 26, 26)),
  rose(Color.fromARGB(255, 210, 45, 133));

  final Color seedColor;
  const AppColorPreset(this.seedColor);
}

// ---------------------------------------------------------------------------
// ThemeMode
// ---------------------------------------------------------------------------
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final savedTheme = prefs?.getString(_kThemeModeStorageKey);
      if (savedTheme != null) {
        for (final mode in ThemeMode.values) {
          if (mode.name == savedTheme) {
            return mode;
          }
        }
      }
    } catch (_) {
      // Fallback if provider was not overridden yet
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs != null) {
        await prefs.setString(_kThemeModeStorageKey, mode.name);
      } else {
        final instance = await SharedPreferences.getInstance();
        await instance.setString(_kThemeModeStorageKey, mode.name);
      }
    } catch (_) {
      // Ignore if native channel unavailable
    }
  }

  Future<void> setDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

// ---------------------------------------------------------------------------
// AppFontOption
// ---------------------------------------------------------------------------
final appFontProvider = NotifierProvider<AppFontNotifier, AppFontOption>(() {
  return AppFontNotifier();
});

class AppFontNotifier extends Notifier<AppFontOption> {
  @override
  AppFontOption build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final savedFont = prefs?.getString(_kAppFontStorageKey);
      if (savedFont != null) {
        for (final option in AppFontOption.values) {
          if (option.name == savedFont) {
            return option;
          }
        }
      }
    } catch (_) {
      // Fallback
    }
    return AppFontOption.systemDefault;
  }

  Future<void> setFont(AppFontOption option) async {
    if (state == option) return;
    state = option;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs != null) {
        await prefs.setString(_kAppFontStorageKey, option.name);
      } else {
        final instance = await SharedPreferences.getInstance();
        await instance.setString(_kAppFontStorageKey, option.name);
      }
    } catch (_) {
      // Ignore if native channel unavailable
    }
  }
}

// ---------------------------------------------------------------------------
// AppColorPreset
// ---------------------------------------------------------------------------
final appColorPresetProvider =
    NotifierProvider<AppColorPresetNotifier, AppColorPreset>(() {
      return AppColorPresetNotifier();
    });

class AppColorPresetNotifier extends Notifier<AppColorPreset> {
  @override
  AppColorPreset build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final savedPreset = prefs?.getString(_kAppColorPresetStorageKey);
      if (savedPreset != null) {
        for (final preset in AppColorPreset.values) {
          if (preset.name == savedPreset) {
            return preset;
          }
        }
      }
    } catch (_) {
      // Fallback
    }
    return AppColorPreset.energyOrange;
  }

  Future<void> setColorPreset(AppColorPreset preset) async {
    if (state == preset) return;
    state = preset;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs != null) {
        await prefs.setString(_kAppColorPresetStorageKey, preset.name);
      } else {
        final instance = await SharedPreferences.getInstance();
        await instance.setString(_kAppColorPresetStorageKey, preset.name);
      }
    } catch (_) {
      // Ignore if native channel unavailable
    }
  }
}
