import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart'; // 🚀 FIX 1: Added import
import 'package:math/core/services/app_usage_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AppUsageScreen extends StatelessWidget {
  const AppUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageService = Provider.of<AppUsageService>(context);

    // Prepare data for the chart
    final List<BarChartGroupData> chartData = [];
    final today = DateTime.now();
    double maxY = 0;

    // Get the last 7 days
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);
      final seconds = usageService.weeklyUsage[dayStr] ?? 0;
      final minutes = seconds / 60; // Convert to minutes

      if (minutes > maxY) {
        maxY = minutes;
      }

      chartData.add(
        BarChartGroupData(
          x: 6 - i, // 0 = 6 days ago, 6 = today
          barRods: [
            BarChartRodData(
              toY: minutes,
              color: (i == 0) ? theme.primaryColor : Colors.grey.shade400,
              width: 16.w,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      );
    }

    // Calculate max Y value cleanly
    final chartMaxY = (maxY < 50) ? 60.0 : (maxY * 1.2).ceilToDouble();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140.h,
              pinned: true,
              backgroundColor: theme.colorScheme.secondary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(), // 🚀 This will now work
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'App Analytics',
                  style: TextStyle(color: Colors.white),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.secondary,
                        theme.colorScheme.secondary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Icon(
                          Icons.insights_rounded,
                          size: 180.sp,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header ---
                    Text(
                      'Your Weekly Activity',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Usage breakdown for the last 7 days.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // --- Graph Container ---
                    Container(
                      height: 300.h,
                      padding: EdgeInsets.all(16.w).copyWith(top: 32.h),
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
                          maxY: chartMaxY,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.black87,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final minutes = rod.toY.toInt();
                                    return BarTooltipItem(
                                      '$minutes min',
                                      const TextStyle(color: Colors.white),
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35.w,
                                // 🚀 FIX 4: Simplified getTitlesWidget
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('');
                                  if (value == meta.max) {
                                    return Text(
                                      '${value.toInt()}m',
                                      style: TextStyle(fontSize: 10.sp),
                                    );
                                  }
                                  if (value % 30 == 0) {
                                    return Text(
                                      '${value.toInt()}m',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.grey.shade500,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30.h, // Make space for the text
                                getTitlesWidget: (value, meta) {
                                  final day = today.subtract(
                                    Duration(days: 6 - value.toInt()),
                                  );
                                  // 🚀 FIX 2: Removed problematic SideTitleWidget wrapper
                                  return Padding(
                                    padding: EdgeInsets.only(top: 8.h),
                                    child: Text(
                                      DateFormat('E').format(day),
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
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
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 30,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            ),
                          ),
                          barGroups: chartData,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // --- Analysis ---
                    Text(
                      'Performance Summary',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // 🚀 FIX 3: Passed usageService
                    _buildAnalysisCard(
                      context,
                      usageService, // Pass the service
                      'Today vs Yesterday',
                      usageService.todayUsageFormatted,
                      usageService.usagePercentageChange > 0.1
                          ? 'You increased activity by ${usageService.usagePercentageChange.toStringAsFixed(0)}%.'
                          : usageService.usagePercentageChange < -0.1
                          ? 'Activity decreased by ${usageService.usagePercentageChange.toStringAsFixed(0).replaceAll('-', '')}%. Try scheduling a lesson.'
                          : 'Usage is consistent, keep up the habit!',
                      usageService.usagePercentageChange > 0.1
                          ? Colors.green
                          : Colors.orange,
                    ),
                    SizedBox(height: 12.h),

                    // 🚀 FIX 3: Passed usageService
                    _buildAnalysisCard(
                      context,
                      usageService, // Pass the service
                      'Total Time Spent',
                      'Over 7 Days',
                      'This analysis will soon track your long-term consistency.',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 FIX 3: Added AppUsageService parameter
  Widget _buildAnalysisCard(
    BuildContext context,
    AppUsageService usageService,
    String title,
    String value,
    String comment,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border(
          left: BorderSide(color: color, width: 5.w),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  comment,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 🚀 FIX 4: Use the passed 'usageService' variable
              if (title == 'Today vs Yesterday')
                Text(
                  usageService.yesterdayUsageSeconds > 0
                      ? 'Total for Today'
                      : 'First day logged',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
