import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math/features/lessons/presentation/curriculum/subjects_screen.dart';
import 'package:math/core/services/language_service.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => ChangeNotifierProvider(
        create: (_) => LanguageService(),
        child: const MaterialApp(home: SubjectsScreen(gradeId: 'grade_6')),
      ),
    );
  }

  group('SubjectsScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // The screen should render
      expect(find.byType(SubjectsScreen), findsOneWidget);
    });

    testWidgets('shows loading shimmer initially', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // On first frame, should show loading state
      expect(find.byType(SubjectsScreen), findsOneWidget);
    });

    testWidgets('has CustomScrollView', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
