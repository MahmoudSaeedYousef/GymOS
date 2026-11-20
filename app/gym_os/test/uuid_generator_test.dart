import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/utils/uuid_generator.dart';

void main() {
  group('UuidGenerator Tests', () {
    test('generates valid RFC 4122 v4 UUID format', () {
      final uuid = UuidGenerator.v4();
      final regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      expect(regex.hasMatch(uuid), isTrue, reason: 'UUID $uuid does not match v4 regex');
    });

    test('generates unique UUIDs on multiple calls', () {
      final set = <String>{};
      for (int i = 0; i < 100; i++) {
        final id = UuidGenerator.v4();
        expect(set.contains(id), isFalse);
        set.add(id);
      }
      expect(set.length, 100);
    });
  });
}
