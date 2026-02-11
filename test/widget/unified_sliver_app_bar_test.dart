import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math/core/widgets/unified_sliver_app_bar.dart';

void main() {
  Widget createWidgetUnderTest({
    required String title,
    required bool isLoading,
    String breadcrumbText = 'Grade 6',
    String selectedSort = 'Newest',
  }) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              UnifiedSliverAppBar(
                title: title,
                isLoading: isLoading,
                breadcrumb: Text(breadcrumbText),
                backgroundIcon: Icons.grid_view_rounded,
                selectedSort: selectedSort,
                onSortSelected: (value) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('UnifiedSliverAppBar - Normal State', () {
    testWidgets('renders title when not loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(title: 'Subjects', isLoading: false),
      );

      expect(find.text('Subjects'), findsOneWidget);
    });

    testWidgets('renders breadcrumb when not loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          title: 'Mathematics',
          isLoading: false,
          breadcrumbText: 'Grade 7',
        ),
      );

      expect(find.text('Grade 7'), findsOneWidget);
    });

    testWidgets('renders back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(title: 'Lessons', isLoading: false),
      );

      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('renders sort button when not loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(title: 'Subjects', isLoading: false),
      );

      // Sort button is an IconButton
      expect(find.byType(IconButton), findsAtLeastNWidgets(2));
    });

    testWidgets('renders background icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(title: 'Test', isLoading: false),
      );

      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    });
  });

  group('UnifiedSliverAppBar - Loading State', () {
    testWidgets('shows shimmer for title when loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(title: 'Subjects', isLoading: true),
      );

      // When loading, the title text should not be directly visible
      // Instead, a shimmer container should be shown
      expect(find.text('Subjects'), findsNothing);
    });

    testWidgets('shows shimmer for breadcrumb when loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          title: 'Test',
          isLoading: true,
          breadcrumbText: 'Grade 8',
        ),
      );

      // Breadcrumb text should not be visible when loading
      expect(find.text('Grade 8'), findsNothing);
    });

    testWidgets('shows shimmer for sort button when loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(title: 'Test', isLoading: true),
      );

      // When loading, there should be no sort IconButton
      // Instead, a shimmer container is shown
      // Back button still exists (1 IconButton), but not the sort button
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsOneWidget); // Only back button
    });

    testWidgets('renders back button even when loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(title: 'Test', isLoading: true),
      );

      // Back button should always be present
      expect(find.byType(IconButton), findsOneWidget);
    });
  });

  group('UnifiedSliverAppBar - Dark Mode', () {
    testWidgets('renders correctly in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  UnifiedSliverAppBar(
                    title: 'Test',
                    isLoading: false,
                    breadcrumb: const Text('Breadcrumb'),
                    backgroundIcon: Icons.school,
                    selectedSort: 'Newest',
                    onSortSelected: (value) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Breadcrumb'), findsOneWidget);
    });
  });
}
