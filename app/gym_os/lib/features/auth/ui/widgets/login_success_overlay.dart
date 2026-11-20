import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

Future<void> showLoginSuccessAnimation(BuildContext context) {
  HapticFeedback.mediumImpact();

  return showGeneralDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'LoginSuccess',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, anim1, anim2) {
      return const _LoginSuccessDialog();
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.88,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
          child: child,
        ),
      );
    },
  );
}

class _LoginSuccessDialog extends StatefulWidget {
  const _LoginSuccessDialog();

  @override
  State<_LoginSuccessDialog> createState() => _LoginSuccessDialogState();
}

class _LoginSuccessDialogState extends State<_LoginSuccessDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.78,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.active.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.active.withValues(alpha: 0.2),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.active,
                  boxShadow: [
                    BoxShadow(
                      color: colors.active.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child:
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 38,
                    ).animate().scale(
                      begin: const Offset(0.0, 0.0),
                      end: const Offset(1.0, 1.0),
                      delay: 80.ms,
                      duration: 380.ms,
                      curve: Curves.elasticOut,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                    context.l10n.welcomeToGymOS,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 280.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppSpacing.xs),
              Text(
                    context.l10n.loginSuccess,
                    style: TextStyle(
                      color: colors.active,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 280.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
