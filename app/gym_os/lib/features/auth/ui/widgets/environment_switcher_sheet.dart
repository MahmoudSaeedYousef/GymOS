import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/l10n/l10n_extension.dart';
import 'package:gym_os/core/network/environment_store.dart';
import 'package:gym_os/core/theme/app_spacing.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/ui/atoms/gym_text_field.dart';
import 'package:gym_os/features/auth/providers/auth_provider.dart';

/// Shows the server environment switcher bottom sheet.
/// Guarded by `kDebugMode` or explicit developer trigger (e.g. long-press on logo).
void showEnvironmentSwitcherSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.gymColors.surfaceBackground,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const EnvironmentSwitcherSheet(),
  );
}

class EnvironmentSwitcherSheet extends ConsumerStatefulWidget {
  const EnvironmentSwitcherSheet({super.key});

  @override
  ConsumerState<EnvironmentSwitcherSheet> createState() =>
      _EnvironmentSwitcherSheetState();
}

class _EnvironmentSwitcherSheetState
    extends ConsumerState<EnvironmentSwitcherSheet> {
  late ServerEnvironment _selectedEnv;
  late final TextEditingController _customUrlController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final currentEnvState = ref.read(environmentProvider);
    _selectedEnv = currentEnvState.environment;
    _customUrlController = TextEditingController(
      text: currentEnvState.isCustom ? currentEnvState.baseUrl : '',
    );
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  String _getEnvTitle(ServerEnvironment env) {
    final l10n = context.l10n;
    switch (env) {
      case ServerEnvironment.staging:
        return l10n.envStaging;
      case ServerEnvironment.production:
        return l10n.envProduction;
      case ServerEnvironment.local:
        return l10n.envLocal;
      case ServerEnvironment.custom:
        return l10n.envCustom;
    }
  }

  Future<void> _applyEnvironment(ServerEnvironment env) async {
    if (env == ServerEnvironment.custom &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final customUrl = _customUrlController.text.trim();
    final envNotifier = ref.read(environmentProvider.notifier);

    await envNotifier.setEnvironment(
      env,
      customUrl: env == ServerEnvironment.custom ? customUrl : null,
    );

    // Clear local auth token and reset auth state to prevent sending stale tokens across environments
    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.environmentSwitched(_getEnvTitle(env)),
        ),
        backgroundColor: context.gymColors.brandPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: AppSpacing.lg + bottomInset,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle pill
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sheet Title & Current Indicator
            Row(
              children: [
                Icon(
                  Icons.dns_rounded,
                  color: colors.brandPrimary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.serverEnvironment,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (kDebugMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'DEBUG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.accentText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.selectServerEnvironment,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Predefined options
            ...ServerEnvironment.values.map((env) {
              final isSelected = _selectedEnv == env;
              final isCustom = env == ServerEnvironment.custom;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedEnv = env);
                    if (!isCustom) {
                      _applyEnvironment(env);
                    }
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: GymCard(
                    elevationLevel: isSelected ? 1 : 0,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colors.brandPrimary
                                  : colors.surfaceBorder,
                              width: isSelected ? 6 : 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getEnvTitle(env),
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              if (!isCustom)
                                Text(
                                  env.url,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Custom URL Form if Custom is selected
            if (_selectedEnv == ServerEnvironment.custom) ...[
              Form(
                key: _formKey,
                child: GymTextField(
                  controller: _customUrlController,
                  label: l10n.customServerUrl,
                  hint: l10n.customUrlHint,
                  prefixIcon: Icons.link_rounded,
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.invalidUrl;
                    }
                    final uri = Uri.tryParse(v.trim());
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return l10n.invalidUrl;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GymButton(
                label: l10n.save,
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => _applyEnvironment(ServerEnvironment.custom),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
