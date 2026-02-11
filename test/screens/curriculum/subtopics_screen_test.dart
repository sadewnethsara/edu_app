import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math/features/lessons/presentation/curriculum/subtopics_screen.dart';
import 'package:math/core/services/language_service.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => ChangeNotifierProvider(
        create: (_) => LanguageService(),
        child: const MaterialApp(
          home: SubtopicsScreen(
            gradeId: 'grade_6',
            subjectId: 'mathematics',
            lessonId: 'algebra_basics',
          ),
        ),
      ),
    );
  }

  group('SubtopicsScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(SubtopicsScreen), findsOneWidget);
    });

    testWidgets('has CustomScrollView', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
