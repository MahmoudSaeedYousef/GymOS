import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLocaleStorageKey = 'gym_os_selected_locale';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final savedCode = prefs?.getString(_kLocaleStorageKey);
      if (savedCode != null && (savedCode == 'en' || savedCode == 'ar')) {
        return Locale(savedCode);
      }
    } catch (_) {
      // Fallback if provider was not overridden yet
    }
    return const Locale('ar');
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs != null) {
        await prefs.setString(_kLocaleStorageKey, newLocale.languageCode);
      } else {
        final instance = await SharedPreferences.getInstance();
        await instance.setString(_kLocaleStorageKey, newLocale.languageCode);
      }
    } catch (_) {
      // Ignore if native channel unavailable
    }
  }

  Future<void> toggleLocale() async {
    final nextCode = state.languageCode == 'ar' ? 'en' : 'ar';
    await setLocale(Locale(nextCode));
  }
}
