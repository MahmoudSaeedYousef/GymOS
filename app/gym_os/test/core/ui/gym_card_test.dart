import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/core/theme/app_theme.dart';
import 'package:gym_os/core/ui/atoms/gym_card.dart';
import 'package:gym_os/core/ui/gym_ambient_background.dart';

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

  testWidgets('GymCard applies surfaceLevel1 with micro-dot texture in Dark Mode and opaque surfaceLevel1 in Light Mode', (tester) async {
    // 1. Dark Mode card
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('dark_app'),
        theme: AppTheme.darkTheme(),
        home: const Scaffold(
          body: GymCard(
            key: ValueKey('dark_card'),
            child: Text('Dark Card'),
          ),
        ),
      ),
    );

    final darkMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey('dark_card')),
        matching: find.byType(Material),
      ),
    );
    expect(darkMaterial.color, isNotNull);
    expect(darkMaterial.color!.a, equals(1.0));

    final darkContainer = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('dark_card')),
        matching: find.byType(Container),
      ),
    );
    final darkDecoration = darkContainer.decoration as BoxDecoration;
    expect(darkDecoration.gradient, isNull);

    // Verify dark micro-dot pattern overlay is present in dark mode
    final darkCustomPaint = find.descendant(
      of: find.byKey(const ValueKey('dark_card')),
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GymMicroDotPainter,
      ),
    );
    expect(darkCustomPaint, findsOneWidget);

    // 2. Light Mode card remains untouched (opaque #FFFFFF / surfaceLevel1, no gradient, no micro-dots)
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('light_app'),
        theme: AppTheme.lightTheme(),
        home: const Scaffold(
          body: GymCard(
            key: ValueKey('light_card'),
            child: Text('Light Card'),
          ),
        ),
      ),
    );

    final lightMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byKey(const ValueKey('light_card')),
        matching: find.byType(Material),
      ),
    );
    expect(lightMaterial.color, equals(Colors.white));

    final lightContainer = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('light_card')),
        matching: find.descendant(
          of: find.byType(Material),
          matching: find.byType(Container),
        ),
      ),
    );
    final lightDecoration = lightContainer.decoration as BoxDecoration;
    expect(lightDecoration.gradient, isNull);

    final lightCustomPaint = find.descendant(
      of: find.byKey(const ValueKey('light_card')),
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GymMicroDotPainter,
      ),
    );
    expect(lightCustomPaint, findsNothing);
  });
}
