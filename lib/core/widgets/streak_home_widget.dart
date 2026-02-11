import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/services/streak_service.dart';
import 'package:provider/provider.dart';

class StreakHomeWidget extends StatelessWidget {
  const StreakHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to rebuild this widget when streak changes
    return Consumer<StreakService>(
      builder: (context, streakService, child) {
        // If data hasn't been synced from Firebase yet, show loading
        if (!streakService.isSynced) {
          // You can show a loading spinner, but this is less intrusive
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2025), // Dark background
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40.sp,
                  height: 40.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  "Loading streak...",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          );
        }

        // Data is loaded, show the real widget
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2025), // Dark background
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Take only needed space
            children: [
              // Flame Icon
              Icon(
                Icons.local_fire_department,
                color: (streakService.currentStreak > 0)
                    ? const Color(0xFFF76B1C) // Orange
                    : Colors.grey.shade600, // Greyed out if 0
                size: 40.sp,
              ),
              SizedBox(width: 16.w),

              // Streak Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streakService.currentStreak} day streak',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Way to go!",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
