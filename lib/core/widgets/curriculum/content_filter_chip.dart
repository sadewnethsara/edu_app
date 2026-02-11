import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Filter chip for content type filtering
class ContentFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ContentFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor
                : isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
