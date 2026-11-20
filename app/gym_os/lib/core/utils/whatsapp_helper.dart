import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// Helper utility for WhatsApp messaging and phone number formatting.
class WhatsAppHelper {
  WhatsAppHelper._();

  /// Normalizes an Egyptian phone number to international format with '20' prefix.
  /// Examples:
  /// - '01012345678' -> '201012345678'
  /// - '+20 101 234 5678' -> '201012345678'
  /// - '011-222-33333' -> '201122233333'
  /// - '1012345678' -> '201012345678'
  static String formatEgyptianPhone(String raw) {
    // 1. Remove spaces, dashes, brackets and any non-digit character (keeping '+')
    String cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');

    // 2. Remove leading '+' if present
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // 3. Remove leading international '00' prefixes
    if (cleaned.startsWith('0020')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('002')) {
      cleaned = '20${cleaned.substring(3)}';
    }

    // 4. If it starts with '01' (standard 11-digit Egyptian mobile), replace '0' with '20'
    if (cleaned.startsWith('01') && cleaned.length == 11) {
      cleaned = '20${cleaned.substring(1)}';
    } else if (cleaned.startsWith('1') && cleaned.length == 10) {
      // 10-digit number without leading 0
      cleaned = '20$cleaned';
    }

    return cleaned;
  }

  /// Sends a localized WhatsApp renewal reminder message to the given member.
  static Future<bool> sendRenewalReminder(
    BuildContext context, {
    required String phoneNumber,
    required String memberName,
  }) async {
    HapticFeedback.lightImpact();

    final formattedPhone = formatEgyptianPhone(phoneNumber);
    final message = context.l10n.whatsappRenewalMessage(memberName);
    final uri = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showErrorSnackBar(context);
        return false;
      }
      return launched;
    } catch (_) {
      if (context.mounted) {
        _showErrorSnackBar(context);
      }
      return false;
    }
  }

  static void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.whatsappLaunchError),
        backgroundColor: context.gymColors.expired,
      ),
    );
  }
}
