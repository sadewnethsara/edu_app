import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Firebase & State
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Routing & Utils
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:math/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

// UI Packages
import 'package:shimmer/shimmer.dart';
import 'package:icons_plus/icons_plus.dart';

// Data Models
import 'package:math/core/models/content_model.dart';
import 'package:math/core/models/grade_model.dart';
import 'package:math/core/models/lesson_model.dart';
import 'package:math/core/models/subject_model.dart';
import 'package:math/core/models/subtopic_model.dart';

// Services & Widgets
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/continue_learning_service.dart';
import 'package:math/core/router/app_router.dart'; // For static route paths

final logger = Logger();

class AllLessonsScreen extends StatefulWidget {
  const AllLessonsScreen({super.key});

  @override
  State<AllLessonsScreen> createState() => _AllLessonsScreenState();
}

class _AllLessonsScreenState extends State<AllLessonsScreen> {
  // --- STATE & CORE LOGIC ---

  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String _selectedLanguage = 'en';
  List<String> _userGradeIds = [];

  // Data structure: Map<GradeId, Map<SubjectId, List<Lessons>>>
  Map<String, Map<String, List<LessonModel>>> _lessonsData = {};
  Map<String, GradeModel> _gradesMap = {};
  Map<String, SubjectModel> _subjectsMap = {};

  // Caching maps
  final Map<String, Future<ContentCollection?>> _lessonContentFutures = {};
  final Map<String, Future<List<SubtopicModel>>> _subtopicFutures = {};
  final Map<String, Future<ContentCollection?>> _subtopicContentFutures = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          final language = data['learningMedium'] as String? ?? 'en';
          final grades = List<String>.from(data['grades'] ?? []);

          if (mounted) {
            _selectedLanguage = language;
            _userGradeIds = grades;
          }
          await _loadAllLessons(initialLoad: true);
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      logger.e('Error loading user data', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllLessons({bool initialLoad = false}) async {
    if (!initialLoad && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    if (_userGradeIds.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, Map<String, List<LessonModel>>> tempLessonsData = {};
      final Map<String, GradeModel> tempGradesMap = {};
      final Map<String, SubjectModel> tempSubjectsMap = {};

      final allGrades = await _apiService.getGrades(_selectedLanguage);
      for (var grade in allGrades) {
        if (_userGradeIds.contains(grade.id)) {
          tempGradesMap[grade.id] = grade;
        }
      }

      for (String gradeId in _userGradeIds) {
        if (!tempGradesMap.containsKey(gradeId)) continue;

        final subjects = await _apiService.getSubjects(
          gradeId,
          _selectedLanguage,
        );

        tempLessonsData[gradeId] = {};

        for (var subject in subjects) {
          tempSubjectsMap[subject.id] = subject;

          final lessons = await _apiService.getLessons(
            gradeId,
            subject.id,
            _selectedLanguage,
          );

          if (lessons.isNotEmpty) {
            tempLessonsData[gradeId]![subject.id] = lessons;
          }
        }
      }

      if (mounted) {
        setState(() {
          _lessonsData = tempLessonsData;
          _gradesMap = tempGradesMap;
          _subjectsMap = tempSubjectsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error loading lessons', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    _lessonContentFutures.clear();
    _subtopicFutures.clear();
    _subtopicContentFutures.clear();
    await _loadAllLessons();
  }

  Future<ContentCollection?> _getOrFetchLessonContent(
    String gradeId,
    String subjectId,
    String lessonId,
  ) {
    if (!_lessonContentFutures.containsKey(lessonId)) {
      _lessonContentFutures[lessonId] = _apiService.getLessonContent(
        gradeId,
        subjectId,
        lessonId,
        _selectedLanguage,
      );
    }
    return _lessonContentFutures[lessonId]!;
  }

  Future<List<SubtopicModel>> _getOrFetchSubtopics(
    String gradeId,
    String subjectId,
    String lessonId,
  ) {
    if (!_subtopicFutures.containsKey(lessonId)) {
      _subtopicFutures[lessonId] = _apiService.getSubtopics(
        gradeId,
        subjectId,
        lessonId,
        _selectedLanguage,
      );
    }
    return _subtopicFutures[lessonId]!;
  }

  Future<ContentCollection?> _getOrFetchSubtopicContent(
    String gradeId,
    String subjectId,
    String lessonId,
    String subtopicId,
  ) {
    if (!_subtopicContentFutures.containsKey(subtopicId)) {
      _subtopicContentFutures[subtopicId] = _apiService.getSubtopicContent(
        gradeId,
        subjectId,
        lessonId,
        subtopicId,
        _selectedLanguage,
      );
    }
    return _subtopicContentFutures[subtopicId]!;
  }

  int _getTotalLessonsCount() {
    int count = 0;
    for (var gradeData in _lessonsData.values) {
      for (var lessons in gradeData.values) {
        count += lessons.length;
      }
    }
    return count;
  }

  // --- MODAL & NAVIGATION ---

  Future<void> _launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      logger.e('Could not launch $url');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showContentActionModal(
    ContentItem item,
    List<ContentItem> contextList,
    String contentType,
    String parentName,
    String gradeId,
    String subjectId,
    String lessonId,
    String? subtopicId,
  ) {
    int currentIndex = contextList.indexWhere((i) => i.id == item.id);
    final continueService = Provider.of<ContinueLearningService>(
      context,
      listen: false,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ContentActionModal(
          item: item,
          contentType: contentType,
          onPlay: () {
            Navigator.pop(context); // Close modal
            const routePath = AppRouter.videoPlayerPath;

            final continueData = ContinueLearningData(
              gradeId: gradeId,
              subjectId: subjectId,
              lessonId: lessonId,
              subtopicId: subtopicId,
              item: item,
              contextList: contextList,
              contentType: contentType,
              parentName: parentName,
              routePath: routePath,
              startIndex: currentIndex,
            );
            continueService.setLastViewedItem(continueData);

            context.push(
              routePath,
              extra: {'playlist': contextList, 'startIndex': currentIndex},
            );
          },
          onOpen: () {
            Navigator.pop(context); // Close modal
            String routePath;
            if (contentType == 'notes') {
              routePath = AppRouter.noteViewerPath;
            } else {
              routePath = AppRouter.pdfViewerPath;
            }

            final continueData = ContinueLearningData(
              gradeId: gradeId,
              subjectId: subjectId,
              lessonId: lessonId,
              subtopicId: subtopicId,
              item: item,
              contextList: contextList,
              contentType: contentType,
              parentName: parentName,
              routePath: routePath,
              startIndex: currentIndex,
            );
            continueService.setLastViewedItem(continueData);

            context.push(
              routePath,
              extra: {'itemList': contextList, 'startIndex': currentIndex},
            );
          },
          onOpenExternal: () {
            Navigator.pop(context); // Close modal
            _launchExternalUrl(item.url);
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        );
        return SlideTransition(
          position: tween.animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: Theme.of(context).cardColor, // Status bar color fix
                child: SafeArea(bottom: false, child: child),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        // 🚀 SafeArea fix
        top: false,
        bottom: true,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverAppBar(
                expandedHeight: 120.h,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: isDark
                    ? Colors.black
                    : const Color(0xFF0B1C2C),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    l10n.lessons,
                    style: const TextStyle(
                      color: Colors.white,
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
                                const Color(0xFF0B1C2C),
                                const Color(0xFF0B1C2C).withValues(alpha: 0.8),
                              ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: -30,
                          top: -30,
                          child: Icon(
                            Iconsax.book_1_bold,
                            size: 160.sp,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Iconsax.document_text_outline,
                      color: Colors.white,
                    ),
                    onPressed: () => context.push(AppRouter.pastPapersPath),
                    tooltip: 'Past Papers',
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.search_normal_1_outline,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      context.push('/lesson-search');
                    },
                    tooltip: 'Search Lessons',
                  ),
                ],
              ),

              // Content
              if (_isLoading)
                _buildShimmerLoading()
              else if (_userGradeIds.isEmpty)
                _buildEmptyState(
                  l10n.noGradesAvailable,
                  l10n.selectYourGrades,
                  Iconsax.teacher_outline,
                  ElevatedButton.icon(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Iconsax.setting_2_outline),
                    label: Text(l10n.settings),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                )
              else if (_lessonsData.isEmpty)
                _buildEmptyState(
                  'No Lessons Available',
                  'Lessons will appear here once added',
                  Iconsax.book_outline,
                  null,
                )
              else
                _buildDataLoaded(theme),
            ],
          ),
        ),
      ),
    );
  }

  // --- EMPTY & LOADED STATES ---

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Widget? action,
  ) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80.sp, color: Colors.grey.shade400),
              SizedBox(height: 24.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[SizedBox(height: 24.h), action],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataLoaded(ThemeData theme) {
    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Glassmorphism Summary Card
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Iconsax.book_saved_bold,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Lessons',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${_getTotalLessonsCount()} Lessons',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 32.h),

          // Lessons by Grade
          ..._buildLessonsByGrade(theme, AppLocalizations.of(context)!),
          SizedBox(height: 80.h), // Bottom padding
        ]),
      ),
    );
  }

  // --- SHIMMER WIDGETS ---

  Widget _buildShimmerPlaceholder({
    double? width,
    required double height,
    double borderRadius = 12.0,
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

  Widget _buildShimmerLoading() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define shimmer colors explicitly for visibility
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerSummaryCard(),
                SizedBox(height: 32.h),
                ...List.generate(2, (index) => _buildShimmerGradeSection()),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildShimmerSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          SizedBox(width: 20.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100.w, height: 14.h, color: Colors.white),
              SizedBox(height: 8.h),
              Container(
                width: 140.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGradeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grade Header Shimmer
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 16.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 100.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ),
        _buildShimmerSubjectCard(),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildShimmerSubjectCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          // Subject Header
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120.w, height: 16.h, color: Colors.white),
                    SizedBox(height: 6.h),
                    Container(width: 80.w, height: 12.h, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
          // Fake Lesson Items
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 14.h,
                              color: Colors.white,
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              width: 100.w,
                              height: 10.h,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* Removed detailed shimmer tiles for cleaner loading state */

  // --- DATA BUILD WIDGETS ---

  List<Widget> _buildLessonsByGrade(ThemeData theme, AppLocalizations l10n) {
    List<Widget> widgets = [];
    for (var gradeId in _userGradeIds) {
      final gradeData = _lessonsData[gradeId];
      if (gradeData == null || gradeData.isEmpty) continue;
      final grade = _gradesMap[gradeId];
      if (grade == null) continue;
      widgets.add(_buildGradeSection(grade, gradeData, theme, l10n));
      widgets.add(SizedBox(height: 24.h));
    }
    return widgets;
  }

  Widget _buildGradeSection(
    GradeModel grade,
    Map<String, List<LessonModel>> subjectsData,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 16.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Iconsax.briefcase_bold,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                grade.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        ...subjectsData.entries.map((entry) {
          final subjectId = entry.key;
          final lessons = entry.value;
          final subject = _subjectsMap[subjectId];
          if (subject == null || lessons.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildSubjectCard(grade, subject, lessons, theme);
        }),
      ],
    );
  }

  Widget _buildSubjectCard(
    GradeModel grade,
    SubjectModel subject,
    List<LessonModel> lessons,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          children: [
            // Subject Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      _getSubjectIcon(subject.icon),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 17.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(
                              Iconsax.book_1_outline,
                              size: 14.sp,
                              color: theme.hintColor,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${lessons.length} Lessons',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lessons List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: lessons.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                indent: 20.w,
                endIndent: 20.w,
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return _buildLessonTile(grade, subject, lesson, theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTile(
    GradeModel grade,
    SubjectModel subject,
    LessonModel lesson,
    ThemeData theme,
  ) {
    final contentCounts = lesson.contentCounts;
    final hasContent =
        contentCounts != null &&
        (contentCounts.videos > 0 ||
            contentCounts.notes > 0 ||
            contentCounts.contentPdfs > 0 ||
            contentCounts.resources > 0);

    return ExpansionTile(
      key: PageStorageKey(lesson.id),
      tilePadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      shape: const Border(), // Remove default borders
      collapsedShape: const Border(),
      backgroundColor: theme.colorScheme.surfaceContainer.withValues(
        alpha: 0.5,
      ),
      collapsedBackgroundColor: Colors.transparent,

      // Leading Icon (Number)
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${lesson.order}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),

      // Title
      title: Text(
        lesson.name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),

      // Description (Subtitle)
      subtitle: lesson.description.isEmpty && !hasContent
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lesson.description.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      lesson.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (hasContent)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: [
                        if (contentCounts.videos > 0)
                          _buildContentBadge(
                            Iconsax.play_circle_bold,
                            '${contentCounts.videos}',
                            theme,
                          ),
                        if (contentCounts.notes > 0)
                          _buildContentBadge(
                            Iconsax.document_text_bold,
                            '${contentCounts.notes}',
                            theme,
                          ),
                        if (contentCounts.contentPdfs > 0)
                          _buildContentBadge(
                            Iconsax.document_normal_bold,
                            '${contentCounts.contentPdfs}',
                            theme,
                          ),
                        if (contentCounts.resources > 0)
                          _buildContentBadge(
                            Iconsax.folder_open_bold,
                            '${contentCounts.resources}',
                            theme,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
      trailing: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Iconsax.arrow_down_1_outline,
          size: 20.sp,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [_buildExpandedLessonContent(grade, subject, lesson, theme)],
    );
  }

  Widget _buildContentBadge(IconData icon, String count, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: theme.primaryColor),
          SizedBox(width: 4.w),
          Text(
            count,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSubjectIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'calculate':
      case 'calculator':
        return Iconsax.calculator_outline;
      case 'science':
        return Iconsax
            .monitor_outline; // Fallback or use a specific science icon if available
      case 'language':
      case 'book':
        return Iconsax.book_outline;
      case 'history':
        return Iconsax.scroll_outline; // Using scroll as history analogue
      case 'art':
        return Iconsax.brush_outline;
      case 'music':
        return Iconsax.music_bold;
      case 'sports':
        return Iconsax.activity_outline;
      default:
        return Iconsax.book_1_outline;
    }
  }

  Widget _buildExpandedLessonContent(
    GradeModel grade,
    SubjectModel subject,
    LessonModel lesson,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, left: 12.w, right: 12.w, bottom: 12.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder(
            future: _getOrFetchLessonContent(grade.id, subject.id, lesson.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.h),
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final content = snapshot.data;
              final hasContent = content != null && content.totalCount > 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.video_circle_outline,
                        size: 18.sp,
                        color: theme.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Lesson Content',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (!hasContent)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        'No content available',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.textTheme.bodyMedium?.color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        if (content.videos.isNotEmpty)
                          _buildContentItemsList(
                            'Videos',
                            Iconsax.play_circle_outline,
                            content.videos,
                            theme,
                            lesson.name,
                            grade.id,
                            subject.id,
                            lesson.id,
                            null,
                          ),
                        if (content.notes.isNotEmpty)
                          _buildContentItemsList(
                            'Notes',
                            Iconsax.note_text_outline,
                            content.notes,
                            theme,
                            lesson.name,
                            grade.id,
                            subject.id,
                            lesson.id,
                            null,
                          ),
                        if (content.contentPdfs.isNotEmpty)
                          _buildContentItemsList(
                            'PDFs',
                            Iconsax.document_normal_outline,
                            content.contentPdfs,
                            theme,
                            lesson.name,
                            grade.id,
                            subject.id,
                            lesson.id,
                            null,
                          ),
                        if (content.resources.isNotEmpty)
                          _buildContentItemsList(
                            'Resources',
                            Iconsax.folder_outline,
                            content.resources,
                            theme,
                            lesson.name,
                            grade.id,
                            subject.id,
                            lesson.id,
                            null,
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
          SizedBox(height: 16.h),
          Divider(height: 1, color: theme.dividerColor),
          SizedBox(height: 16.h),
          FutureBuilder(
            future: _getOrFetchSubtopics(grade.id, subject.id, lesson.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.h),
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final subtopics = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.task_square_outline,
                        size: 18.sp,
                        color: theme.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Subtopics',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${subtopics.length}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (subtopics.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        'No subtopics available',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.textTheme.bodyMedium?.color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      controller: ScrollController(keepScrollOffset: false),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: subtopics.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        return _buildSubtopicTile(
                          grade,
                          subject,
                          lesson,
                          subtopics[index],
                          theme,
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentItemsList(
    String title,
    IconData icon,
    List<ContentItem> items,
    ThemeData theme,
    String parentName,
    String gradeId,
    String subjectId,
    String lessonId,
    String? subtopicId,
  ) {
    String contentType = 'unknown';
    if (title == 'Videos') contentType = 'videos';
    if (title == 'Notes') contentType = 'notes';
    if (title == 'PDFs') contentType = 'contentPdfs';
    if (title == 'Resources') contentType = 'resources';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: theme.primaryColor),
              SizedBox(width: 6.w),
              Text(
                '$title (${items.length})',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...items.map((item) {
            final name = item.name.isNotEmpty
                ? item.name
                : (item.fileName ?? 'Untitled');
            return Padding(
              padding: EdgeInsets.only(left: 8.w, bottom: 4.h),
              child: InkWell(
                onTap: () {
                  _showContentActionModal(
                    item,
                    items,
                    contentType,
                    parentName,
                    gradeId,
                    subjectId,
                    lessonId,
                    subtopicId,
                  );
                },
                borderRadius: BorderRadius.circular(6.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16.sp,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubtopicTile(
    GradeModel grade,
    SubjectModel subject,
    LessonModel lesson,
    SubtopicModel subtopic,
    ThemeData theme,
  ) {
    final contentCounts = subtopic.contentCounts;
    final hasContent =
        contentCounts != null &&
        (contentCounts.videos > 0 ||
            contentCounts.notes > 0 ||
            contentCounts.contentPdfs > 0 ||
            contentCounts.resources > 0);

    return ExpansionTile(
      key: PageStorageKey(subtopic.id),
      tilePadding: EdgeInsets.all(10.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      backgroundColor: theme.primaryColor.withValues(alpha: 0.05),
      collapsedBackgroundColor: theme.scaffoldBackgroundColor,
      title: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                '${subtopic.order}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              subtopic.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 6.h, left: 42.w),
        child: (hasContent)
            ? Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: [
                  if (contentCounts.videos > 0)
                    _buildSmallContentBadge(
                      Iconsax.play_circle_outline,
                      '${contentCounts.videos}',
                      theme,
                    ),
                  if (contentCounts.notes > 0)
                    _buildSmallContentBadge(
                      Iconsax.note_text_outline,
                      '${contentCounts.notes}',
                      theme,
                    ),
                  if (contentCounts.contentPdfs > 0)
                    _buildSmallContentBadge(
                      Iconsax.document_normal_outline,
                      '${contentCounts.contentPdfs}',
                      theme,
                    ),
                  if (contentCounts.resources > 0)
                    _buildSmallContentBadge(
                      Iconsax.folder_outline,
                      '${contentCounts.resources}',
                      theme,
                    ),
                ],
              )
            : null,
      ),
      trailing: Icon(
        Iconsax.arrow_down_1_outline,
        size: 20.sp,
        color: theme.primaryColor,
      ),
      children: [
        _buildExpandedSubtopicContent(grade, subject, lesson, subtopic, theme),
      ],
    );
  }

  Widget _buildExpandedSubtopicContent(
    GradeModel grade,
    SubjectModel subject,
    LessonModel lesson,
    SubtopicModel subtopic,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, left: 12.w, right: 12.w, bottom: 12.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: FutureBuilder(
        future: _getOrFetchSubtopicContent(
          grade.id,
          subject.id,
          lesson.id,
          subtopic.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(12.h),
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final content = snapshot.data;
          final hasContent = content != null && content.totalCount > 0;

          if (!hasContent) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Text(
                'No content available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.textTheme.bodyMedium?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          List<Widget> contentWidgets = [];
          if (content.videos.isNotEmpty) {
            contentWidgets.add(
              _buildContentItemsList(
                'Videos',
                Icons.play_circle_outline,
                content.videos,
                theme,
                subtopic.name,
                grade.id,
                subject.id,
                lesson.id,
                subtopic.id,
              ),
            );
          }
          if (content.notes.isNotEmpty) {
            contentWidgets.add(
              _buildContentItemsList(
                'Notes',
                Icons.note_outlined,
                content.notes,
                theme,
                subtopic.name,
                grade.id,
                subject.id,
                lesson.id,
                subtopic.id,
              ),
            );
          }
          if (content.contentPdfs.isNotEmpty) {
            contentWidgets.add(
              _buildContentItemsList(
                'PDFs',
                Icons.picture_as_pdf_outlined,
                content.contentPdfs,
                theme,
                subtopic.name,
                grade.id,
                subject.id,
                lesson.id,
                subtopic.id,
              ),
            );
          }
          if (content.resources.isNotEmpty) {
            contentWidgets.add(
              _buildContentItemsList(
                'Resources',
                Icons.folder_outlined,
                content.resources,
                theme,
                subtopic.name,
                grade.id,
                subject.id,
                lesson.id,
                subtopic.id,
              ),
            );
          }

          return ListView.separated(
            controller: ScrollController(keepScrollOffset: false),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contentWidgets.length,
            itemBuilder: (context, index) => contentWidgets[index],
            separatorBuilder: (context, index) => SizedBox(height: 0.h),
          );
        },
      ),
    );
  }

  Widget _buildSmallContentBadge(IconData icon, String count, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: theme.primaryColor),
          SizedBox(width: 3.w),
          Text(
            count,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} // End of _AllLessonsScreenState

// --- MODAL WIDGET ---
class _ContentActionModal extends StatelessWidget {
  final ContentItem item;
  final String contentType;
  final VoidCallback onPlay;
  final VoidCallback onOpen;
  final VoidCallback onOpenExternal;

  const _ContentActionModal({
    required this.item,
    required this.contentType,
    required this.onPlay,
    required this.onOpen,
    required this.onOpenExternal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemName = item.name.isNotEmpty
        ? item.name
        : (item.fileName ?? 'Untitled');

    IconData icon;
    String buttonText;
    VoidCallback onPressed;

    switch (contentType) {
      case 'videos':
        icon = Icons.play_circle_fill_rounded;
        buttonText = 'Play Video';
        onPressed = onPlay;
        break;
      case 'notes':
        icon = Icons.note_alt_rounded;
        buttonText = 'Open Note';
        onPressed = onOpen;
        break;
      case 'contentPdfs':
        icon = Icons.picture_as_pdf_rounded;
        buttonText = 'Open PDF';
        onPressed = onOpen;
        break;
      case 'resources':
        icon = Icons.launch_rounded;
        buttonText = 'Open in External App';
        onPressed = onOpenExternal;
        break;
      default:
        icon = Icons.help_outline_rounded;
        buttonText = 'Open';
        onPressed = onOpenExternal;
    }

    final EdgeInsets modalPadding = EdgeInsets.symmetric(
      horizontal: 24.w,
      vertical: 20.h,
    ).copyWith(top: 24.h);

    final BorderRadius modalBorderRadius = BorderRadius.vertical(
      bottom: Radius.circular(20.r),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w).copyWith(top: 10.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: modalBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: modalPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thumbnail for video
              if (contentType == 'videos')
                Container(
                  width: double.infinity,
                  height: 180.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey.shade200,
                  ),
                  child: Builder(
                    builder: (context) {
                      String? thumbnailUrl = item.thumbnail;
                      if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
                        final youtubeRegex = RegExp(
                          r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
                        );
                        final match = youtubeRegex.firstMatch(item.url);
                        if (match != null) {
                          final videoId = match.group(1);
                          thumbnailUrl =
                              'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
                        }
                      }

                      return (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.videocam_rounded,
                                        size: 60.sp,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.videocam_rounded,
                                size: 60.sp,
                                color: Colors.grey.shade400,
                              ),
                            );
                    },
                  ),
                ),

              // Content Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: theme.primaryColor, size: 32.sp),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        if (item.description != null &&
                            item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Action Button
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.h),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
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
