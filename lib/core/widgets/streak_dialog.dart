import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/services/streak_service.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

class StreakDialog extends StatelessWidget {
  const StreakDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakService>(
      builder: (context, streakService, child) {
        final bool streakLost = streakService.streakWasLost;
        final int streakCount = streakService.currentStreak;
        final int previousStreak = streakService.previousStreak;

        // --- Compute week days ---
        final Set<int> weekLoginDays = {};
        final today = DateTime.now();
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        final startOfWeekDate = DateUtils.dateOnly(startOfWeek);
        final endOfWeekDate = DateUtils.dateOnly(endOfWeek);

        for (final date in streakService.streakHistory) {
          final visitDate = DateUtils.dateOnly(date);
          if ((visitDate.isAtSameMomentAs(startOfWeekDate) ||
                  visitDate.isAfter(startOfWeekDate)) &&
              (visitDate.isAtSameMomentAs(endOfWeekDate) ||
                  visitDate.isBefore(endOfWeekDate))) {
            weekLoginDays.add(date.weekday);
          }
        }

        return Scaffold(
          backgroundColor: streakLost
              ? const Color(0xFF1A1C26)
              : const Color(0xFF0D0F14),
          body: SafeArea(
            top: false,
            bottom: true,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: streakLost
                      ? [const Color(0xFF2A2D3A), const Color(0xFF1A1C26)]
                      : [
                          const Color(0xFFF76B1C).withValues(alpha: 0.25),
                          const Color(0xFF1A2025),
                          const Color(0xFF0D0F14),
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // 🔥 Centered Content (No Scroll)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 24.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Fire Icon
                          FadeInDown(
                            duration: const Duration(milliseconds: 400),
                            child: Container(
                              width: 120.w,
                              height: 120.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: streakLost
                                      ? [
                                          Colors.grey.withValues(alpha: 0.3),
                                          Colors.transparent,
                                        ]
                                      : [
                                          const Color(
                                            0xFFF76B1C,
                                          ).withValues(alpha: 0.4),
                                          Colors.transparent,
                                        ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.local_fire_department_rounded,
                                  color: streakLost
                                      ? Colors.grey.shade600
                                      : const Color(0xFFF76B1C),
                                  size: 80.sp,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // Title
                          FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              streakLost
                                  ? "Streak Lost"
                                  : "🔥 You're On Fire! 🔥",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(height: 12.h),

                          // Streak Counter
                          ZoomIn(
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32.w,
                                vertical: 16.h,
                              ),
                              decoration: BoxDecoration(
                                color: streakLost
                                    ? Colors.grey.shade800.withValues(
                                        alpha: 0.4,
                                      )
                                    : const Color(
                                        0xFFF76B1C,
                                      ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(
                                  color: streakLost
                                      ? Colors.grey.shade700
                                      : const Color(
                                          0xFFF76B1C,
                                        ).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "$streakCount",
                                    style: TextStyle(
                                      fontSize: 52.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    streakCount == 1
                                        ? "Day Streak"
                                        : "Days Streak",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey.shade300,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 24.h),

                          // Week Tracker
                          FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            child: Container(
                              padding: EdgeInsets.all(18.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "This Week",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 14.h),
                                  _buildWeekTracker(weekLoginDays),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 24.h),

                          // Message
                          FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: const Duration(milliseconds: 100),
                            child: Text(
                              streakLost
                                  ? "You reached a $previousStreak-day streak! A new one begins now — keep it going! 💪"
                                  : "Keep your fire alive! Log in every day to maintain your streak. 🔥",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 15.sp,
                                height: 1.4,
                              ),
                            ),
                          ),

                          SizedBox(height: 28.h),

                          // CTA Button
                          FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: const Duration(milliseconds: 200),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56.h,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: streakLost
                                        ? [
                                            Colors.grey.shade700,
                                            Colors.grey.shade800,
                                          ]
                                        : const [
                                            Color(0xFFF76B1C),
                                            Color(0xFFFF9800),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: streakLost
                                          ? Colors.black38
                                          : const Color(
                                              0xFFF76B1C,
                                            ).withValues(alpha: 0.4),
                                      blurRadius: 12.r,
                                      offset: Offset(0, 6.h),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16.r),
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Center(
                                      child: Text(
                                        streakLost
                                            ? "Start New Streak"
                                            : "Continue Learning",
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Close Button (Top Right)
                  Positioned(
                    top: 20.h,
                    right: 16.w,
                    child: SafeArea(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Week Tracker Row
  Widget _buildWeekTracker(Set<int> weekLoginDays) {
    final List<String> weekDays = ["M", "T", "W", "T", "F", "S", "S"];
    final int todayWeekday = DateTime.now().weekday;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final int currentDay = index + 1;
        final bool isToday = currentDay == todayWeekday;
        final bool isChecked = weekLoginDays.contains(currentDay);

        return _buildDayCircle(
          label: weekDays[index],
          isChecked: isChecked,
          isToday: isToday,
        );
      }),
    );
  }

  Widget _buildDayCircle({
    required String label,
    required bool isChecked,
    required bool isToday,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isToday
                ? Colors.white
                : isChecked
                ? Colors.grey.shade300
                : Colors.grey.shade600,
            fontSize: 13.sp,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 36.w,
          height: 36.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isChecked
                ? const LinearGradient(
                    colors: [Color(0xFFF76B1C), Color(0xFFFF9800)],
                  )
                : null,
            color: isChecked
                ? null
                : Colors.grey.shade800.withValues(alpha: 0.5),
            border: Border.all(
              color: isToday
                  ? Colors.white
                  : isChecked
                  ? const Color(0xFFF76B1C)
                  : Colors.grey.shade700,
              width: isToday ? 2.w : 1.4.w,
            ),
            boxShadow: isChecked
                ? [
                    BoxShadow(
                      color: const Color(0xFFF76B1C).withValues(alpha: 0.4),
                      blurRadius: 6.r,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isChecked
                ? Icon(Icons.check_rounded, color: Colors.white, size: 18.sp)
                : isToday
                ? Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
