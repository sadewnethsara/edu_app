import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/models/grade_model.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/app_usage_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/services/continue_learning_service.dart';
import 'package:math/core/services/language_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:math/core/services/streak_service.dart';
import 'package:math/core/widgets/streak_dialog.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:math/core/widgets/live_event_card.dart';
import 'package:math/core/models/live_event_model.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final ApiService _apiService = ApiService();
  List<GradeModel> _grades = [];
  bool _isLoading = true;
  String _selectedLanguage = 'en';

  // State Variables
  int _totalLessonsCount = 0;
  int _totalPoints = 0;
  double _completionPercent = 0.0;
  List<String> _userGradeIds = [];
  Timer? _usageTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemNavBarColor();
      Provider.of<AppUsageService>(context, listen: false).initialize();
      Provider.of<ContinueLearningService>(context, listen: false).initialize();
      _syncAndCheckStreak();
      _loadUserStatsAndGrades();
      _startUsageTimer();
    });
  }

  void _updateSystemNavBarColor() {
    if (!mounted) return;
    final theme = Theme.of(context);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _usageTimer?.cancel();
    super.dispose();
  }

  void _startUsageTimer() {
    _usageTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      Provider.of<AppUsageService>(context, listen: false).incrementUsage(30);
    });
  }

  Future<void> _loadUserStatsAndGrades() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      int totalCount = 0;
      int userPoints = 0;
      double userCompletion = 0.0;
      List<String> userGrades = [];
      String learningMedium = 'en';

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          learningMedium = data['learningMedium'] as String? ?? 'en';
          userGrades = List<String>.from(data['grades'] ?? []);
          userPoints = data['points'] as int? ?? 0;
          userCompletion =
              (data['completionPercent'] as num?)?.toDouble() ?? 0.0;
        }
      }

      if (mounted) {
        setState(() {
          _selectedLanguage = learningMedium;
          _userGradeIds = userGrades;
        });
      }

      final allGrades = await _apiService.getGrades(_selectedLanguage);

      if (_userGradeIds.isNotEmpty) {
        for (String gradeId in _userGradeIds) {
          if (allGrades.any((g) => g.id == gradeId)) {
            final subjects = await _apiService.getSubjects(
              gradeId,
              _selectedLanguage,
            );
            for (var subject in subjects) {
              final lessons = await _apiService.getLessons(
                gradeId,
                subject.id,
                _selectedLanguage,
              );
              totalCount += lessons.length;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _grades = allGrades
              .where((g) => _userGradeIds.contains(g.id))
              .toList();
          _totalLessonsCount = totalCount;
          _totalPoints = userPoints;
          _completionPercent = userCompletion;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      logger.e('Error loading user stats/grades', error: e, stackTrace: s);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAndCheckStreak() async {
    final streakService = Provider.of<StreakService>(context, listen: false);
    await streakService.syncFromFirebase();
    final status = await streakService.updateStreakOnAppOpen();

    if (mounted &&
        (status == StreakUpdateStatus.streakIncreased ||
            status == StreakUpdateStatus.streakLost)) {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StreakDialog(),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _onRefresh() async {
    await _loadUserStatsAndGrades();
    await _syncAndCheckStreak();
    if (mounted)
      await Provider.of<ContinueLearningService>(
        context,
        listen: false,
      ).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? _buildLoadingState(theme, isDark)
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: theme.primaryColor,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(context, theme, isDark),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickStats(theme, isDark),
                          _buildLiveEventsSection(theme, isDark),
                          _buildAcademicGradesSection(context, theme, isDark),
                          _buildContinueLearning(context, theme, isDark),
                          _buildDashboardChart(theme, isDark),
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- LIVE EVENTS SECTION ---
  Widget _buildLiveEventsSection(ThemeData theme, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_events')
          .orderBy('startTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final liveEvents = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          Timestamp? ts = data['startTime'] as Timestamp?;
          DateTime start = ts != null ? ts.toDate() : DateTime.now();

          Timestamp? linkEnableTs = data['linkEnableTime'] as Timestamp?;
          DateTime? linkEnable = linkEnableTs != null
              ? linkEnableTs.toDate()
              : null;

          return LiveEvent(
            title: data['title'] ?? 'No Title',
            description: data['description'] ?? '',
            link: data['link'] ?? '',
            startTime: start,
            linkEnableTime: linkEnable,
            isLive: data['isLive'] ?? false,
          );
        }).toList();

        return Padding(
          padding: EdgeInsets.only(top: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(theme, "LIVE EVENTS & MEETINGS", ""),
              SizedBox(height: 8.h),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: liveEvents.length,
                itemBuilder: (context, index) {
                  final event = liveEvents[index];
                  return FadeInRight(
                    delay: Duration(milliseconds: 200 * (index + 1)),
                    child: LiveEventCard(
                      event: event,
                      isDark: isDark,
                      theme: theme,
                      onJoin: () =>
                          _showExternalLinkBottomSheet(context, event.link),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExternalLinkBottomSheet(BuildContext context, String urlString) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border(
            top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
          ),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.global_bold,
                size: 32.sp,
                color: theme.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Leave App?",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "You are about to open an external link. Do you want to continue?",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.link_1_outline,
                    size: 18.sp,
                    color: theme.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      urlString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final Uri url = Uri.parse(urlString);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not launch $urlString'),
                            ),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), Colors.black]
                : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32.r),
            bottomRight: Radius.circular(32.r),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.push(AppRouter.profilePath),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28.r,
                  backgroundColor: theme.primaryColor,
                  backgroundImage: user?.photoURL != null
                      ? CachedNetworkImageProvider(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Iconsax.user_outline, color: Colors.white)
                      : null,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    user?.displayName?.split(' ')[0] ?? 'Scholar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, bool isDark) {
    final streak = Provider.of<StreakService>(context).currentStreak;
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: _buildGlassStat(
              theme,
              Iconsax.book_outline,
              "$_totalLessonsCount",
              "Lessons",
              Colors.blue,
              onTap: () {
                final continueService = Provider.of<ContinueLearningService>(
                  context,
                  listen: false,
                );
                final data = continueService.lastViewedData;
                if (data != null) {
                  Map<String, dynamic> extra =
                      data.routePath == AppRouter.videoPlayerPath
                      ? {
                          'playlist': data.contextList,
                          'startIndex': data.startIndex,
                        }
                      : {
                          'itemList': data.contextList,
                          'startIndex': data.startIndex,
                        };
                  context.push(data.routePath, extra: extra);
                } else {
                  context.push(AppRouter.allLessonsPath);
                }
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildGlassStat(
              theme,
              Iconsax.flash_outline,
              "$streak",
              "Streak",
              Colors.orange,
              onTap: () => context.push(AppRouter.streakPath),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildGlassStat(
              theme,
              Iconsax.award_outline,
              "${_completionPercent.toStringAsFixed(0)}%",
              "Done",
              Colors.green,
              onTap: () => context.push(AppRouter.leaderboardPath),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStat(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color, {
    required VoidCallback onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: theme.disabledColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardChart(ThemeData theme, bool isDark) {
    return Consumer<AppUsageService>(
      builder: (context, usageService, _) {
        final List<FlSpot> spots = [];
        final Map<String, int> data = usageService.weeklyUsage;
        final now = DateTime.now();

        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final seconds = data[dateStr] ?? 0;
          spots.add(
            FlSpot((6 - i).toDouble(), (seconds / 60).toDouble()),
          ); // Minutes
        }

        return FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: Container(
            height: 260.h,
            margin: EdgeInsets.only(top: 24.h),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Weekly Learning Activity",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Minutes spent daily",
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Iconsax.trend_up_outline,
                        size: 16.sp,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              if (value < 0 || value >= days.length)
                                return const SizedBox.shrink();
                              return Text(
                                days[value.toInt()],
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: theme.disabledColor,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text(
                              "${value.toInt()}m",
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: theme.disabledColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: theme.primaryColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: theme.primaryColor,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.primaryColor.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toInt()} mins',
                                TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicGradesSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_grades.length > 1)
            FadeInRight(
              delay: const Duration(milliseconds: 600),
              child: _buildSectionHeader(
                theme,
                "MY ACADEMIC PATH",
                _grades.length > 1 ? "Slide to view more" : "",
              ),
            )
          else if (_grades.isNotEmpty)
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _buildSectionHeader(
                theme,
                "MY ACADEMIC PATH",
                _grades.length > 1 ? "Slide to view more" : "",
              ),
            ),
          SizedBox(height: 16.h),
          if (_grades.length > 1)
            FadeInRight(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                height: 140.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _grades.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: _GradeCard(
                        grade: _grades[index],
                        onTap: () =>
                            context.push('/subjects/${_grades[index].id}'),
                      ),
                    );
                  },
                ),
              ),
            )
          else if (_grades.isNotEmpty)
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _GradeCard(
                grade: _grades[0],
                fullWidth: true,
                onTap: () => context.push('/subjects/${_grades[0].id}'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.sp, color: theme.disabledColor),
          ),
      ],
    );
  }

  Widget _buildContinueLearning(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final continueService = Provider.of<ContinueLearningService>(context);
    final data = continueService.lastViewedData;
    if (data == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: FadeInUp(
        delay: const Duration(milliseconds: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, "RESUME SESSION", ""),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), Colors.black]
                      : [const Color(0xFFF8FAFC), Colors.white],
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  Map<String, dynamic> extra =
                      data.routePath == AppRouter.videoPlayerPath
                      ? {
                          'playlist': data.contextList,
                          'startIndex': data.startIndex,
                        }
                      : {
                          'itemList': data.contextList,
                          'startIndex': data.startIndex,
                        };
                  context.push(data.routePath, extra: extra);
                },
                borderRadius: BorderRadius.circular(24.r),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Icon(
                          Iconsax.play_circle_outline,
                          color: theme.primaryColor,
                          size: 28.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.item.name,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "Picked up where you left off",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: theme.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.arrow_right_3_outline,
                        size: 20.sp,
                        color: theme.disabledColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 200.h, color: Colors.white),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (i) => Expanded(
                        child: Container(
                          height: 80.h,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    height: 240.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    height: 140.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final GradeModel grade;
  final VoidCallback onTap;
  final bool fullWidth;

  const _GradeCard({
    required this.grade,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: fullWidth ? double.infinity : 180.w,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Iconsax.book_1_outline,
                  color: theme.primaryColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      grade.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Mathematics",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
