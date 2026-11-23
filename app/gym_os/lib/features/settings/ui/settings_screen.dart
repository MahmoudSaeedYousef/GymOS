import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/core/database/database_provider.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/network/dio_client.dart';
import 'package:gym_os/core/sync/sync_provider.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/features/home/providers/dashboard_provider.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/payments/providers/payments_provider.dart';
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

  int _tapCount = 0;
  DateTime? _firstTapTime;
  bool _devModeUnlocked = false;
  bool _isPopulatingDemoData = false;

  void _handleHeaderTap() {
    final now = DateTime.now();
    if (_firstTapTime == null ||
        now.difference(_firstTapTime!) > const Duration(seconds: 2)) {
      _firstTapTime = now;
      _tapCount = 1;
    } else {
      _tapCount++;
      if (_tapCount >= 5) {
        setState(() {
          _devModeUnlocked = true;
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final colors = context.gymColors;
    final db = ref.read(appDatabaseProvider);
    final pendingCount = await db.syncOutboxDao.getPendingCount();

    if (!context.mounted) return;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: colors.expired,
            size: 32,
          ),
          title: Text(l10n.signOutConfirmationTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.signOutConfirmationMessage),
              if (pendingCount > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.expired.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.expired.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        color: colors.expired,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.signOutUnsyncedWarning(pendingCount),
                          style: TextStyle(
                            color: colors.expired,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.expired,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true && context.mounted) {
      HapticFeedback.mediumImpact();
      ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _populate30DayDemoData() async {
    if (_isPopulatingDemoData) return;

    setState(() {
      _isPopulatingDemoData = true;
    });

    final dio = ref.read(dioProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await dio.post('/api/dev/populate-30day-history');

      // Clear local Drift tables & sync metadata
      final db = ref.read(appDatabaseProvider);
      await db.clearAllTablesAndMetadata();

      // Trigger full fresh sync from server
      await ref.read(syncEngineProvider).pullLatestState();

      // Invalidate relevant providers to immediately update all Dashboard KPIs, chart, and members
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(weeklyStatsProvider);
      ref.invalidate(paymentsSummaryProvider);
      ref.read(membersProvider.notifier).loadInitial();

      if (mounted) {
        final data = response.data;
        String message = 'Demo data populated successfully';
        if (data is Map<String, dynamic> && data['message'] != null) {
          message = data['message'].toString();
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to populate demo data';
        final resData = e.response?.data;
        if (resData is Map<String, dynamic> && resData['message'] != null) {
          errorMsg = resData['message'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMsg = e.message!;
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPopulatingDemoData = false;
        });
      }
    }
  }

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
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleHeaderTap,
          child: Text(l10n.settingsTitle),
        ),
      ),
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleHeaderTap,
                  child: Text(
                    l10n.appCustomization,
                    style: TextStyle(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.bold,
                    ),
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
                  style: TextStyle(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GymButton(
                  label: l10n.logout,
                  icon: Icons.logout_rounded,
                  onPressed: () => _handleSignOut(context),
                ),
              ],
            ),
          ),

          if (_devModeUnlocked) ...[
            const SizedBox(height: AppSpacing.xl),
            GymCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.developer_mode_rounded,
                        size: 18,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Developer Tools',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Populate 30 days of realistic attendance, revenue, and subscriptions for testing.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isPopulatingDemoData
                          ? null
                          : _populate30DayDemoData,
                      icon: _isPopulatingDemoData
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(
                        _isPopulatingDemoData
                            ? 'Populating Demo Data...'
                            : 'Populate 30-Day Demo Data',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
