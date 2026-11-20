import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/utils/whatsapp_helper.dart';

void main() {
  group('WhatsAppHelper.formatEgyptianPhone', () {
    test('formats standard 11-digit mobile starting with 01 correctly', () {
      expect(
        WhatsAppHelper.formatEgyptianPhone('01012345678'),
        '201012345678',
      );
      expect(
        WhatsAppHelper.formatEgyptianPhone('01123456789'),
        '201123456789',
      );
      expect(
        WhatsAppHelper.formatEgyptianPhone('01234567890'),
        '201234567890',
      );
      expect(
        WhatsAppHelper.formatEgyptianPhone('01555555555'),
        '201555555555',
      );
    });

    test('handles spaces, dashes, brackets and symbols', () {
      expect(
        WhatsAppHelper.formatEgyptianPhone('010-123-45678'),
        '201012345678',
      );
      expect(
        WhatsAppHelper.formatEgyptianPhone('011 (234) 56789'),
        '201123456789',
      );
      expect(
        WhatsAppHelper.formatEgyptianPhone('+20 101 234 5678'),
        '201012345678',
      );
      expect(
        WhatsAppHelper.formatEgyptianPhone('+20-112-345-6789'),
        '201123456789',
      );
    });

    test('handles international prefixes +20, 0020, and raw 20', () {
      expect(
        WhatsAppHelper.formatEgyptianPhone('+201012345678'),
        '201012345678',
      );
      expect(
        WhatsAppHelper.formatEgyptianPhone('00201012345678'),
        '201012345678',
      );
      expect(
        WhatsAppHelper.formatEgyptianPhone('201012345678'),
        '201012345678',
      );
    });

    test('handles 10-digit number missing leading 0', () {
      expect(
        WhatsAppHelper.formatEgyptianPhone('1012345678'),
        '201012345678',
      );
    });
  });
}
