import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/core/network/environment_store.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/ui/atoms/gym_text_field.dart';
import 'package:gym_os/features/auth/ui/widgets/environment_switcher_sheet.dart';
import 'package:gym_os/features/auth/ui/widgets/login_success_overlay.dart';
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

  // Future<void> _handleLogin() async {
  //   if (_phoneController.text.isEmpty) {
  //     _phoneController.text = '01012345679';
  //     _passwordController.text = 'StrongPassword123!';
  //   }
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isLoading = true);

  //   try {
  //     await ref
  //         .read(authProvider.notifier)
  //         .login(_phoneController.text.trim(), _passwordController.text);
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('رقم الهاتف أو كلمة المرور غير صحيحة'),
  //           backgroundColor: Colors.red,
  //           behavior: SnackBarBehavior.floating,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
  Future<void> _handleLogin() async {
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
      if (mounted) {
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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final l10n = context.l10n;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // 1. Logo (88 dp centered with semantic label, long-press to switch environment)
    final envState = ref.watch(environmentProvider);
    Widget logoWidget = GestureDetector(
      onLongPress: () => showEnvironmentSwitcherSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/app_icon.png',
            width: 88,
            height: 88,
            fit: BoxFit.contain,
            semanticLabel: l10n.appLogoSemanticLabel,
          ),
          if (kDebugMode ||
              envState.environment != ServerEnvironment.production) ...[
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () => showEnvironmentSwitcherSheet(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceLevel2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: colors.surfaceBorder, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            envState.environment == ServerEnvironment.production
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
    Widget buttonWidget = GymButton(
      label: l10n.loginButton,
      icon: Icons.login_rounded,
      isLoading: _isLoading,
      onPressed: _handleLogin,
      semanticLabel: l10n.loginButton,
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
              isPassword: true,
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.passwordRequired : null,
            ),
            const SizedBox(height: AppSpacing.xl),
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
        child: SafeArea(
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
      ),
    );
  }
}
