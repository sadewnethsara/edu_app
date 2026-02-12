import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/router/app_router.dart';

import 'package:math/core/widgets/styled_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateSystemNavBarColor(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSystemNavBarColor() {
    final surfaceColor = Theme.of(context).scaffoldBackgroundColor;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: surfaceColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateSystemNavBarColor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 0.12.sh),
                Container(
                  alignment: Alignment.center,
                  height: 0.35.sh,
                  child: Lottie.asset(
                    'assets/animations/welcome.json',
                    controller: _controller,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Unlock Your Math Potential",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 32.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  "Explore engaging lessons, master new concepts, and track your progress in the world of mathematics.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StyledButton(
                onPressed: () {
                  context.push(AppRouter.onboardingPath);
                },
                text: "GET STARTED",
                isPrimary: true,
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () {
                  context.push(AppRouter.loginPath);
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.fromHeight(56.h),
                  foregroundColor: theme.colorScheme.primary, // Use theme color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: 2.0,
                    ),
                  ),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 16.sp,
                  ),
                ),
                child: const Text("I ALREADY HAVE AN ACCOUNT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
