import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StandardBottomSheet extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final double? maxHeightMultiplier;
  final bool showDragHandle;
  final bool showDivider;
  final bool showScrollbar;
  final bool isContentScrollable;
  final EdgeInsetsGeometry? padding;

  const StandardBottomSheet({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.maxHeightMultiplier = 0.75,
    this.showDragHandle = true,
    this.showDivider = true,
    this.showScrollbar = true,
    this.isContentScrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * (maxHeightMultiplier ?? 0.85),
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : theme.primaryColor.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle)
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

            if (title != null)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 4.h, 12.w, 4.h),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 22.sp, color: theme.primaryColor),
                      SizedBox(width: 12.w),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    trailing ??
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 24.sp),
                          onPressed: () => Navigator.pop(context),
                          color: Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                  ],
                ),
              ),

            if (showDivider && title != null)
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
              ),

            if (isContentScrollable)
              Flexible(
                child: showScrollbar
                    ? RawScrollbar(
                        thumbColor: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                        thickness: 3.w,
                        radius: Radius.circular(10.r),
                        child: SingleChildScrollView(
                          padding: padding ?? EdgeInsets.zero,
                          child: child,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: padding ?? EdgeInsets.zero,
                        child: child,
                      ),
              )
            else
              Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ],
        ),
      ),
    );
  }
}
