import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerHelpers {
  static Widget buildShimmerLoading(
    BuildContext context, {
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: child,
    );
  }

  static Widget buildShimmerRect({
    double? width,
    required double height,
    double borderRadius = 8.0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius.r),
      ),
    );
  }

  static Widget buildShimmerCircle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget buildShimmerListTile({bool hasTrailing = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          buildShimmerCircle(size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildShimmerRect(width: 120.w, height: 16.h),
                SizedBox(height: 8.h),
                buildShimmerRect(width: 180.w, height: 12.h),
              ],
            ),
          ),
          if (hasTrailing) ...[
            SizedBox(width: 16.w),
            buildShimmerRect(width: 24.w, height: 24.h),
          ],
        ],
      ),
    );
  }

  static Widget buildShimmerSectionTitle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
      child: buildShimmerRect(width: 100.w, height: 14.h),
    );
  }

  static Widget buildShimmerCard({required int itemCount}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Column(
            children: [
              buildShimmerListTile(),
              if (index < itemCount - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
