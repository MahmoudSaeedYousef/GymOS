import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';

void main() {
  testWidgets('GymCard renders Material widget and does not hide ListTile splashes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: GymCard(
            child: ListTile(
              title: const Text('Test Title'),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    // Verify Material widget exists inside GymCard
    final materialFinder = find.descendant(
      of: find.byType(GymCard),
      matching: find.byType(Material),
    );
    expect(materialFinder, findsOneWidget);

    // Verify ListTile is rendered without throwing
    expect(find.text('Test Title'), findsOneWidget);
  });
}
