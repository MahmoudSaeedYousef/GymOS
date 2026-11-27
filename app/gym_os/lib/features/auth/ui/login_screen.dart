import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/network/app_exception.dart';
import 'package:gym_os/core/network/environment_store.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/ui/atoms/gym_text_field.dart';
import 'package:gym_os/features/auth/ui/widgets/environment_switcher_sheet.dart';
import 'package:gym_os/features/auth/ui/widgets/login_success_overlay.dart';
import 'package:gym_os/features/auth/ui/widgets/quick_settings_sheet.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 1) {
          _cooldownSeconds--;
        } else {
          _cooldownSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleLogin() async {
    if (_cooldownSeconds > 0) return;

    if (_phoneController.text.isEmpty) {
      _phoneController.text = '01012345679';
      _passwordController.text = 'StrongPassword123!';
    } else if (_phoneController.text == '1') {
      _phoneController.text = '01012345678';
      _passwordController.text = 'StrongPassword123!';
    } else if (_phoneController.text == '2') {
      _phoneController.text = '01012345677';
      _passwordController.text = 'StrongPassword123!';
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .login(_phoneController.text.trim(), _passwordController.text);

      if (!mounted) return;
      // أنيميشن ترحيب سريع يشتغل فوق الـ rootNavigator أثناء انتقال GoRouter للداشبورد
      showLoginSuccessAnimation(context);
    } catch (e) {
      if (!mounted) return;

      RateLimitException? rateLimitEx;
      if (e is RateLimitException) {
        rateLimitEx = e;
      } else if (e is DioException && e.error is RateLimitException) {
        rateLimitEx = e.error as RateLimitException;
      }

      if (rateLimitEx != null) {
        _startCooldown(rateLimitEx.retryAfterSeconds);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.rateLimitMessage(rateLimitEx.retryAfterSeconds),
            ),
            backgroundColor: context.gymColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.invalidPhoneOrPassword),
            backgroundColor: context.gymColors.expired,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // 1. Logo (88 dp centered with semantic label, long-press to switch environment)
    final envState = ref.watch(environmentProvider);
    Widget logoWidget = GestureDetector(
      onLongPress: () => showEnvironmentSwitcherSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? colors.surfaceLevel1 : colors.surfaceLevel0,
              border: Border.all(
                color: isDark
                    ? colors.brandPrimary.withValues(alpha: 0.25)
                    : colors.surfaceBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? colors.brandPrimary.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: isDark ? 28 : 14,
                  spreadRadius: isDark ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Transform.flip(
                flipX: isRtl,
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  fit: BoxFit.cover,
                  color: !isLight
                      ? Color.lerp(Colors.white, colors.brandPrimary, 0.12)!
                      : null,
                  colorBlendMode: !isLight ? BlendMode.dstATop : null,
                  semanticLabel: context.l10n.appLogoSemanticLabel,
                ),
              ),
            ),
          ),
          if (kDebugMode ||
              envState.environment != ServerEnvironment.production) ...[
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => {}, // showEnvironmentSwitcherSheet(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceLevel2,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: colors.surfaceBorder, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              envState.environment ==
                                  ServerEnvironment.production
                              ? colors.brandPrimary
                              : colors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        envState.environment.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // 2. Title and Subtitle
    Widget titleWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.loginTitle,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.loginSubtitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    // 3. Button
    final isCoolingDown = _cooldownSeconds > 0;
    Widget buttonWidget = GymButton(
      label: isCoolingDown
          ? l10n.rateLimitCooldown(_cooldownSeconds)
          : l10n.loginButton,
      icon: isCoolingDown ? Icons.timer_outlined : Icons.login_rounded,
      isLoading: _isLoading,
      onPressed: (_isLoading || isCoolingDown) ? null : _handleLogin,
      semanticLabel: isCoolingDown
          ? l10n.rateLimitCooldown(_cooldownSeconds)
          : l10n.loginButton,
    );

    // 4. Form Card
    Widget cardWidget = GymCard(
      elevationLevel: 1,
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GymTextField(
              controller: _phoneController,
              label: l10n.phoneNumber,
              hint: l10n.phoneHint,
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.phoneRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            GymTextField(
              controller: _passwordController,
              label: l10n.password,
              hint: l10n.passwordHint,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
                tooltip: _isPasswordVisible
                    ? l10n.hidePassword
                    : l10n.showPassword,
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.passwordRequired : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (isCoolingDown) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: colors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.rateLimitMessage(_cooldownSeconds),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!disableAnimations)
              buttonWidget
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 350),
                  )
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  )
            else
              buttonWidget,
          ],
        ),
      ),
    );

    if (!disableAnimations) {
      logoWidget = logoWidget
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 300))
          .slideY(
            begin: 0.15,
            end: 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );

      titleWidget = titleWidget
          .animate()
          .fadeIn(
            delay: const Duration(milliseconds: 100),
            duration: const Duration(milliseconds: 300),
          )
          .slideY(
            begin: 0.15,
            end: 0,
            delay: const Duration(milliseconds: 100),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );

      cardWidget = cardWidget
          .animate()
          .fadeIn(
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 350),
          )
          .slideY(
            begin: 0.12,
            end: 0,
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(colors.surfaceLevel0, colors.surfaceLevel1, 0.45)!,
              colors.surfaceLevel0,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: logoWidget),
                        const SizedBox(height: AppSpacing.md),
                        titleWidget,
                        const SizedBox(height: AppSpacing.xl),
                        cardWidget,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top Quick-Settings Action Button inside SafeArea
            PositionedDirectional(
              top: 0,
              end: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: AppSpacing.sm,
                    end: AppSpacing.md,
                  ),
                  child: Semantics(
                    button: true,
                    label: l10n.quickSettings,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showQuickSettingsSheet(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.surfaceLevel1.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.surfaceBorder,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
