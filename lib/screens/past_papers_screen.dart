import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';

import 'package:math/data/models/grade_model.dart';
import 'package:math/data/models/past_paper_model.dart';
import 'package:math/services/api_service.dart';
import 'package:math/widgets/filter_bottom_sheet.dart';
import 'package:math/widgets/sort_bottom_sheet.dart';
import 'package:math/widgets/search_bar_widget.dart';
import 'package:math/screens/past_paper_pdf_viewer_screen.dart';
import 'package:math/services/language_service.dart';
import 'package:math/services/logger_service.dart';
import 'package:math/widgets/standard_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class PastPapersScreen extends StatefulWidget {
  const PastPapersScreen({super.key});

  @override
  State<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends State<PastPapersScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<PastPaperModel> _papers = [];
  List<GradeModel> _availableGrades = [];
  bool _isLoading = true;
  bool _isLoadingGrades = true;
  String _selectedLanguage = 'en';
  String? _selectedGrade;
  String? _selectedYear;
  String _selectedPaperType = 'All'; // 🚀 ADDED
  String _selectedTerm = 'All'; // 🚀 ADDED
  List<String> _years = []; // 🚀 ADDED
  final List<String> _paperTypes = [
    'All',
    'Model Paper',
    'Past Paper',
    'Marking Scheme',
  ]; // 🚀 ADDED: Adjusted types based on context usually
  final List<String> _terms = [
    'All',
    '1st Term',
    '2nd Term',
    '3rd Term',
  ]; // 🚀 ADDED

  String _searchText = '';
  String _sortOrder = 'Newest'; // Newest, Oldest, A-Z, Z-A

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _loadAvailableGrades();
      if (_selectedGrade != null) {
        _loadPastPapers(_selectedGrade!);
      }
    }
  }

  Future<void> _loadUserLanguage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final learningMedium = userDoc.data()?['learningMedium'] as String?;
          if (learningMedium != null && mounted) {
            String languageCode = learningMedium;
            if (learningMedium.toLowerCase() == 'english') {
              languageCode = 'en';
            } else if (learningMedium.toLowerCase() == 'sinhala') {
              languageCode = 'si';
            }
            logger.i(
              '🌍 User learning medium: $learningMedium → Using language code: $languageCode',
            );
            setState(() => _selectedLanguage = languageCode);
          }
        }
      }
      await _loadAvailableGrades();
    } catch (e) {
      logger.e('Error loading user language', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvailableGrades() async {
    if (mounted) {
      setState(() => _isLoadingGrades = true);
    }
    try {
      final grades = await _apiService.getGrades(_selectedLanguage);
      logger.i(
        'Loaded ${grades.length} grades for language: $_selectedLanguage',
      );

      if (mounted) {
        setState(() {
          _availableGrades = grades;
          _isLoadingGrades = false;

          if (_selectedGrade == null && grades.isNotEmpty) {
            _selectedGrade = grades.first.id;
            logger.i('Auto-selected first grade: $_selectedGrade');
            _loadPastPapers(_selectedGrade!);
          } else {
            // If no grades, stop loading
            setState(() => _isLoading = false);
          }
        });
      }
    } catch (e) {
      logger.e('Error loading grades', error: e);
      if (mounted) {
        setState(() => _isLoadingGrades = false);
      }
    }
  }

  Future<void> _loadPastPapers(String gradeId) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      logger.i(
        '📚 Loading past papers for gradeId: $gradeId, language: $_selectedLanguage',
      );

      final papers = await _apiService.getPastPapers(
        gradeId,
        _selectedLanguage,
      );

      final gradeName = _availableGrades
          .firstWhere(
            (g) => g.id == gradeId,
            orElse: () => GradeModel(
              id: gradeId,
              name: 'Grade ${gradeId.replaceAll(RegExp(r'[^0-9]'), '')}',
              order: 0,
              description: '',
              isActive: true,
            ),
          )
          .name;
      logger.i('✅ Loaded ${papers.length} past papers for grade: $gradeName');

      if (mounted) {
        setState(() {
          _papers = papers;
          // Extract unique years
          _years = papers.map((p) => p.year.toString()).toSet().toList()
            ..sort((a, b) => b.compareTo(a)); // Newest first
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error loading past papers', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🚀 UPDATED: Filter logic now includes search, sorting, and advanced filters
  List<PastPaperModel> get _filteredPapers {
    List<PastPaperModel> papers = _papers;

    if (_selectedYear != null) {
      papers = papers
          .where((paper) => paper.year.toString() == _selectedYear)
          .toList();
    }

    if (_selectedPaperType != 'All') {
      // Assuming 'type' is a field in PastPaperModel or we filter by title convention if not exist
      // Since PastPaperModel might not have 'type', check if title contains it or ignore if not supported
      // If PastPaperModel has a type field:
      // papers = papers.where((p) => p.type == _selectedPaperType).toList();
      // If not, we rely on title matching:
      papers = papers
          .where((paper) => paper.title.contains(_selectedPaperType))
          .toList();
    }

    if (_selectedTerm != 'All') {
      // Similarly for term, assuming it's in title if not a field
      papers = papers
          .where(
            (paper) =>
                paper.term == _selectedTerm ||
                paper.title.contains(_selectedTerm),
          )
          .toList();
    }

    if (_searchText.isNotEmpty) {
      papers = papers
          .where((paper) => paper.title.toLowerCase().contains(_searchText))
          .toList();
    }

    // Apply sorting
    if (_sortOrder == 'Newest') {
      papers.sort((a, b) => b.year.compareTo(a.year));
    } else if (_sortOrder == 'Oldest') {
      papers.sort((a, b) => a.year.compareTo(b.year));
    } else if (_sortOrder == 'A-Z') {
      papers.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (_sortOrder == 'Z-A') {
      papers.sort(
        (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
    }

    return papers;
  }

  // Open PDF in-app
  void _openPdfInApp(String pdfUrl, String title) {
    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF URL not available')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PastPaperPdfViewerScreen(title: title, pdfUrl: pdfUrl),
      ),
    );
  }

  // 🚀 NEW: Bottom Sheet for Paper Actions
  void _showPaperActionModal(PastPaperModel paper) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PaperActionModal(
        paper: paper,
        onOpenPaper: () {
          Navigator.pop(context);
          _openPdfInApp(paper.fileUrl, paper.title);
        },
        onOpenAnswers: () {
          Navigator.pop(context);
          _openPdfInApp(paper.answerUrl ?? '', '${paper.title} - Answers');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finalFilteredPapers = _filteredPapers; // Cache list for build

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          // App Bar
          // Custom Header for Past Papers
          SliverAppBar(
            expandedHeight: 140.h,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.sort, color: Colors.white, size: 24.sp),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => SortBottomSheet(
                      currentSort: _sortOrder,
                      onSortSelected: (sort) {
                        setState(() {
                          _sortOrder = sort;
                        });
                      },
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 60.w, bottom: 16.h),
              title: Text(
                'Past Papers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.brightness == Brightness.dark
                        ? [
                            const Color(0xFF0F172A), // Slate 900
                            const Color(0xFF000000), // Pure Black
                          ]
                        : [
                            const Color(0xFF0EA5E9), // Sky Blue
                            const Color(0xFF06B6D4), // Cyan
                          ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative Icon
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.description_outlined,
                        size: 140.sp,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    // Vertical Grade Indicator on LEFT
                    Positioned(
                      left: 20.w,
                      bottom: 16.h,
                      top: 60.h,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Vertical Grade Text
                          RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              _availableGrades.isNotEmpty &&
                                      _selectedGrade != null
                                  ? _availableGrades
                                        .firstWhere(
                                          (g) => g.id == _selectedGrade,
                                          orElse: () => GradeModel(
                                            id: '',
                                            name: 'Grade',
                                            order: 0,
                                            description: '',
                                            isActive: true,
                                          ),
                                        )
                                        .name
                                        .toUpperCase()
                                  : 'GRADE',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Vertical Line
                          Container(
                            width: 2,
                            height: 32.h,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          /* UnifiedSliverAppBar(
            title: 'Past Papers',
            isLoading: _isLoading,
            backgroundIcon: Icons.description_outlined,
            breadcrumb: Text(
              _availableGrades.isNotEmpty && _selectedGrade != null
                  ? _availableGrades
                        .firstWhere(
                          (g) => g.id == _selectedGrade,
                          orElse: () => GradeModel(
                            id: '',
                            name: 'Grade',
                            order: 0,
                            description: '',
                            isActive: true,
                          ),
                        )
                        .name
                  : 'Grade',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selectedSort: _sortOrder,
            onSortSelected: (value) {
              setState(() {
                _sortOrder = value;
              });
              // Trigger sort logic if needed, e.g. re-sort list
              // Assuming _papers are sorted in build or elsewhere based on _sortOrder
            },
          ), */

          // Search Bar
          SliverToBoxAdapter(
            child: SearchBarWidget(
              hintText: 'Search papers by title...',
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  _searchText = query.toLowerCase();
                });
              },
              onClear: () {
                setState(() {
                  _searchText = '';
                });
              },
            ),
          ),

          // Active Filters
          if (_selectedYear != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: Row(
                  children: [
                    Chip(
                      label: Text('Year: $_selectedYear'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() => _selectedYear = null),
                      backgroundColor: theme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          _isLoading
              ? _buildShimmerList()
              : finalFilteredPapers.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _selectedGrade == null
                              ? 'Select a grade'
                              : 'No papers found',
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                        ),
                        if (_selectedGrade != null) ...[
                          SizedBox(height: 8.h),
                          Text(
                            _searchText.isNotEmpty
                                ? 'Try adjusting your search'
                                : 'Papers will appear here once uploaded',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final paper = finalFilteredPapers[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        // 🚀 UPDATED: Call modal on tap
                        child: _PastPaperCard(
                          paper: paper,
                          onTap: () => _showPaperActionModal(paper),
                        ),
                      );
                    }, childCount: finalFilteredPapers.length),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterBottomSheet,
        backgroundColor: theme.primaryColor,
        icon: const Icon(Iconsax.filter_outline, color: Colors.white),
        label: const Text(
          'Filter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return FilterBottomSheet(
            years: _years,
            paperTypes: _paperTypes,
            terms: _terms,
            grades: _availableGrades,
            selectedYear: _selectedYear,
            selectedPaperType: _selectedPaperType,
            selectedTerm: _selectedTerm,
            selectedGrade: _selectedGrade,
            onYearSelected: (year) {
              setModalState(() {
                setState(() => _selectedYear = year);
              });
            },
            onTypeSelected: (type) {
              setModalState(() {
                setState(() => _selectedPaperType = type);
              });
            },
            onTermSelected: (term) {
              setModalState(() {
                setState(() => _selectedTerm = term);
              });
            },
            onGradeSelected: (gradeId) {
              setModalState(() {
                setState(() {
                  _selectedGrade = gradeId;
                  _selectedYear = null;
                  if (gradeId != null) {
                    _loadPastPapers(gradeId);
                  }
                });
              });
            },
            onReset: () {
              setModalState(() {
                setState(() {
                  _selectedYear = null;
                  _selectedPaperType = 'All';
                  _selectedTerm = 'All';
                });
              });
            },
          );
        },
      ),
    );
  }

  // 🚀 --- NEW SHIMMER WIDGETS --- 🚀

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

  Widget _buildShimmerList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade900 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerPlaceholder(
                    width: 60.w,
                    height: 80.h,
                    borderRadius: 12.r,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerPlaceholder(
                          width: double.infinity,
                          height: 16.h,
                        ),
                        SizedBox(height: 8.h),
                        _buildShimmerPlaceholder(width: 100.w, height: 12.h),
                        SizedBox(height: 12.h),
                        _buildShimmerPlaceholder(
                          width: double.infinity,
                          height: 12.h,
                        ),
                        SizedBox(height: 6.h),
                        _buildShimmerPlaceholder(width: 200.w, height: 12.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: 5),
      ),
    );
  }
}

// --- FILTER CHIP WIDGET ---

// 🚀 --- NEW REDESIGNED CARD WIDGET --- 🚀

class _PastPaperCard extends StatelessWidget {
  final PastPaperModel paper;
  final VoidCallback onTap; // 🚀 Use this for the modal

  const _PastPaperCard({required this.paper, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          // 🚀 UPDATED: Dark mode visible color
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Visual
            Container(
              width: 80.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  bottomLeft: Radius.circular(16.r),
                ),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: theme.colorScheme.secondary,
                size: 32.sp,
              ),
            ),
            // Right Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      paper.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Year & Term
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12.sp,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          paper.year,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (paper.term != null) ...[
                          Text(
                            ' • ${paper.term}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Description
                    Text(
                      paper.description.isEmpty
                          ? 'No description available.'
                          : paper.description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.8,
                        ),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Tags (if available)
                    if (paper.tags != null && paper.tags!.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: paper.tags!.take(3).map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚀 --- NEW MODAL WIDGET --- 🚀

class _PaperActionModal extends StatelessWidget {
  final PastPaperModel paper;
  final VoidCallback onOpenPaper;
  final VoidCallback onOpenAnswers;

  const _PaperActionModal({
    required this.paper,
    required this.onOpenPaper,
    required this.onOpenAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasAnswers =
        paper.answerUrl != null && paper.answerUrl!.isNotEmpty;
    final isDark = theme.brightness == Brightness.dark;

    return StandardBottomSheet(
      title: paper.title,
      icon: Icons.description_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
            ).copyWith(bottom: 8.h),
            child: Row(
              children: [
                SizedBox(width: 36.w), // Align with title text
                Text(
                  '${paper.year}${paper.term != null ? " - ${paper.term}" : ""}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // "Open Paper" Button
                _buildActionButton(
                  context: context,
                  onPressed: onOpenPaper,
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Open Paper',
                  subtitle: 'View the question paper',
                  isPrimary: true,
                  isDark: isDark,
                ),

                SizedBox(height: 12.h),

                // "Open Answers" Button
                _buildActionButton(
                  context: context,
                  onPressed: hasAnswers ? onOpenAnswers : null,
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Open Answers',
                  subtitle: hasAnswers
                      ? 'View the marking scheme'
                      : 'Not available',
                  isPrimary: false,
                  isDark: isDark,
                  isDisabled: !hasAnswers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isPrimary,
    required bool isDark,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isPrimary
                ? theme.primaryColor.withValues(alpha: 0.1)
                : isDisabled
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.grey.shade50)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isPrimary
                  ? theme.primaryColor.withValues(alpha: 0.3)
                  : isDisabled
                  ? Colors.transparent
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200),
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? theme.primaryColor.withValues(alpha: 0.15)
                      : isDisabled
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.grey.shade100)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: isPrimary
                      ? theme.primaryColor
                      : isDisabled
                      ? Colors.grey
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey.shade700),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isPrimary
                            ? theme.primaryColor
                            : isDisabled
                            ? Colors.grey
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDisabled
                            ? Colors.grey.shade400
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDisabled)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isPrimary
                      ? theme.primaryColor
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400),
                  size: 16.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
