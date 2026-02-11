import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/widgets/poll_widget.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../helpers/test_helpers.mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuthService = MockAuthService();
    fakeFirestore = FakeFirebaseFirestore();
  });

  Widget createWidgetUnderTest(PollData pollData, {String? userId}) {
    // Setup Mock User if needed
    if (userId != null) {
      final user = MockUser(uid: userId, displayName: 'Test User');
      when(mockAuthService.user).thenReturn(user);
    } else {
      when(mockAuthService.user).thenReturn(null);
    }

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: Provider<AuthService>.value(
            value: mockAuthService,
            child: PollWidget(
              postId: 'post_1',
              pollData: pollData,
              firestore: fakeFirestore,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('PollWidget renders options correctly', (
    WidgetTester tester,
  ) async {
    final pollData = PollData(
      options: ['Option A', 'Option B'],
      voteCounts: [10, 5],
      totalVotes: 15,
      lengthDays: 1,
      endsAt: Timestamp.now(),
      allowMultipleVotes: false,
    );

    await tester.pumpWidget(createWidgetUnderTest(pollData, userId: 'user_1'));
    await tester.pump(); // Settle state

    expect(find.text('Option A'), findsOneWidget);
    expect(find.text('Option B'), findsOneWidget);
    // Since it's expired (Timestamp.now()), it should show results
    expect(find.text('15 votes · Final results'), findsOneWidget);
  });
}
