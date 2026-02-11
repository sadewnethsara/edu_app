import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:math/widgets/sort_bottom_sheet.dart';

class UnifiedSliverAppBar extends StatelessWidget {
  final String title;
  final bool isLoading;
  final Widget breadcrumb;
  final IconData backgroundIcon;
  final Function(String) onSortSelected;
  final String selectedSort;
  final VoidCallback? onBack;
  final VoidCallback? onHome;

  const UnifiedSliverAppBar({
    super.key,
    required this.title,
    required this.isLoading,
    required this.breadcrumb,
    required this.backgroundIcon,
    required this.onSortSelected,
    this.selectedSort = 'Newest',
    this.onBack,
    this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120.h,
      floating: true,
      snap: true,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      leadingWidth: 56.w,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left_outline,
          color: Colors.white,
          size: 24.sp,
        ),
        onPressed: onBack ?? () => context.pop(),
      ),
      actions: [
        isLoading
            ? Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Shimmer.fromColors(
                  baseColor: Colors.white.withValues(alpha: 0.3),
                  highlightColor: Colors.white.withValues(alpha: 0.6),
                  child: Container(
                    width: 35.w,
                    height: 35.w,
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              )
            : IconButton(
                icon: Icon(
                  Iconsax.sort_outline,
                  color: Colors.white,
                  size: 22.sp,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => SortBottomSheet(
                      currentSort: selectedSort,
                      onSortSelected: onSortSelected,
                    ),
                  );
                },
              ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.6),
                child: Container(
                  width: 180.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              )
            : Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0F172A), // Slate 900
                      const Color(0xFF000000), // Pure Black
                    ]
                  : [
                      const Color(0xFF0EA5E9), // Sky Blue
                      const Color(0xFF06B6D4), // Cyan
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative Icon
              Positioned(
                right: -30,
                bottom: -40,
                child: Icon(
                  backgroundIcon,
                  size: 180.sp,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              // Breadcrumb with Home Button
              Positioned(
                top: 50.h,
                left: 16.w,
                right: 16.w,
                child: SafeArea(
                  top: true,
                  child: isLoading
                      ? Shimmer.fromColors(
                          baseColor: Colors.white.withValues(alpha: 0.3),
                          highlightColor: Colors.white.withValues(alpha: 0.6),
                          child: Container(
                            width: 150.w,
                            height: 14.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            // Home Icon Button
                            InkWell(
                              onTap: onHome ?? () => context.go('/'),
                              borderRadius: BorderRadius.circular(20.r),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Iconsax.home_2_outline,
                                  size: 16.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Vertical Divider Line
                            Container(
                              width: 1.5,
                              height: 16.h,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            SizedBox(width: 8.w),
                            // Breadcrumb
                            Expanded(child: breadcrumb),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
