import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/models/lesson_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/language_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:math/core/widgets/unified_sliver_app_bar.dart';
import 'package:math/core/widgets/search_bar_widget.dart';
import 'package:math/core/widgets/loading/search_bar_shimmer.dart';
import 'package:math/core/widgets/loading/content_list_shimmer.dart';
import 'package:math/core/widgets/states/empty_state_widget.dart';
import 'package:math/core/widgets/curriculum/curriculum_item_card.dart';
import 'package:math/core/widgets/curriculum/content_count_badge.dart';

class LessonsScreen extends StatefulWidget {
  final String gradeId;
  final String subjectId;

  const LessonsScreen({
    super.key,
    required this.gradeId,
    required this.subjectId,
  });

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final ApiService _apiService = ApiService();
  List<LessonModel> _lessons = [];
  List<LessonModel> _filteredLessons = [];
  bool _isLoading = true;
  String _selectedLanguage = 'en';
  String _subjectName = '';
  String _gradeName = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLanguage = context
        .watch<LanguageService>()
        .locale
        .languageCode;
    if (currentLanguage != _selectedLanguage && !_isLoading) {
      _selectedLanguage = currentLanguage;
      _loadLessons();
    }
  }

  Future<void> _loadLessons({bool forceRefresh = false}) async {
    try {
      logger.i(
        '🔍 LessonsScreen: Fetching for grade=${widget.gradeId}, subject=${widget.subjectId}, language=$_selectedLanguage',
      );

      final gradeNameFuture = FirebaseFirestore.instance
          .collection('curricula')
          .doc(_selectedLanguage)
          .collection('grades')
          .doc(widget.gradeId)
          .get();

      final subjectNameFuture = () async {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('grades')
            .doc(widget.gradeId)
            .collection('subjects')
            .doc(widget.subjectId)
            .get();

        if (!doc.exists) {
          doc = await FirebaseFirestore.instance
              .collection('curricula')
              .doc(_selectedLanguage)
              .collection('grades')
              .doc(widget.gradeId)
              .collection('subjects')
              .doc(widget.subjectId)
              .get();
        }
        return doc;
      }();

      final lessonsFuture = _apiService.getLessons(
        widget.gradeId,
        widget.subjectId,
        _selectedLanguage,
        forceRefresh: forceRefresh,
      );

      final results = await Future.wait([
        gradeNameFuture,
        subjectNameFuture,
        lessonsFuture,
      ]);

      if (!mounted) return;

      final gradeDoc = results[0] as DocumentSnapshot;
      final subjectDoc = results[1] as DocumentSnapshot;
      final lessons = results[2] as List<LessonModel>;

      if (gradeDoc.exists) {
        _gradeName = gradeDoc.data() is Map
            ? ((gradeDoc.data() as Map<String, dynamic>)['name'] ?? 'Grade')
            : 'Grade';
      } else {
        _gradeName =
            'Grade ${widget.gradeId.replaceAll(RegExp(r'[^0-9]'), '')}';
      }

      if (subjectDoc.exists) {
        final data = subjectDoc.data() as Map<String, dynamic>?;
        _subjectName = data?['name'] ?? 'Subject';
      }

      setState(() {
        _lessons = lessons;
        _filteredLessons = lessons;
        _isLoading = false;
        _sortLessons();
      });
    } catch (e) {
      logger.e('Error loading lessons', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _selectedSort = 'Newest';

  void _sortLessons() {
    if (!mounted) return;
    setState(() {
      switch (_selectedSort) {
        case 'A-Z':
          _filteredLessons.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Z-A':
          _filteredLessons.sort((a, b) => b.name.compareTo(a.name));
          break;
        case 'Newest':
          _filteredLessons.sort((a, b) => b.order.compareTo(a.order));
          break;
        case 'Oldest':
          _filteredLessons.sort((a, b) => a.order.compareTo(b.order));
          break;
      }
    });
  }

  void _filterLessons(String query) {
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredLessons = List.from(_lessons);
      } else {
        _filteredLessons = _lessons
            .where(
              (lesson) =>
                  lesson.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
      _sortLessons();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: RefreshIndicator(
          onRefresh: () => _loadLessons(forceRefresh: true),
          color: Theme.of(context).primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              UnifiedSliverAppBar(
                title: _subjectName,
                isLoading: _isLoading,
                backgroundIcon: Icons.menu_book_rounded,
                breadcrumb: InkWell(
                  onTap: () => context.pop(),
                  child: Text(
                    _gradeName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.sp,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                selectedSort: _selectedSort,
                onSortSelected: (value) {
                  setState(() {
                    _selectedSort = value;
                  });
                  _sortLessons();
                },
              ),

              SliverToBoxAdapter(
                child: _isLoading
                    ? const SearchBarShimmer()
                    : SearchBarWidget(
                        hintText: 'Search lessons...',
                        controller: _searchController,
                        onChanged: _filterLessons,
                        onClear: () => _filterLessons(''),
                      ),
              ),

              _isLoading
                  ? const ContentListShimmer(itemHeight: 100)
                  : _filteredLessons.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.inbox_rounded,
                      title: 'No Lessons Available',
                      subtitle: 'Lessons for this subject will appear here.',
                    )
                  : SliverPadding(
                      padding: EdgeInsets.all(20.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final lesson = _filteredLessons[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: CurriculumItemCard(
                              name: lesson.name,
                              description: lesson.description,
                              order: lesson.order,
                              type: CurriculumItemType.lesson,
                              contentBadges:
                                  lesson.contentCounts != null &&
                                      (lesson.contentCounts!.videos > 0 ||
                                          lesson.contentCounts!.notes > 0 ||
                                          lesson.contentCounts!.contentPdfs >
                                              0 ||
                                          lesson.contentCounts!.resources > 0)
                                  ? SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          if (lesson.contentCounts!.videos > 0)
                                            ContentCountBadge(
                                              icon: Icons.videocam_rounded,
                                              count:
                                                  lesson.contentCounts!.videos,
                                              color: Colors.red,
                                            ),
                                          if (lesson.contentCounts!.notes >
                                              0) ...[
                                            SizedBox(width: 8.w),
                                            ContentCountBadge(
                                              icon: Icons.description_rounded,
                                              count:
                                                  lesson.contentCounts!.notes,
                                              color: Colors.blue,
                                            ),
                                          ],
                                          if (lesson
                                                  .contentCounts!
                                                  .contentPdfs >
                                              0) ...[
                                            SizedBox(width: 8.w),
                                            ContentCountBadge(
                                              icon:
                                                  Icons.picture_as_pdf_rounded,
                                              count: lesson
                                                  .contentCounts!
                                                  .contentPdfs,
                                              color: Colors.orange,
                                            ),
                                          ],
                                          if (lesson.contentCounts!.resources >
                                              0) ...[
                                            SizedBox(width: 8.w),
                                            ContentCountBadge(
                                              icon: Icons.folder_rounded,
                                              count: lesson
                                                  .contentCounts!
                                                  .resources,
                                              color: Colors.green,
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  : null,
                              onTap: () => context.push(
                                '/subjects/${widget.gradeId}/${widget.subjectId}/lessons/${lesson.id}',
                              ),
                            ),
                          );
                        }, childCount: _filteredLessons.length),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
