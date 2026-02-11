import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Removed
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/models/subject_model.dart';
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

class SubjectsScreen extends StatefulWidget {
  final String gradeId;

  const SubjectsScreen({super.key, required this.gradeId});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final ApiService _apiService = ApiService();
  List<SubjectModel> _subjects = [];
  List<SubjectModel> _filteredSubjects = [];
  bool _isLoading = true;
  String _selectedLanguage = 'en';
  String _gradeName = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for language changes
    final currentLanguage = context
        .watch<LanguageService>()
        .locale
        .languageCode;
    if (currentLanguage != _selectedLanguage && !_isLoading) {
      _selectedLanguage = currentLanguage;
      _loadSubjects();
    }
  }

  Future<void> _loadSubjects({bool forceRefresh = false}) async {
    try {
      logger.i(
        '🔍 SubjectsScreen: Fetching for gradeId=${widget.gradeId}, language=$_selectedLanguage, forceRefresh=$forceRefresh',
      );

      // Parallelize fetching Grade Name and Subjects
      final results = await Future.wait([
        // 1. Fetch Grade Name
        FirebaseFirestore.instance
            .collection('curricula')
            .doc(_selectedLanguage)
            .collection('grades')
            .doc(widget.gradeId)
            .get(),
        // 2. Fetch Subjects
        _apiService.getSubjects(
          widget.gradeId,
          _selectedLanguage,
          forceRefresh: forceRefresh,
        ),
      ]);

      if (!mounted) return;

      final gradeDoc = results[0] as DocumentSnapshot;
      final subjects = results[1] as List<SubjectModel>;

      if (gradeDoc.exists) {
        _gradeName = gradeDoc.data() is Map
            ? ((gradeDoc.data() as Map<String, dynamic>)['name'] ?? 'Grade')
            : 'Grade';
      } else {
        _gradeName =
            'Grade ${widget.gradeId.replaceAll(RegExp(r'[^0-9]'), '')}';
      }

      logger.i('✅ SubjectsScreen: Grade found - $_gradeName');
      logger.i('📚 SubjectsScreen: Received ${subjects.length} subjects');

      setState(() {
        _subjects = subjects;
        _filteredSubjects = subjects;
        _isLoading = false;
        _sortSubjects();
      });
    } catch (e, stackTrace) {
      logger.e(
        '❌ SubjectsScreen: Error loading subjects',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _selectedSort = 'Newest';

  void _sortSubjects() {
    if (!mounted) return;
    setState(() {
      switch (_selectedSort) {
        case 'A-Z':
          _filteredSubjects.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Z-A':
          _filteredSubjects.sort((a, b) => b.name.compareTo(a.name));
          break;
        case 'Newest':
          _filteredSubjects.sort((a, b) => b.order.compareTo(a.order));
          break;
        case 'Oldest':
          _filteredSubjects.sort((a, b) => a.order.compareTo(b.order));
          break;
      }
    });
  }

  void _filterSubjects(String query) {
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredSubjects = List.from(_subjects);
      } else {
        _filteredSubjects = _subjects
            .where(
              (subject) =>
                  subject.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
      _sortSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: true,
        child: RefreshIndicator(
          onRefresh: () => _loadSubjects(forceRefresh: true),
          color: Theme.of(context).primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ... existing slivers ...
              UnifiedSliverAppBar(
                title: 'Subjects',
                isLoading: _isLoading,
                backgroundIcon: Icons.grid_view_rounded,
                breadcrumb: Text(
                  _gradeName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selectedSort: _selectedSort,
                onSortSelected: (value) {
                  setState(() {
                    _selectedSort = value;
                  });
                  _sortSubjects();
                },
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: _isLoading
                    ? const SearchBarShimmer()
                    : SearchBarWidget(
                        hintText: 'Search subjects...',
                        controller: _searchController,
                        onChanged: _filterSubjects,
                        onClear: () => _filterSubjects(''),
                      ),
              ),

              // Content
              _isLoading
                  ? const ContentListShimmer(itemHeight: 80)
                  : _filteredSubjects.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.inbox_rounded,
                      title: 'No Subjects Available',
                      subtitle: 'Subjects for this grade will appear here.',
                    )
                  : SliverPadding(
                      padding: EdgeInsets.all(20.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final subject = _filteredSubjects[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: CurriculumItemCard(
                              name: subject.name,
                              description: subject.description,
                              order: subject.order,
                              type: CurriculumItemType.subject,
                              iconName: subject.icon,
                              onTap: () => context.push(
                                '/subjects/${widget.gradeId}/${subject.id}',
                              ),
                            ),
                          );
                        }, childCount: _filteredSubjects.length),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
