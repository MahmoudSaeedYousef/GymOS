import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/features/attendance/models/current_inside_member_model.dart';
import 'package:gym_os/features/attendance/providers/attendance_provider.dart';
import 'package:gym_os/features/attendance/ui/widgets/current_inside_sheet.dart';
import 'package:gym_os/features/members/ui/widgets/member_avatar.dart';
import 'package:gym_os/l10n/app_localizations.dart';

void main() {
  testWidgets('CurrentInsideSheet renders MemberAvatar with photoUrl and fallback', (tester) async {
    final testMembers = [
      CurrentInsideMemberModel(
        recordId: 'rec-1',
        memberId: 'mem-1',
        fullName: 'أحمد علي',
        phoneNumber: '0101111111',
        checkInTime: DateTime.now().subtract(const Duration(minutes: 15)),
        photoUrl: 'https://example.com/photo.jpg',
      ),
      CurrentInsideMemberModel(
        recordId: 'rec-2',
        memberId: 'mem-2',
        fullName: 'محمود حسن',
        phoneNumber: '0102222222',
        checkInTime: DateTime.now().subtract(const Duration(minutes: 45)),
        photoUrl: null,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentInsideProvider.overrideWith((ref) => Stream.value(testMembers)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(
            body: CurrentInsideSheet(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify MemberAvatar widgets are rendered
    expect(find.byType(MemberAvatar), findsNWidgets(2));
    expect(find.text('أحمد علي'), findsOneWidget);
    expect(find.text('محمود حسن'), findsOneWidget);
  });
}
