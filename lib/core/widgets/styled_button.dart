import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StyledButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isPrimary;
  final bool isDisabled;
  final bool isLoading; // --- ADDED ---

  const StyledButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isPrimary = true,
    this.isDisabled = false,
    this.isLoading = false, // --- ADDED ---
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bool isEffectivelyDisabled = isDisabled || isLoading;

    final Color buttonColor = isEffectivelyDisabled
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : (isPrimary
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer);

    final Color textColor = isEffectivelyDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.6)
        : (isPrimary
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSecondaryContainer);

    final Color borderColor = isEffectivelyDisabled
        ? colorScheme.outlineVariant
        : (isPrimary ? colorScheme.primary : colorScheme.secondary);

    return ElevatedButton(
      onPressed: isEffectivelyDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor, // This color will be used by the indicator
        minimumSize: Size.fromHeight(56.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
          side: BorderSide(color: borderColor, width: 2.w),
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16.sp,
          letterSpacing: 0.2,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 24.h, // Constrain size of indicator
              height: 24.h,
              child: CircularProgressIndicator(
                strokeWidth: 3.w,
                color: textColor, // Use the button's text color
              ),
            )
          : Text(text, textAlign: TextAlign.center),
    );
  }
}
