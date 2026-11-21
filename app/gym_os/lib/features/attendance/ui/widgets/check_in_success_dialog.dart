import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// دالة مساعدة لاستدعاء الأنيميشن من أي مكان بسطر واحد
Future<void> showCheckInSuccessAnimation(
  BuildContext context, {
  required String memberName,
  String? message,
}) {
  HapticFeedback.lightImpact();

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'CheckInSuccess',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) {
      return _CheckInSuccessDialog(memberName: memberName, message: message);
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
          child: child,
        ),
      );
    },
  );
}

class _CheckInSuccessDialog extends StatefulWidget {
  final String memberName;
  final String? message;

  const _CheckInSuccessDialog({
    required this.memberName,
    this.message,
  });

  @override
  State<_CheckInSuccessDialog> createState() => _CheckInSuccessDialogState();
}

class _CheckInSuccessDialogState extends State<_CheckInSuccessDialog> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    // يقفل تلقائياً بعد 1.6 ثانية عشان سرعة الشغل على الريسبشن
    _autoCloseTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.active.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.active.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة الصح مع حلقات نبضية متوسعة
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // الحلقة الخارجية المتوسعة
                    Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.active.withValues(alpha: 0.15),
                          ),
                        )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.15, 1.15),
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeOut(delay: 300.ms, duration: 400.ms),

                    // الدائرة الأساسية
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.active,
                        boxShadow: [
                          BoxShadow(
                            color: colors.active.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child:
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 42,
                          ).animate().scale(
                            begin: const Offset(0.0, 0.0),
                            end: const Offset(1.0, 1.0),
                            delay: 100.ms,
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // اسم المشترك
              Text(
                    widget.memberName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 300.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: AppSpacing.xs),

              // رسالة التأكيد
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.active.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.message ?? context.l10n.checkInSuccess,
                      style: TextStyle(
                        color: colors.active,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 220.ms, duration: 300.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
