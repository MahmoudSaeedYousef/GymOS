import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/providers/app_settings_provider.dart';
import 'package:gym_os/core/theme/app_spacing.dart';
import 'package:gym_os/core/theme/app_theme.dart';

/// Opens the quick settings bottom sheet for pre-auth actions
/// (Theme mode toggle, language toggle, and server environment status/switching).
void showQuickSettingsSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.gymColors.surfaceBackground,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const QuickSettingsSheet(),
  );
}

class QuickSettingsSheet extends ConsumerWidget {
  const QuickSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.gymColors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    // final envState = ref.watch(environmentProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: colors.brandPrimary,
                    size: 20,
                  ),
                ),
                //   const SizedBox(width: AppSpacing.sm),
                //   Expanded(
                //     child: Text(
                //       l10n.quickSettings,
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //         color: colors.textPrimary,
                //       ),
                //     ),
                //   ),
                //   IconButton(
                //     icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                //     onPressed: () => Navigator.of(context).pop(),
                //     tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                //   ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Settings Container
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceLevel1,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: colors.surfaceBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  // Dark Mode Switch
                  ListTile(
                    leading: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: colors.brandPrimary,
                    ),
                    title: Text(
                      l10n.darkMode,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: themeMode == ThemeMode.dark,
                      activeTrackColor: colors.brandPrimary,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).setDarkMode(val);
                      },
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: colors.surfaceBorder,
                  ),

                  // Language Switch
                  ListTile(
                    leading: Icon(
                      Icons.language_rounded,
                      color: colors.brandPrimary,
                    ),
                    title: Text(
                      l10n.language,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    trailing: DropdownButton<String>(
                      value: locale.languageCode,
                      underline: const SizedBox(),
                      dropdownColor: colors.surfaceLevel2,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.textSecondary,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text(
                            l10n.languageArabic,
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(
                            l10n.languageEnglish,
                            style: TextStyle(color: colors.textPrimary),
                          ),
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
            // const SizedBox(height: AppSpacing.md),

            // // Server Environment Tile
            // Container(
            //   decoration: BoxDecoration(
            //     color: colors.surfaceLevel1,
            //     borderRadius: AppSpacing.borderRadiusMd,
            //     border: Border.all(color: colors.surfaceBorder, width: 0.8),
            //   ),
            //   child: ListTile(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: AppSpacing.borderRadiusMd,
            //     ),
            //     leading: Container(
            //       width: 10,
            //       height: 10,
            //       decoration: BoxDecoration(
            //         shape: BoxShape.circle,
            //         color: envState.environment == ServerEnvironment.production
            //             ? colors.active
            //             : colors.warning,
            //       ),
            //     ),
            //     title: Text(
            //       l10n.serverEnvironment,
            //       style: TextStyle(
            //         fontWeight: FontWeight.w600,
            //         color: colors.textPrimary,
            //       ),
            //     ),
            //     subtitle: Text(
            //       '${envState.environment.label} (${envState.baseUrl})',
            //       style: TextStyle(
            //         fontSize: 12,
            //         color: colors.textSecondary,
            //       ),
            //       maxLines: 1,
            //       overflow: TextOverflow.ellipsis,
            //     ),
            //     trailing: Icon(
            //       Icons.arrow_forward_ios_rounded,
            //       size: 16,
            //       color: colors.textSecondary,
            //     ),
            //     onTap: () {
            //       Navigator.of(context).pop();
            //       showEnvironmentSwitcherSheet(context);
            //     },
            //   ),
            // ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
