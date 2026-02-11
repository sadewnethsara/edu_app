import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Removed
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/models/subtopic_model.dart';
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

class SubtopicsScreen extends StatefulWidget {
  final String gradeId;
  final String subjectId;
  final String lessonId;

  const SubtopicsScreen({
    super.key,
    required this.gradeId,
    required this.subjectId,
    required this.lessonId,
  });

  @override
  State<SubtopicsScreen> createState() => _SubtopicsScreenState();
}

class _SubtopicsScreenState extends State<SubtopicsScreen> {
  final ApiService _apiService = ApiService();
  List<SubtopicModel> _subtopics = [];
  List<SubtopicModel> _filteredSubtopics = [];
  bool _isLoading = true;
  String _selectedLanguage = 'en';
  String _lessonName = '';
  String _gradeName = '';
  String _subjectName = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubtopics();
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
      _loadSubtopics();
    }
  }

  Future<void> _loadSubtopics({bool forceRefresh = false}) async {
    try {
      logger.i(
        '🔍 SubtopicsScreen: Fetching for lesson=${widget.lessonId}, language=$_selectedLanguage',
      );

      // Define futures for parallel execution

      // 1. Grade Name Future
      final gradeNameFuture = FirebaseFirestore.instance
          .collection('curricula')
          .doc(_selectedLanguage)
          .collection('grades')
          .doc(widget.gradeId)
          .get();

      // 2. Subject Name Future
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

      // 3. Lesson Name Future
      final lessonNameFuture = () async {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('grades')
            .doc(widget.gradeId)
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('lessons')
            .doc(widget.lessonId)
            .get();

        if (!doc.exists) {
          doc = await FirebaseFirestore.instance
              .collection('curricula')
              .doc(_selectedLanguage)
              .collection('grades')
              .doc(widget.gradeId)
              .collection('subjects')
              .doc(widget.subjectId)
              .collection('lessons')
              .doc(widget.lessonId)
              .get();
        }
        return doc;
      }();

      // 4. Subtopics List Future
      final subtopicsFuture = _apiService.getSubtopics(
        widget.gradeId,
        widget.subjectId,
        widget.lessonId,
        _selectedLanguage,
        forceRefresh: forceRefresh,
      );

      // Execute in parallel
      final results = await Future.wait([
        gradeNameFuture,
        subjectNameFuture,
        lessonNameFuture,
        subtopicsFuture,
      ]);

      if (!mounted) return;

      final gradeDoc = results[0] as DocumentSnapshot;
      final subjectDoc = results[1] as DocumentSnapshot;
      final lessonDoc = results[2] as DocumentSnapshot;
      final subtopics = results[3] as List<SubtopicModel>;

      // Process Grade Name
      if (gradeDoc.exists) {
        _gradeName = gradeDoc.data() is Map
            ? ((gradeDoc.data() as Map<String, dynamic>)['name'] ?? 'Grade')
            : 'Grade';
      } else {
        _gradeName =
            'Grade ${widget.gradeId.replaceAll(RegExp(r'[^0-9]'), '')}';
      }

      // Process Subject Name
      if (subjectDoc.exists) {
        _subjectName =
            (subjectDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Subject';
      }

      // Process Lesson Name
      if (lessonDoc.exists) {
        _lessonName =
            (lessonDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Lesson';
      }

      setState(() {
        _subtopics = subtopics;
        _filteredSubtopics = subtopics;
        _isLoading = false;
        _sortSubtopics();
      });
    } catch (e) {
      logger.e('Error loading subtopics', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _selectedSort = 'Newest';

  void _sortSubtopics() {
    setState(() {
      switch (_selectedSort) {
        case 'A-Z':
          _filteredSubtopics.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Z-A':
          _filteredSubtopics.sort((a, b) => b.name.compareTo(a.name));
          break;
        case 'Newest':
          _filteredSubtopics.sort((a, b) => b.order.compareTo(a.order));
          break;
        case 'Oldest':
          _filteredSubtopics.sort((a, b) => a.order.compareTo(b.order));
          break;
      }
    });
  }

  void _filterSubtopics(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubtopics = List.from(_subtopics);
      } else {
        _filteredSubtopics = _subtopics
            .where(
              (subtopic) =>
                  subtopic.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
      _sortSubtopics();
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
          onRefresh: () => _loadSubtopics(forceRefresh: true),
          color: Theme.of(context).primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              UnifiedSliverAppBar(
                title: _lessonName,
                isLoading: _isLoading,
                backgroundIcon: Icons.topic_rounded,
                breadcrumb: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/subjects/${widget.gradeId}'),
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
                    Text(
                      ' / ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.sp,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.pop(),
                      child: Text(
                        _subjectName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                selectedSort: _selectedSort,
                onSortSelected: (value) {
                  setState(() {
                    _selectedSort = value;
                  });
                  _sortSubtopics();
                },
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: _isLoading
                    ? const SearchBarShimmer()
                    : SearchBarWidget(
                        hintText: 'Search subtopics...',
                        controller: _searchController,
                        onChanged: _filterSubtopics,
                        onClear: () => _filterSubtopics(''),
                      ),
              ),

              // Content
              _isLoading
                  ? const ContentListShimmer(itemHeight: 140)
                  : _filteredSubtopics.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.topic_outlined,
                      title: 'No Subtopics Available',
                      subtitle: 'Subtopics for this lesson will appear here.',
                    )
                  : SliverPadding(
                      padding: EdgeInsets.all(20.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final subtopic = _filteredSubtopics[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: CurriculumItemCard(
                              name: subtopic.name,
                              description: subtopic.description,
                              order: subtopic.order,
                              type: CurriculumItemType.subtopic,
                              contentBadges:
                                  subtopic.contentCounts != null &&
                                      (subtopic.contentCounts!.videos > 0 ||
                                          subtopic.contentCounts!.notes > 0 ||
                                          subtopic.contentCounts!.contentPdfs >
                                              0 ||
                                          subtopic.contentCounts!.resources > 0)
                                  ? SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          if (subtopic.contentCounts!.videos >
                                              0)
                                            ContentCountBadge(
                                              icon: Icons.videocam_rounded,
                                              count: subtopic
                                                  .contentCounts!
                                                  .videos,
                                              color: Colors.red,
                                            ),
                                          if (subtopic.contentCounts!.notes >
                                              0) ...[
                                            SizedBox(width: 8.w),
                                            ContentCountBadge(
                                              icon: Icons.description_rounded,
                                              count:
                                                  subtopic.contentCounts!.notes,
                                              color: Colors.blue,
                                            ),
                                          ],
                                          if (subtopic
                                                  .contentCounts!
                                                  .contentPdfs >
                                              0) ...[
                                            SizedBox(width: 8.w),
                                            ContentCountBadge(
                                              icon:
                                                  Icons.picture_as_pdf_rounded,
                                              count: subtopic
                                                  .contentCounts!
                                                  .contentPdfs,
                                              color: Colors.orange,
                                            ),
                                          ],
                                          if (subtopic
                                                  .contentCounts!
                                                  .resources >
                                              0) ...[
                                            SizedBox(width: 8.w),
                                            ContentCountBadge(
                                              icon: Icons.folder_rounded,
                                              count: subtopic
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
                                '/subjects/${widget.gradeId}/${widget.subjectId}/lessons/${widget.lessonId}/subtopics/${subtopic.id}',
                              ),
                            ),
                          );
                        }, childCount: _filteredSubtopics.length),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
