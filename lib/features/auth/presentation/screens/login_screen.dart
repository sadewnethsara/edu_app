import 'dart:ui'; // 🚀 For BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/widgets/smart_identifier_field.dart';
import 'package:math/core/widgets/styled_button.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:math/core/widgets/standard_bottom_sheet.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// 🚀 Define login states
enum LoginStep { identifier, password, otp }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  // UI State
  LoginStep _currentStep = LoginStep.identifier; // 🚀 Use enum
  bool _showCreateAccount = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateSystemNavBarColor(),
    );
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
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!context.mounted) return;
    MessageBanner.show(context, message: message, type: MessageType.error);
  }

  /// Handles the "CONTINUE" button tap
  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _showCreateAccount = false;
    });

    final authService = context.read<AuthService>();
    final String identifier = _identifierController.text.trim();

    if (identifier.contains('@')) {
      // --- EMAIL LOGIC ---
      final bool emailExists = await authService.checkEmailExists(identifier);
      if (emailExists) {
        setState(() {
          _currentStep = LoginStep.password;
          _isLoading = false;
        });
      } else {
        setState(() {
          _showCreateAccount = true;
          _isLoading = false;
        });
        // Automatically show the bottom sheet
        if (mounted) {
          _showCreateAccountSheet(context);
        }
      }
    } else {
      // --- PHONE LOGIC ---
      String formattedPhone = identifier;
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+94${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+94$formattedPhone';
      }

      // Check if phone number exists
      final bool phoneExists = await authService.checkPhoneExists(
        formattedPhone,
      );

      if (phoneExists) {
        // Phone exists - send OTP for login
        try {
          if (!mounted) return;
          await authService.sendOtpToPhone(context, formattedPhone);
          setState(() {
            _currentStep = LoginStep.otp;
            _isLoading = false;
          });
        } catch (e) {
          _showError(e.toString());
          setState(() => _isLoading = false);
        }
      } else {
        // Phone doesn't exist - show create account sheet
        setState(() {
          _showCreateAccount = true;
          _isLoading = false;
        });
        if (mounted) {
          _showCreateAccountSheet(context);
        }
      }
    }
  }

  /// Handles the "LOG IN" button tap
  Future<void> _submitPasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();

    final error = await authService.signInWithEmail(
      email: _identifierController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (error != null) {
      _showError(error);
      if (mounted) setState(() => _isLoading = false);
    }
    // On success, auth listener will redirect
  }

  /// Handles the "VERIFY OTP" button tap
  Future<void> _submitOtpLogin() async {
    if (_otpController.text.trim().length < 6) {
      _showError("Please enter the 6-digit OTP.");
      return;
    }

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();

    final error = await authService.signInWithPhoneOtp(
      _otpController.text.trim(),
    );

    if (error != null) {
      _showError(error);
    }

    if (context.mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitGoogleSignIn() async {
    setState(() => _isLoading = true);
    final error = await context.read<AuthService>().signInWithGoogle();

    if (error == "USER_NOT_FOUND") {
      // Google user doesn't exist in Firestore - show create account sheet
      setState(() {
        _isLoading = false;
        _showCreateAccount = true;
      });
      if (mounted) {
        _showCreateAccountSheet(context);
      }
    } else if (error != null) {
      // Other errors - show error message
      _showError(error);
      setState(() => _isLoading = false);
    } else {
      // Success - loading state will be cleared by auth listener
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetToIdentifierStep() {
    setState(() {
      _currentStep = LoginStep.identifier;
      _passwordController.clear();
      _otpController.clear();
      _showCreateAccount = false;
    });
  }

  // 🚀 --- NEW WIDGET: Animated Form Body --- 🚀
  Widget _buildAnimatedForm(ThemeData theme) {
    Widget currentForm;
    switch (_currentStep) {
      case LoginStep.password:
        currentForm = _buildPasswordForm(theme);
        break;
      case LoginStep.otp:
        currentForm = _buildOtpForm(theme);
        break;
      case LoginStep.identifier:
        currentForm = _buildIdentifierForm(theme);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        // Slide in from the right
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);

        // Fade in
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: Padding(
        key: ValueKey(_currentStep), // Key is crucial for AnimatedSwitcher
        padding: EdgeInsets.all(24.w),
        child: currentForm,
      ),
    );
  }

  // 🚀 --- NEW WIDGET: Identifier Form --- 🚀
  Widget _buildIdentifierForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //SizedBox(height: 12.h),
        SmartIdentifierField(controller: _identifierController),

        SizedBox(height: 24.h),
        StyledButton(
          onPressed: _handleContinue,
          text: "CONTINUE",
          isLoading: _isLoading,
          isPrimary: true,
        ),
      ],
    );
  }

  // 🚀 --- NEW WIDGET: Password Form --- 🚀
  Widget _buildPasswordForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Enter Password", style: theme.textTheme.headlineMedium),
        SizedBox(height: 8.h),
        Text(
          "Signing in as ${_identifierController.text}",
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 32.h),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofocus: true, // Auto-focus on this field
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: const Icon(Icons.lock_outline),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.length < 6) {
              return "Password too short";
            }
            return null;
          },
        ),
        SizedBox(height: 24.h),
        StyledButton(
          onPressed: _submitPasswordLogin,
          text: "LOG IN",
          isLoading: _isLoading,
          isPrimary: true,
        ),
      ],
    );
  }

  // 🚀 --- NEW WIDGET: OTP Form --- 🚀
  // 🚀 --- NEW WIDGET: OTP Form --- 🚀
  Widget _buildOtpForm(ThemeData theme) {
    final defaultPinTheme = PinTheme(
      width: 50.w,
      height: 58.h,
      textStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Verify Phone", style: theme.textTheme.headlineMedium),
        SizedBox(height: 8.h),
        Text(
          "Enter the 6-digit code sent to ${_identifierController.text}",
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 32.h),

        // 🌟 Redesigned OTP Input
        Pinput(
          length: 6,
          controller: _otpController,
          autofocus: true,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              border: Border.all(color: theme.primaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          submittedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              color: theme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.length != 6) {
              return "Please enter all 6 digits";
            }
            return null;
          },
          onCompleted: (_) => _submitOtpLogin(),
        ),

        SizedBox(height: 24.h),
        StyledButton(
          onPressed: _submitOtpLogin,
          text: "VERIFY OTP",
          isLoading: _isLoading,
          isPrimary: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.primaryColor,
              expandedHeight: 180.h,
              pinned: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _currentStep != LoginStep.identifier
                          ? Icons.arrow_back_rounded
                          : Icons.close_rounded,
                      color: Colors.black,
                    ),
                    onPressed: _currentStep != LoginStep.identifier
                        ? _resetToIdentifierStep
                        : () => context.go(AppRouter.welcomePath),
                  ),
                ),
              ),

              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle background icon
                      Positioned(
                        right: -40.w,
                        bottom: -40.h,
                        child: Icon(
                          FontAwesome.arrow_right_arrow_left_solid,
                          size: 200.sp,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),

                      // --- ✨ Main Header Texts ---
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 24.w,
                            bottom: 32.h,
                            right: 24.w,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome Back",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26.sp,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Sign in to continue your learning journey",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 🚀 --- NEW "Glass" Card --- 🚀
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: _buildAnimatedForm(theme),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // "OR" Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              "OR",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: _buildGoogleSignInButton(theme),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Create Account Button
                      if (_showCreateAccount)
                        ElevatedButton(
                          onPressed: () => _showCreateAccountSheet(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.fromHeight(56.h),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                          ),
                          child: const Text(
                            "CREATE AN ACCOUNT",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () => context.go(AppRouter.onboardingPath),
                          child: const Text(
                            "Don't have an account? Create One",
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 --- NEW: Redesigned Google Button --- 🚀
  Widget _buildGoogleSignInButton(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        // Slide in from the right
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);

        // Fade in
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: Padding(
        key: ValueKey(_currentStep), // Key is crucial for AnimatedSwitcher
        padding: EdgeInsets.all(24.w),
        child: TextButton.icon(
          onPressed: _isLoading ? null : _submitGoogleSignIn,
          style: TextButton.styleFrom(
            minimumSize: Size.fromHeight(56.h),
            foregroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.r),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                width: 2.0,
              ),
            ),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          icon: _isLoading
              ? null
              : SvgPicture.asset(
                  'assets/images/google.svg',
                  width: 16.sp,
                  height: 16.sp,
                ),
          label: _isLoading
              ? SizedBox(
                  height: 24.h,
                  width: 24.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                )
              : const Text("CONTINUE WITH GOOGLE"),
        ),
      ),
    );
  }

  // 🚀 --- Show Create Account Bottom Sheet --- 🚀
  void _showCreateAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return StandardBottomSheet(
          title: "No Account Found",
          icon: Icons.person_add_alt_1_rounded,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.rotate(
                      angle: value * 0.1,
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 64.sp,
                        color: theme.primaryColor,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),

              // Title
              Text(
                "Create an account to start your learning journey",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Create Account Button
              StyledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRouter.onboardingPath);
                },
                text: "CREATE AN ACCOUNT",
                isPrimary: true,
                isLoading: false,
              ),
              SizedBox(height: 12.h),

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
            ],
          ),
        );
      },
    );
  }
}
