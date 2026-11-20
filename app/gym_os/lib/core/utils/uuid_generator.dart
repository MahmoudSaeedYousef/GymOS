import 'dart:math';

/// Lightweight pure-Dart UUID generator conforming to RFC 4122 Version 4.
class UuidGenerator {
  static final Random _random = Random.secure();

  /// Generates a random RFC 4122 version 4 UUID string.
  /// Example: `f47ac10b-58cc-4372-a567-0e02b2c3d479`
  static String v4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Version 4: set bits 4-7 of the 7th byte to 0100
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    // Variant RFC 4122: set bits 6-7 of the 9th byte to 10
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();

    return '${hex[0]}${hex[1]}${hex[2]}${hex[3]}-'
        '${hex[4]}${hex[5]}-'
        '${hex[6]}${hex[7]}-'
        '${hex[8]}${hex[9]}-'
        '${hex[10]}${hex[11]}${hex[12]}${hex[13]}${hex[14]}${hex[15]}';
  }
}
