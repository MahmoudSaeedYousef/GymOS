import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final currentFont = ref.watch(appFontProvider);
    final currentPreset = ref.watch(appColorPresetProvider);
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          100,
        ),
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
                    color: colors.brandPrimary,
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
                    color: colors.brandPrimary,
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
                const Divider(),

                // تغيير الخط
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.font_download_outlined,
                    color: colors.brandPrimary,
                  ),
                  title: Text(
                    l10n.appFont,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: DropdownButton<AppFontOption>(
                    value: currentFont,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: AppFontOption.systemDefault,
                        child: Text(l10n.fontDefault),
                      ),
                      DropdownMenuItem(
                        value: AppFontOption.azer,
                        child: Text(
                          l10n.fontAzer,
                          style: const TextStyle(fontFamily: 'Azer'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: AppFontOption.alyamama,
                        child: Text(
                          l10n.fontAlyamama,
                          style: const TextStyle(fontFamily: 'Alyamama'),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(appFontProvider.notifier).setFont(val);
                      }
                    },
                  ),
                ),
                const Divider(),

                // اختيار لون السمة
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: colors.brandPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            l10n.accentColor,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: AppColorPreset.values.map((preset) {
                          final isSelected = preset == currentPreset;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(appColorPresetProvider.notifier)
                                  .setColorPreset(preset);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: preset.seedColor,
                                        width: 2.5,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 2.5,
                                      ),
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: preset.seedColor,
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: preset.seedColor.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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
