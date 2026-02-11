import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math/screens/curriculum/lessons_screen.dart';
import 'package:math/services/language_service.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => ChangeNotifierProvider(
        create: (_) => LanguageService(),
        child: const MaterialApp(
          home: LessonsScreen(gradeId: 'grade_6', subjectId: 'mathematics'),
        ),
      ),
    );
  }

  group('LessonsScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(LessonsScreen), findsOneWidget);
    });

    testWidgets('has CustomScrollView', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
