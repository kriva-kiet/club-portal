import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriva/widgets/fancy_chip.dart';
import 'package:kriva/widgets/animated_button.dart';

void main() {
  group('FancyChip Widget Tests', () {
    testWidgets('renders chip label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FancyChip(label: 'Flutter dev')),
        ),
      );

      expect(find.text('Flutter dev'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('shows check icon when selected is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FancyChip(label: 'Flutter dev', isSelected: true),
          ),
        ),
      );

      expect(find.text('Flutter dev'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('triggers callback on tap', (WidgetTester tester) async {
      bool selectedValue = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FancyChip(
              label: 'Flutter dev',
              onSelected: (val) {
                selectedValue = val;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Flutter dev'));
      await tester.pumpAndSettle();

      expect(selectedValue, isTrue);
    });
  });

  group('AnimatedButton Widget Tests', () {
    testWidgets('renders button text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(onPressed: () {}, text: 'Click Me'),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('triggers onPressed callback', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: () {
                pressed = true;
              },
              text: 'Click Me',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Click Me'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });
}
