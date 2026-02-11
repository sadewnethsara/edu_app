import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';

class OnboardingOtpPage extends StatefulWidget {
  final String phoneNumber;
  final Function(String) onOtpChanged;
  final VoidCallback onResendTapped; // --- ADDED ---
  final bool showError;

  const OnboardingOtpPage({
    super.key,
    required this.phoneNumber,
    required this.onOtpChanged,
    required this.onResendTapped, // --- ADDED ---
    this.showError = false,
  });

  @override
  State<OnboardingOtpPage> createState() => _OnboardingOtpPageState();
}

class _OnboardingOtpPageState extends State<OnboardingOtpPage> {
  bool _isResending = false;

  Future<void> _onResend() async {
    setState(() => _isResending = true);
    try {
      widget.onResendTapped();
      // We don't set isResending=false here, we let the parent show a snackbar
      // and we just re-enable the button after a timeout to prevent spam.
      await Future.delayed(const Duration(seconds: 10));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- (All your Pinput theme code is correct, no changes there) ---
    final defaultPinTheme = PinTheme(
      width: 45.w,
      height: 56.h,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: theme.colorScheme.primary, width: 2.w),
      ),
    );
    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: theme.colorScheme.error, width: 2.w),
      ),
    );

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Verify Your Number",
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            "We've sent a 6-digit code to\n+94${widget.phoneNumber.replaceAll(' ', '')}",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48.h),
          Center(
            child: Pinput(
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              errorPinTheme: errorPinTheme,
              forceErrorState: widget.showError,
              onChanged: widget.onOtpChanged,
              onCompleted: widget.onOtpChanged,
            ),
          ),
          SizedBox(height: 24.h),
          if (widget.showError)
            Text(
              "Invalid code. Please try again.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 24.h),

          // --- RESEND BUTTON LOGIC ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive a code?",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isResending)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: _onResend, // Use the new handler
                  child: const Text("Resend Code"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
