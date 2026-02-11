import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:math/core/models/grade_model.dart';
import 'package:math/core/models/language_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math/l10n/app_localizations.dart';
import 'package:math/core/services/language_service.dart';
import 'package:math/features/auth/presentation/onboarding/pages/age_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/connect_account_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/create_password_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/gender_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/grade_selection_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/language_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/location_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/login_prompt_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/medium_selection_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/name_input_page.dart';
import 'package:math/features/auth/presentation/onboarding/pages/onboarding_otp_page.dart';

// Helper to wrap widgets with ScreenUtil and MaterialApp
Widget createTestWidget(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812), // Example design size
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) {
      return ChangeNotifierProvider<LanguageService>(
        create: (_) => LanguageService(),
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
          home: Scaffold(body: child),
        ),
      );
    },
  );
}

class MockApiService extends ApiService {
  MockApiService() : super(firestore: FakeFirebaseFirestore());

  @override
  Future<List<LanguageModel>> getLanguages() async {
    // Return dummy languages
    return [
      LanguageModel(
        code: 'en',
        label: 'English',
        nativeName: 'English',
        isActive: true,
        order: 1,
      ),
    ];
  }

  @override
  Future<List<GradeModel>> getGrades(String languageCode) async {
    return [
      GradeModel(
        id: 'g1',
        name: 'Grade 1',
        order: 1,
        isActive: true,
        description: '',
      ),
    ];
  }
}

void main() {
  final apiService = MockApiService();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Onboarding Screens Widget Tests', () {
    // 1. LanguagePage
    testWidgets('LanguagePage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          LanguagePage(onLanguageSelected: (lang) {}, showError: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LanguagePage), findsOneWidget);
    });

    // 2. MediumSelectionPage
    testWidgets('MediumSelectionPage renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          MediumSelectionPage(
            onMediumSelected: (medium) {},
            showError: false,
            apiService: apiService, // Inject mock service
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MediumSelectionPage), findsOneWidget);
    });

    // 3. GradeSelectionPage
    testWidgets('GradeSelectionPage renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          GradeSelectionPage(
            onGradesSelected: (grades) {},
            apiService: apiService, // Inject mock service
          ),
        ),
      );
      await tester.pumpAndSettle();
      // GradeSelectionPage fetches data, might be empty or loading
      expect(find.byType(GradeSelectionPage), findsOneWidget);
    });

    // 4. LocationPage
    testWidgets('LocationPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          LocationPage(
            onProvinceSelected: (p) {},
            onDistrictSelected: (d) {},
            onCitySelected: (c) {},
            showError: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LocationPage), findsOneWidget);
    });

    // 5. GenderPage
    testWidgets('GenderPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GenderPage(onGenderSelected: (gender) {}, showError: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GenderPage), findsOneWidget);
    });

    // 6. AgePage
    testWidgets('AgePage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(AgePage(onAgeSelected: (age) {}, showError: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AgePage), findsOneWidget);
    });

    // 7. NameInputPage
    testWidgets('NameInputPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          NameInputPage(
            onFirstNameChanged: (name) {},
            onLastNameChanged: (name) {},
            showNameError: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NameInputPage), findsOneWidget);
    });

    // 8. ConnectAccountPage
    testWidgets('ConnectAccountPage renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          ConnectAccountPage(
            onEmailChanged: (email) {},
            onMobileChanged: (mobile) {},
            onGoogleSignIn: () async {},
            showError: false,
            isGoogleLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConnectAccountPage), findsOneWidget);
    });

    // 9. OnboardingOtpPage
    testWidgets('OnboardingOtpPage renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          OnboardingOtpPage(
            phoneNumber: '123456789',
            onOtpChanged: (otp) {},
            onResendTapped: () {},
            showError: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingOtpPage), findsOneWidget);
    });

    // 10. CreatePasswordPage
    testWidgets('CreatePasswordPage renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          CreatePasswordPage(
            onPasswordChanged: (pass) {},
            onConfirmPasswordChanged: (pass) {},
            showError: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CreatePasswordPage), findsOneWidget);
    });

    // 11. LoginPromptPage
    testWidgets('LoginPromptPage renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(LoginPromptPage(onLoginPrompt: () async {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginPromptPage), findsOneWidget);
    });
  });
}
