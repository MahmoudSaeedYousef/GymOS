import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/gym_ambient_background.dart';
import '../providers/auth_provider.dart';

/// Animated branded splash screen for Gymmy.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    _navigationTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _navigateNext();
    });
  }

  void _navigateNext() {
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GymAmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Centered Brand Identity
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Elevated White Squircle Emblem with App Icon
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: colors.brandPrimary.withValues(alpha: isDark ? 0.35 : 0.18),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          AppAssets.appIcon,
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1.0, 1.0),
                          duration: 650.ms,
                          curve: Curves.elasticOut,
                        ),

                    const SizedBox(height: AppSpacing.lg),

                    // Gymmy Brand Title
                    Text(
                      context.l10n.appTitle,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: colors.brandPrimary,
                        letterSpacing: -0.8,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: AppSpacing.xs),

                    // Localized Subtle Tagline
                    Text(
                      context.l10n.splashTagline,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        letterSpacing: 0.2,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 350.ms, duration: 450.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                  ],
                ),
              ),

              // Subtle Minimal Loading Indicator at the Bottom
              Positioned(
                bottom: AppSpacing.xl,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.brandPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
