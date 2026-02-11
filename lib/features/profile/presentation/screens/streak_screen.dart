import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/services/streak_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streakService = Provider.of<StreakService>(context);

    // Prepare data for the chart
    final List<BarChartGroupData> chartData = [];
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Get the last 7 days for the chart
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);

      // Check if this day is in the streak history
      final bool visited = streakService.streakHistory.any(
        (visit) => DateFormat('yyyy-MM-dd').format(visit) == dayStr,
      );

      chartData.add(
        BarChartGroupData(
          x: 6 - i, // 0 = 6 days ago, 6 = today
          barRods: [
            BarChartRodData(
              toY: visited ? 1 : 0, // 1 if visited, 0 if not
              color: visited ? theme.primaryColor : Colors.grey.shade300,
              width: 20.w,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: true,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140.h,
              floating: false,
              pinned: true,
              backgroundColor: Colors.orange,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Your Streak',
                  style: TextStyle(color: Colors.white),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange.shade600, Colors.orange.shade400],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 180.sp,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Current Streak Card ---
                    _buildCurrentStreakCard(theme, streakService.currentStreak),
                    SizedBox(height: 24.h),

                    // --- 7-Day History Graph ---
                    Text(
                      'Last 7 Days',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      height: 250.h,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 1.2, // Max Y (1.0) + padding
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final day = today.subtract(
                                    Duration(days: 6 - value.toInt()),
                                  );
                                  return Text(
                                    DateFormat('E').format(day),
                                    style: TextStyle(fontSize: 10.sp),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: chartData,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // --- How it works ---
                    _buildInfoCard(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStreakCard(ThemeData theme, int currentStreak) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: Colors.orange,
            size: 60.sp,
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$currentStreak Day${currentStreak == 1 ? "" : "s"}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Current Streak',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.primaryColor,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Streaks Work',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Visit the app every day to build your streak. You have a 7-day grace period to visit before your streak resets to zero.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
