import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math/core/widgets/curriculum/curriculum_item_card.dart';

void main() {
  Widget createWidgetUnderTest({
    required String name,
    required String description,
    required int order,
    required CurriculumItemType type,
    String? iconName,
    bool isDark = false,
  }) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: CurriculumItemCard(
            name: name,
            description: description,
            order: order,
            type: type,
            iconName: iconName,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  group('CurriculumItemCard - Subject', () {
    testWidgets('renders subject card with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          name: 'Mathematics',
          description: 'Study of numbers and patterns',
          order: 1,
          type: CurriculumItemType.subject,
          iconName: 'calculator',
        ),
      );

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Study of numbers and patterns'), findsOneWidget);
      expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
    });

    testWidgets(
      'renders subject card with default icon when iconName is unknown',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            name: 'Unknown Subject',
            description: 'Test description',
            order: 2,
            type: CurriculumItemType.subject,
            iconName: 'unknown',
          ),
        );

        expect(find.text('Unknown Subject'), findsOneWidget);
        expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      },
    );

    testWidgets('renders subject card in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          name: 'Science',
          description: 'Scientific studies',
          order: 3,
          type: CurriculumItemType.subject,
          iconName: 'science',
          isDark: true,
        ),
      );

      expect(find.text('Science'), findsOneWidget);
      expect(find.byIcon(Icons.science_rounded), findsOneWidget);
    });
  });

  group('CurriculumItemCard - Lesson', () {
    testWidgets('renders lesson card with order number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          name: 'Introduction to Algebra',
          description: 'Basic algebraic concepts',
          order: 5,
          type: CurriculumItemType.lesson,
        ),
      );

      expect(find.text('Introduction to Algebra'), findsOneWidget);
      expect(find.text('Basic algebraic concepts'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders lesson card without description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          name: 'Lesson Title',
          description: '',
          order: 1,
          type: CurriculumItemType.lesson,
        ),
      );

      expect(find.text('Lesson Title'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('CurriculumItemCard - Subtopic', () {
    testWidgets('renders subtopic card with order number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          name: 'Solving Equations',
          description: 'Learn to solve various equations',
          order: 3,
          type: CurriculumItemType.subtopic,
        ),
      );

      expect(find.text('Solving Equations'), findsOneWidget);
      expect(find.text('Learn to solve various equations'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('CurriculumItemCard - Interaction', () {
    testWidgets('calls onTap callback when tapped', (
      WidgetTester tester,
    ) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: CurriculumItemCard(
                name: 'Test',
                description: 'Description',
                order: 1,
                type: CurriculumItemType.subject,
                onTap: () {
                  wasTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CurriculumItemCard));
      await tester.pump();

      expect(wasTapped, true);
    });
  });
}
