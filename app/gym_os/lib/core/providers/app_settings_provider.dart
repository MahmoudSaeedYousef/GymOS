import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/locale_provider.dart';

export '../l10n/locale_provider.dart';

const String _kThemeModeStorageKey = 'gym_os_selected_theme_mode';

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
