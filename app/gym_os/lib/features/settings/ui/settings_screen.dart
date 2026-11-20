import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // كارد إعدادات التطبيق (لغة وثيم)
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appCustomization,
                  style: TextStyle(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // تغيير الثيم
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: colors.textHighlight,
                  ),
                  title: Text(
                    l10n.darkMode,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Switch.adaptive(
                    value: themeMode == ThemeMode.dark,
                    activeTrackColor: colors.brandPrimary,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).setDarkMode(val);
                    },
                  ),
                ),
                const Divider(),

                // تغيير اللغة
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.language_rounded,
                    color: colors.textHighlight,
                  ),
                  title: Text(
                    l10n.language,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: DropdownButton<String>(
                    value: locale.languageCode,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text(l10n.languageArabic),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(l10n.languageEnglish),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(val));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // كارد إدارة الباقات والاشتراكات
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.managePlansAndSubscriptions,
                  style: TextStyle(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.card_membership_rounded,
                    color: colors.brandPrimary,
                  ),
                  title: Text(
                    l10n.managePlans,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_ios_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    context.pushNamed('plans');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // كارد الحساب وتسجيل الخروج
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.account,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GymButton(
                  label: l10n.logout,
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
