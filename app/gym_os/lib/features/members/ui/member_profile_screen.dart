import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_os/core/ui/atoms/gym_button.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/utils/whatsapp_helper.dart';
import 'package:intl/intl.dart';
import 'package:gym_os/features/attendance/ui/widgets/check_in_success_dialog.dart';
import 'package:gym_os/features/members/providers/members_provider.dart';
import 'package:gym_os/features/payments/ui/renew_subscription_sheet.dart';
import 'package:lottie/lottie.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../attendance/services/attendance_api_service.dart';
import '../models/member_model.dart';
import '../services/gym_api_service.dart';
import 'widgets/edit_member_sheet.dart';
import 'widgets/member_avatar.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  final MemberModel member;

  const MemberProfileScreen({super.key, required this.member});

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  late MemberModel _currentMember;
  bool _isCheckingIn = false;
  bool _isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
  }

  @override
  void didUpdateWidget(covariant MemberProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.member != oldWidget.member) {
      _currentMember = widget.member;
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);
    try {
      final message = await ref
          .read(attendanceApiProvider)
          .checkIn(_currentMember.id);

      if (!mounted) return;

      ref.read(membersProvider.notifier).resetFilters();

      // تشغيل أنيميشن تسجيل الحضور
      await showCheckInSuccessAnimation(
        context,
        memberName: _currentMember.fullName,
        message: message,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: context.gymColors.expired,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _openEditDetailsSheet() async {
    final updated = await showModalBottomSheet<MemberModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gymColors.surfaceBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditMemberSheet(member: _currentMember),
    );

    if (updated != null && mounted) {
      setState(() => _currentMember = updated);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.gymColors.surfaceBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('الكاميرا', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('المعرض', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) return;

      File fileToUpload = File(pickedFile.path);
      const maxSizeBytes = 500 * 1024; // 500 KB

      // Convert PNG or large images to compressed JPEG (< 500 KB)
      final isPng = fileToUpload.path.toLowerCase().endsWith('.png');
      if (isPng || fileToUpload.lengthSync() > maxSizeBytes) {
        try {
          final targetPath =
              '${fileToUpload.parent.path}/member_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final compressedXFile = await FlutterImageCompress.compressAndGetFile(
            fileToUpload.path,
            targetPath,
            format: CompressFormat.jpeg,
            minWidth: 512,
            minHeight: 512,
            quality: 75,
          );

          if (compressedXFile != null) {
            fileToUpload = File(compressedXFile.path);
          }
        } catch (_) {
          // If compression fails or is unsupported on platform, continue with original
        }
      }

      if (fileToUpload.lengthSync() > maxSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'حجم الصورة أكبر من 500 كيلوبايت، يرجى اختيار صورة أخرى',
            ),
            backgroundColor: context.gymColors.expired,
          ),
        );
        return;
      }

      setState(() => _isUploadingPhoto = true);

      final photoUrl = await ref
          .read(gymApiServiceProvider)
          .uploadMemberPhoto(_currentMember.id, fileToUpload);

      if (!mounted) return;

      setState(() {
        _currentMember = _currentMember.copyWith(photoUrl: photoUrl);
      });

      ref.invalidate(membersProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تحديث الصورة بنجاح'),
          backgroundColor: context.gymColors.active,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: context.gymColors.expired,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final isActive = _currentMember.subscriptionStatus.toLowerCase() == 'active';
    final statusColor = isActive ? colors.active : colors.expired;
    final isExpiringSoon = _currentMember.isExpiringSoon;
    final shouldShowReminder = !isActive || isExpiringSoon;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.memberProfileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل بيانات المشترك',
            onPressed: _openEditDetailsSheet,
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // 1. الهيدر (بيانات العميل)
          GymCard(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    MemberAvatar(
                      photoUrl: _currentMember.photoUrl,
                      fullName: _currentMember.fullName,
                      radius: 40,
                      fontSize: 32,
                    ),
                    if (_isUploadingPhoto)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: colors.brandPrimary,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _currentMember.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentMember.phoneNumber,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive
                        ? context.l10n.activeSubscription
                        : context.l10n.expiredSubscription,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. تفاصيل الباقة
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.subscriptionDetails,
                  style: TextStyle(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _DetailRow(
                  icon: Icons.card_membership_rounded,
                  label: context.l10n.plan,
                  value: _currentMember.activePlanName ?? context.l10n.noPlan,
                ),
                if (_currentMember.subscriptionEndDate != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: context.l10n.endDate,
                    value: _formatProfileEndDate(
                      _currentMember.subscriptionEndDate!,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 3. الإجراءات (Actions)
          GymButton(
            label: context.l10n.recordAttendance,
            icon: Icons.fingerprint_rounded,
            isLoading: _isCheckingIn,
            onPressed: isActive
                ? _handleCheckIn
                : null, // الزر مقفول لو الاشتراك منتهي
          ),
          const SizedBox(height: AppSpacing.md),
          GymButton(
            label: context.l10n.renewSubscription,
            icon: Icons.payment_rounded,
            onPressed: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: context.gymColors.surfaceBackground,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => RenewSubscriptionSheet(member: _currentMember),
              );

              if (!context.mounted) return;
              if (result == true) {
                ref.read(membersProvider.notifier).resetFilters();
                context.pop();
              }
            },
          ),
          if (shouldShowReminder) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => WhatsAppHelper.sendRenewalReminder(
                  context,
                  phoneNumber: _currentMember.phoneNumber,
                  memberName: _currentMember.fullName,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: colors.active.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  backgroundColor: colors.active.withValues(alpha: 0.08),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadius,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/Whatsapp.json',
                      width: 26,
                      height: 26,
                      repeat: false,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.sendWhatsappReminder,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.active,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

String _formatProfileEndDate(String rawDate) {
  final parsed = DateTime.tryParse(rawDate);
  if (parsed != null) {
    return DateFormat('yyyy-MM-dd').format(parsed);
  }
  if (rawDate.length >= 10) {
    return rawDate.substring(0, 10);
  }
  return rawDate;
}
