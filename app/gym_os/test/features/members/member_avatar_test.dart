import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/features/members/ui/widgets/member_avatar.dart';

void main() {
  group('MemberAvatar Widget Tests', () {
    testWidgets('renders fallback initial letter when photoUrl is null or empty',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MemberAvatar(
                photoUrl: null,
                fullName: 'أحمد محمود',
              ),
            ),
          ),
        ),
      );

      expect(find.text('أ'), findsOneWidget);
    });

    testWidgets('resolves full image URL properly', (tester) async {
      expect(
        resolveMemberPhotoUrl('https://example.com/photo.jpg', 'https://gym.com'),
        'https://example.com/photo.jpg',
      );
      expect(
        resolveMemberPhotoUrl('/uploads/members/photo.jpg', 'https://gym.com'),
        'https://gym.com/uploads/members/photo.jpg',
      );
      expect(
        resolveMemberPhotoUrl('/uploads/members/photo.jpg', 'https://gym.com/'),
        'https://gym.com/uploads/members/photo.jpg',
      );
      expect(resolveMemberPhotoUrl(null, 'https://gym.com'), isNull);
      expect(resolveMemberPhotoUrl('', 'https://gym.com'), isNull);
    });
  });
}
