import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/providers/app_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeModeNotifier loads saved dark theme from SharedPreferences on start', () async {
    SharedPreferences.setMockInitialValues({
      'gym_os_selected_theme_mode': 'dark',
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final mode = container.read(themeModeProvider);
    expect(mode, ThemeMode.dark);
  });

  test('ThemeModeNotifier saves new theme to SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Initial default is ThemeMode.system
    expect(container.read(themeModeProvider), ThemeMode.system);

    // Set to dark mode
    await container.read(themeModeProvider.notifier).setDarkMode(true);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString('gym_os_selected_theme_mode'), 'dark');

    // Set to light mode
    await container.read(themeModeProvider.notifier).setDarkMode(false);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString('gym_os_selected_theme_mode'), 'light');
  });
}
