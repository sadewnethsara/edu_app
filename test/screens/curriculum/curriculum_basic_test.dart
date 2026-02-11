import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math/core/widgets/curriculum/curriculum_item_card.dart';

void main() {
  group('CurriculumItemCard - Basic Structure', () {
    testWidgets('Subject card has correct structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurriculumItemCard(
              name: 'Mathematics',
              description: 'Study of numbers',
              order: 1,
              type: CurriculumItemType.subject,
              iconName: 'calculator',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Study of numbers'), findsOneWidget);
    });

    testWidgets('Lesson card shows order number', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurriculumItemCard(
              name: 'Algebra Basics',
              description: 'Introduction',
              order: 5,
              type: CurriculumItemType.lesson,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Algebra Basics'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Card is tappable', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurriculumItemCard(
              name: 'Test',
              description: '',
              order: 1,
              type: CurriculumItemType.subject,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CurriculumItemCard));
      expect(tapped, true);
    });
  });
}
