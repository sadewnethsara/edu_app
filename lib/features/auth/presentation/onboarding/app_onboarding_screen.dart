import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:provider/provider.dart';

import 'package:math/core/widgets/styled_button.dart';

import 'pages/age_page.dart';
import 'pages/connect_account_page.dart';
import 'pages/create_password_page.dart';
import 'pages/gender_page.dart';
import 'pages/grade_selection_page.dart';
import 'pages/language_page.dart';
import 'pages/location_page.dart';
import 'pages/login_prompt_page.dart';
import 'pages/medium_selection_page.dart';
import 'pages/name_input_page.dart';
import 'pages/onboarding_otp_page.dart';
import 'pages/google_phone_page.dart';

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({super.key});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late ConfettiController _confettiController;
  final _loginPasswordController =
      TextEditingController(); // For login bottom sheet

  String? _selectedAppLanguage;
  String? _selectedLearningMedium;
  List<String> _selectedGrades = [];
  String? _province;
  String? _district;
  String? _city;
  String? _selectedGender;
  String? _selectedAge;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _mobile = '';
  String _otpCode = '';
  String _password = '';
  String _confirmPassword = '';

  bool _showLangError = false;
  bool _showMediumError = false;
  bool _showCityError = false;
  bool _showNameError = false;
  bool _showGenderError = false;
  bool _showAgeError = false;
  bool _showConnectError = false;
  bool _showOtpError = false;
  bool _showPasswordError = false;
  bool _isGoogleLoading = false;
  bool _isContinueLoading = false;
  bool _isGoogleRegistration = false; // Flag for Google Sign-In flow

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateSystemNavBarColor(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _loginPasswordController.dispose();
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  void _showSuccessToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onInverseSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2), // Disappears automatically
      ),
    );
  }

  Future<void> _saveOnboardingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboard_language', _selectedAppLanguage ?? 'N/A');
      await prefs.setString('onboard_medium', _selectedLearningMedium ?? 'N/A');
      await prefs.setStringList('onboard_grades', _selectedGrades);
      await prefs.setString('onboard_province', _province ?? 'N/A');
      await prefs.setString('onboard_district', _district ?? 'N/A');
      await prefs.setString('onboard_city', _city ?? 'N/A');
      await prefs.setString('onboard_gender', _selectedGender ?? 'N/A');
      await prefs.setString('onboard_age', _selectedAge ?? 'N/A');
      await prefs.setString('tempUserName', '$_firstName $_lastName');
      await prefs.setBool('onboardingComplete', true);
      logger.i("✅ Onboarding Data Saved to SharedPreferences");
    } catch (e, s) {
      logger.e("Failed to save onboarding data", error: e, stackTrace: s);
    }
  }

  Future<void> _completeOnboarding() async {
    final authService = context.read<AuthService>();
    await _saveOnboardingData();

    if (authService.user != null) {
      await authService.uploadOnboardingData(authService.user!);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.go(AppRouter.homePath);
    }
  }

  void _triggerHapticsAndError(VoidCallback toggleErrorFlag) {
    logger.w("Validation error on page $_currentPage");
    HapticFeedback.heavyImpact();
    setState(toggleErrorFlag);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(toggleErrorFlag);
    });
  }

  Future<void> _nextPage() async {
    logger.d("Next button pressed on page $_currentPage");
    final authService = context.read<AuthService>();

    FocusScope.of(context).unfocus();

    bool blockNavigation = false;

    if (_currentPage == 0 && _selectedAppLanguage == null) {
      _triggerHapticsAndError(() => _showLangError = true);
      blockNavigation = true;
    }
    if (_currentPage == 1 && _selectedLearningMedium == null) {
      _triggerHapticsAndError(() => _showMediumError = true);
      blockNavigation = true;
    }
    if (_currentPage == 3 && _city == null) {
      _triggerHapticsAndError(() => _showCityError = true);
      blockNavigation = true;
    }
    if (_currentPage == 4 && _selectedGender == null) {
      _triggerHapticsAndError(() => _showGenderError = true);
      blockNavigation = true;
    }
    if (_currentPage == 5 && _selectedAge == null) {
      _triggerHapticsAndError(() => _showAgeError = true);
      blockNavigation = true;
    }
    if (_currentPage == 6 &&
        (_firstName.trim().isEmpty || _lastName.trim().isEmpty)) {
      _triggerHapticsAndError(() => _showNameError = true);
      blockNavigation = true;
    }

    if (_currentPage == 7) {
      if (_isGoogleRegistration) {
        if (_mobile.trim().length < 9) {
          _triggerHapticsAndError(() => _showConnectError = true);
          blockNavigation = true;
        } else {
          if (!mounted) return;
          setState(() => _isContinueLoading = true);
          final fullPhoneNumber = "+94${_mobile.trim()}";
          try {
            await authService.sendOtpToPhone(context, fullPhoneNumber);
            setState(() => _isContinueLoading = false);
          } catch (e) {
            setState(() => _isContinueLoading = false);
            _showErrorSnackBar(e.toString());
            blockNavigation = true;
          }
        }
      } else {
        final isEmailInvalid = !RegExp(
          r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
        ).hasMatch(_email);
        final isPhoneInvalid = _mobile.trim().length < 9;
        if (isEmailInvalid || isPhoneInvalid) {
          _triggerHapticsAndError(() => _showConnectError = true);
          blockNavigation = true;
        } else {
          if (!mounted) return;
          setState(() => _isContinueLoading = true);

          final bool emailExists = await authService.checkEmailExists(_email);
          final fullPhoneNumber = "+94${_mobile.trim()}";
          final bool phoneExists = await authService.checkPhoneExists(
            fullPhoneNumber,
          );

          if (!mounted) return;
          setState(() => _isContinueLoading = false);

          if (emailExists || phoneExists) {
            logger.i("Email or phone exists, prompting for login.");
            _showLoginBottomSheet(
              context,
              emailExists ? _email : _mobile,
              emailExists,
            );
            blockNavigation = true; // Stop navigation
          } else {
            logger.i("New user, sending OTP.");
            try {
              await authService.sendOtpToPhone(context, fullPhoneNumber);
            } catch (e) {
              _showErrorSnackBar(e.toString());
              blockNavigation = true; // Stop navigation on OTP fail
            }
          }
        }
      }
    }

    if (_currentPage == 8) {
      if (_otpCode.length < 6) {
        _triggerHapticsAndError(() => _showOtpError = true);
        blockNavigation = true;
      } else if (_isGoogleRegistration) {
        if (!mounted) return;
        setState(() => _isContinueLoading = true);
        final error = await authService.signUpWithGoogleAndPhone(
          smsCode: _otpCode,
        );
        if (!mounted) return;
        setState(() => _isContinueLoading = false);

        if (error != null) {
          _showErrorSnackBar(error);
          blockNavigation = true;
        } else {
          _confettiController.play();
          _showSuccessToast("Welcome! Your account is created.");
          _pageController.animateToPage(
            10,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
          blockNavigation = true;
        }
      }
    }
    if (_currentPage == 9) {
      final isPasswordInvalid =
          _password.length < 6 || _password != _confirmPassword;
      if (isPasswordInvalid) {
        _triggerHapticsAndError(() => _showPasswordError = true);
        blockNavigation = true;
      } else {
        if (!mounted) return;
        setState(() => _isContinueLoading = true);
        final error = await authService.signUpWithEmailPasswordAndLinkPhone(
          email: _email,
          password: _password,
          smsCode: _otpCode,
        );
        if (!mounted) return;
        setState(() => _isContinueLoading = false);

        if (error != null) {
          _showErrorSnackBar(error);
          if (error.contains('code')) {
            _pageController.animateToPage(
              7,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          }
          blockNavigation = true;
        } else {
          _confettiController.play();
          _showSuccessToast("Welcome! Your account is created.");
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            await _completeOnboarding();
          }
          blockNavigation =
              true; // We're handling navigation in _completeOnboarding
        }
      }
    }

    if (_currentPage == 10) {
      _confettiController.play();
      _showSuccessToast("You're all set!");
      await _completeOnboarding();
    }

    if (!blockNavigation && _currentPage < 10) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _prevPage() async {
    if (_currentPage == 7 && _isGoogleRegistration) {
      setState(() => _isGoogleRegistration = false);
      return;
    }

    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      if (mounted) {
        context.go(AppRouter.welcomePath);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;
    setState(() => _isGoogleLoading = true);
    final authService = context.read<AuthService>();

    await _saveOnboardingToPrefs();

    final error = await authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (error == "USER_NOT_FOUND") {
      setState(() {
        _isGoogleRegistration = true;
      });
      _showSuccessToast("Almost there! Please verify your phone.");
    } else if (error != null) {
      _showErrorSnackBar(error);
    } else {
      _showSuccessToast("Welcome back!");
      context.go(AppRouter.homePath);
    }
  }

  Future<void> _saveOnboardingToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (_selectedAppLanguage != null) {
      await prefs.setString('onboard_language', _selectedAppLanguage!);
    }
    if (_selectedLearningMedium != null) {
      await prefs.setString('onboard_medium', _selectedLearningMedium!);
    }
    if (_selectedGrades.isNotEmpty) {
      await prefs.setStringList('onboard_grades', _selectedGrades);
    }
    if (_province != null) {
      await prefs.setString('onboard_province', _province!);
    }
    if (_district != null) {
      await prefs.setString('onboard_district', _district!);
    }
    if (_city != null) {
      await prefs.setString('onboard_city', _city!);
    }
    if (_selectedGender != null) {
      await prefs.setString('onboard_gender', _selectedGender!);
    }
    if (_selectedAge != null) {
      await prefs.setString('onboard_age', _selectedAge!);
    }

    final fullName = '${_firstName.trim()} ${_lastName.trim()}'.trim();
    if (fullName.isNotEmpty) {
      await prefs.setString('tempUserName', fullName);
    }
    if (_email.isNotEmpty) {
      await prefs.setString('onboard_email', _email);
    }
    if (_mobile.isNotEmpty) {
      await prefs.setString('onboard_mobile', _mobile);
    }

    await prefs.setBool('onboardingComplete', true);
  }

  Future<void> _handleResendOtp() async {
    logger.i('Resending OTP to $_mobile');
    final authService = context.read<AuthService>();
    try {
      final fullPhoneNumber = "+94${_mobile.trim()}"; // ADJUST COUNTRY CODE
      await authService.sendOtpToPhone(context, fullPhoneNumber);
      if (mounted) {
        _showSuccessToast('A new code has been sent.');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showLoginBottomSheet(
    BuildContext context,
    String identifier,
    bool isEmail,
  ) {
    final theme = Theme.of(context);
    bool isLoading = false;
    bool obscureText = true;
    String? errorText;

    _loginPasswordController.clear(); // Clear password on open
    _otpCode = ''; // Clear OTP

    Future<void> handleEmailLogin(StateSetter setSheetState) async {
      final authService = context.read<AuthService>();
      setSheetState(() {
        isLoading = true;
        errorText = null;
      });

      final error = await authService.signInWithEmail(
        email: identifier,
        password: _loginPasswordController.text,
      );

      if (error == null) {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close bottom sheet
        _confettiController.play();
        _showSuccessToast("Welcome back!");
        await _completeOnboarding(); // Save data and go home
      } else {
        setSheetState(() {
          isLoading = false;
          errorText = "Wrong password. Please try again.";
        });
      }
    }

    Future<void> handlePhoneLogin(StateSetter setSheetState) async {
      final authService = context.read<AuthService>();

      if (_otpCode.length < 6) {
        setSheetState(() {
          errorText = "Please enter the 6-digit OTP code.";
        });
        return;
      }

      setSheetState(() {
        isLoading = true;
        errorText = null;
      });

      final error = await authService.signInWithPhoneOtp(_otpCode);

      if (error == null) {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close bottom sheet
        _confettiController.play();
        _showSuccessToast("Welcome back!");
        await _completeOnboarding(); // Save data and go home
      } else {
        setSheetState(() {
          isLoading = false;
          errorText = error;
        });
      }
    }

    Future<void> handleSendOtp(StateSetter setSheetState) async {
      final authService = context.read<AuthService>();
      setSheetState(() {
        isLoading = true;
        errorText = null;
      });

      try {
        final fullPhoneNumber = "+94${identifier.trim()}";
        await authService.sendOtpToPhone(context, fullPhoneNumber);
        setSheetState(() {
          isLoading = false;
        });
        if (mounted) {
          _showSuccessToast('OTP sent to your phone!');
        }
      } catch (e) {
        setSheetState(() {
          isLoading = false;
          errorText = e.toString();
        });
      }
    }

    Future<void> handleUseAnotherNumber(StateSetter setSheetState) async {
      Navigator.of(context).pop(); // Close bottom sheet
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 24.w,
                right: 24.w,
                top: 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Welcome Back!",
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "You already have an account with\n$identifier",
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),

                  if (isEmail) ...[
                    TextField(
                      controller: _loginPasswordController,
                      obscureText: obscureText,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        errorText: errorText,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setSheetState(() => obscureText = !obscureText),
                        ),
                      ),
                      onSubmitted: (_) => handleEmailLogin(setSheetState),
                    ),
                    SizedBox(height: 24.h),
                    StyledButton(
                      onPressed: () => handleEmailLogin(setSheetState),
                      text: "Log In & Continue",
                      isPrimary: true,
                      isLoading: isLoading,
                    ),
                  ],

                  if (!isEmail) ...[
                    if (errorText != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Text(
                          errorText!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    StyledButton(
                      onPressed: () => handleSendOtp(setSheetState),
                      text: "Send OTP to Login",
                      isPrimary: true,
                      isLoading: isLoading,
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      onChanged: (value) =>
                          setSheetState(() => _otpCode = value),
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: "Enter OTP",
                        hintText: "000000",
                      ),
                    ),
                    SizedBox(height: 16.h),
                    StyledButton(
                      onPressed: () => handlePhoneLogin(setSheetState),
                      text: "Verify OTP & Login",
                      isPrimary: false,
                      isLoading: false,
                    ),
                    SizedBox(height: 16.h),
                    TextButton(
                      onPressed: () => handleUseAnotherNumber(setSheetState),
                      child: const Text("Use Another Number to Register"),
                    ),
                  ],

                  SizedBox(height: 24.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _handleWillPop() async {
    if (_currentPage > 0) {
      await _prevPage();
      return false; // prevent screen from closing
    } else {
      if (mounted) {
        context.go(AppRouter.welcomePath);
      }
      return false; // We handle navigation ourselves
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pages = [
      LanguagePage(
        onLanguageSelected: (lang) {
          if (mounted) setState(() => _selectedAppLanguage = lang);
        },
        showError: _showLangError,
      ),
      MediumSelectionPage(
        onMediumSelected: (m) {
          if (mounted) setState(() => _selectedLearningMedium = m);
        },
        showError: _showMediumError,
      ),
      GradeSelectionPage(
        onGradesSelected: (g) {
          if (mounted) setState(() => _selectedGrades = g);
        },
      ),
      LocationPage(
        onProvinceSelected: (p) {
          if (mounted) setState(() => _province = p);
        },
        onDistrictSelected: (d) {
          if (mounted) setState(() => _district = d);
        },
        onCitySelected: (c) {
          if (mounted) setState(() => _city = c);
        },
        showError: _showCityError,
      ),
      GenderPage(
        onGenderSelected: (g) {
          if (mounted) setState(() => _selectedGender = g);
        },
        showError: _showGenderError,
      ),
      AgePage(
        onAgeSelected: (a) {
          if (mounted) setState(() => _selectedAge = a);
        },
        showError: _showAgeError,
      ),
      NameInputPage(
        onFirstNameChanged: (v) {
          if (mounted) setState(() => _firstName = v);
        },
        onLastNameChanged: (v) {
          if (mounted) setState(() => _lastName = v);
        },
        showNameError: _showNameError,
      ),
      _isGoogleRegistration
          ? GooglePhonePage(
              onMobileChanged: (v) {
                if (mounted) setState(() => _mobile = v);
              },
              showError: _showConnectError,
            )
          : ConnectAccountPage(
              onEmailChanged: (v) {
                if (mounted) setState(() => _email = v);
              },
              onMobileChanged: (v) {
                if (mounted) setState(() => _mobile = v);
              },
              onGoogleSignIn: _handleGoogleSignIn,
              showError: _showConnectError,
              isGoogleLoading: _isGoogleLoading,
            ),
      OnboardingOtpPage(
        phoneNumber: _mobile,
        onOtpChanged: (otp) {
          if (mounted) setState(() => _otpCode = otp);
        },
        showError: _showOtpError,
        onResendTapped: _handleResendOtp,
      ),
      CreatePasswordPage(
        onPasswordChanged: (v) {
          if (mounted) setState(() => _password = v);
        },
        onConfirmPasswordChanged: (v) {
          if (mounted) setState(() => _confirmPassword = v);
        },
        showError: _showPasswordError,
      ),
      LoginPromptPage(onLoginPrompt: _completeOnboarding),
    ];

    final totalPages = pages.length;
    final totalProgressSteps = totalPages - 1; // 9 steps (0-8)

    bool isContinueDisabled = false;
    if (_currentPage == 0 && _selectedAppLanguage == null) {
      isContinueDisabled = true;
    }
    if (_currentPage == 1 && _selectedLearningMedium == null) {
      isContinueDisabled = true;
    }
    if (_currentPage == 3 && _city == null) {
      isContinueDisabled = true;
    }
    if (_currentPage == 4 && _selectedGender == null) {
      isContinueDisabled = true;
    }
    if (_currentPage == 5 && _selectedAge == null) {
      isContinueDisabled = true;
    }
    if (_currentPage == 6 &&
        (_firstName.trim().isEmpty || _lastName.trim().isEmpty)) {
      isContinueDisabled = true;
    }
    if (_currentPage == 7) {
      if (_isGoogleRegistration) {
        if (_mobile.trim().length < 9) isContinueDisabled = true;
      } else {
        if (_email.trim().isEmpty || _mobile.trim().length < 9) {
          isContinueDisabled = true;
        }
      }
    }
    if (_currentPage == 8 && _otpCode.length < 6) {
      isContinueDisabled = true;
    }
    if (_currentPage == 9 &&
        (_password.length < 6 || _password != _confirmPassword)) {
      isContinueDisabled = true;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleWillPop();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
            onPressed: () {
              final result = _handleWillPop();
              result.then((shouldPop) {
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              });
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_currentPage < totalPages - 1)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / totalProgressSteps,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    color: theme.colorScheme.primary,
                    minHeight: 10.h,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: pages[index],
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.1),
                      blurRadius: 5.r,
                      offset: Offset(0, -3.h),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16.w),
                child: SafeArea(
                  top: false,
                  child: StyledButton(
                    onPressed: _nextPage,
                    text: _currentPage == totalPages - 1
                        ? "FINISH"
                        : "CONTINUE",
                    isDisabled: isContinueDisabled,
                    isLoading: _isContinueLoading,
                    isPrimary: true,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.2,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
