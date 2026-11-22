import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

/// Resolves the absolute URL for a member photo.
///
/// If `photoUrl` starts with `http://` or `https://`, returns it as-is.
/// Otherwise, prepends the Dio baseUrl (stripping duplicate slashes).
String? resolveMemberPhotoUrl(String? photoUrl, String? baseUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final trimmed = photoUrl.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (baseUrl == null || baseUrl.isEmpty) return trimmed;
  final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final normalizedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$normalizedBase$normalizedPath';
}

/// A circular member avatar displaying network image with robust fallback to initial-letter avatar.
class MemberAvatar extends ConsumerWidget {
  final String? photoUrl;
  final String fullName;
  final double radius;
  final double? fontSize;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MemberAvatar({
    super.key,
    required this.photoUrl,
    required this.fullName,
    this.radius = 22,
    this.fontSize,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final initialLetter = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : '?';

    final bgColor = backgroundColor ?? colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? colorScheme.primary;
    final effectiveFontSize = fontSize ?? (radius * 0.8);
    final diameter = radius * 2;

    Widget buildFallback() {
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: bgColor,
          shape: borderRadius != null ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: Text(
          initialLetter,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: effectiveFontSize,
            color: fgColor,
          ),
        ),
      );
    }

    final dio = ref.watch(dioProvider);
    final resolvedUrl = resolveMemberPhotoUrl(photoUrl, dio.options.baseUrl);

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return buildFallback();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      child: Image.network(
        resolvedUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildFallback(),
      ),
    );
  }
}
