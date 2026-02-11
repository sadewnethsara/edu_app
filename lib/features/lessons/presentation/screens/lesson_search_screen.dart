import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:math/core/models/lesson_model.dart';
import 'package:math/core/models/grade_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/widgets/styled_button.dart';

class LessonSearchScreen extends StatefulWidget {
  const LessonSearchScreen({super.key});

  @override
  State<LessonSearchScreen> createState() => _LessonSearchScreenState();
}

class _LessonSearchScreenState extends State<LessonSearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  bool _isInitializing = true;
  List<LessonModel> _searchResults = [];

  // User's default settings
  String _selectedLanguage = 'en';
  String? _selectedGradeId;

  // Available options
  List<GradeModel> _availableGrades = [];
  final List<String> _availableLanguages = ['en', 'si', 'ta'];
  final Map<String, String> _languageNames = {
    'en': 'English',
    'si': 'Sinhala',
    'ta': 'Tamil',
  };

  // Filter states
  bool _filterAllGrades = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserSettings() async {
    setState(() => _isInitializing = true);

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

          setState(() {
            _selectedLanguage = language;
            _selectedGradeId = grades.isNotEmpty ? grades.first : null;
          });
        }
      }

      // Load available grades
      final allGrades = await _apiService.getGrades(_selectedLanguage);
      setState(() {
        _availableGrades = allGrades;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() => _isInitializing = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _apiService.searchLessons(query, _selectedLanguage);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        selectedGradeId: _selectedGradeId,
        selectedLanguage: _selectedLanguage,
        availableGrades: _availableGrades,
        availableLanguages: _availableLanguages,
        languageNames: _languageNames,
        filterAllGrades: _filterAllGrades,
        onApply: (gradeId, language, allGrades) {
          setState(() {
            _selectedGradeId = gradeId;
            _selectedLanguage = language;
            _filterAllGrades = allGrades;
          });
          _performSearch();
        },
      ),
    );
  }

  String _getGradeName() {
    if (_filterAllGrades) return 'All Grades';
    final grade = _availableGrades.firstWhere(
      (g) => g.id == _selectedGradeId,
      orElse: () => GradeModel(
        id: '',
        name: 'Select Grade',
        order: 0,
        description: '',
        isActive: true,
      ),
    );
    return grade.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : const Color(0xFF0B1C2C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search lessons...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          if (!_isInitializing)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            theme,
                            icon: Icons.school_rounded,
                            label: _getGradeName(),
                          ),
                          SizedBox(width: 8.w),
                          _buildFilterChip(
                            theme,
                            icon: Icons.language_rounded,
                            label:
                                _languageNames[_selectedLanguage] ?? 'English',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(
                      EvaIcons.options_2_outline,
                      color: theme.primaryColor,
                    ),
                    onPressed: _showFilterBottomSheet,
                    tooltip: 'Filter Options',
                  ),
                ],
              ),
            ),

          // Search Results
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: theme.primaryColor),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.search_rounded,
        title: 'Start Searching',
        subtitle: 'Type to search for lessons',
      );
    }

    if (_isLoading) {
      return _buildShimmerLoading(theme);
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.search_off_rounded,
        title: 'No Results Found',
        subtitle: 'Try adjusting your search or filters',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final lesson = _searchResults[index];
        return _buildLessonCard(theme, lesson);
      },
    );
  }

  Widget _buildEmptyState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80.sp, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 6,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonCard(ThemeData theme, LessonModel lesson) {
    return InkWell(
      onTap: () {
        // Navigate to lesson content
        // You'll need to pass gradeId and subjectId
        // For now, just pop back
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.book_rounded,
                color: theme.primaryColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    lesson.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final String? selectedGradeId;
  final String selectedLanguage;
  final List<GradeModel> availableGrades;
  final List<String> availableLanguages;
  final Map<String, String> languageNames;
  final bool filterAllGrades;
  final Function(String?, String, bool) onApply;

  const _FilterBottomSheet({
    required this.selectedGradeId,
    required this.selectedLanguage,
    required this.availableGrades,
    required this.availableLanguages,
    required this.languageNames,
    required this.filterAllGrades,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _selectedGradeId;
  late String _selectedLanguage;
  late bool _filterAllGrades;

  @override
  void initState() {
    super.initState();
    _selectedGradeId = widget.selectedGradeId;
    _selectedLanguage = widget.selectedLanguage;
    _filterAllGrades = widget.filterAllGrades;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : theme.primaryColor.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  Text(
                    'Filter Lessons',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  // Reset Button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterAllGrades = true;
                        _selectedGradeId = null;
                        _selectedLanguage = widget.selectedLanguage;
                      });
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Close Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey.shade700,
                      size: 24.sp,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
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

            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 4.0,
                radius: Radius.circular(8.r),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grade Section
                      _buildSectionTitle(context, 'Grade'),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: [
                          _buildFilterChip(
                            context,
                            'All Grades',
                            _filterAllGrades,
                            isDark,
                            () {
                              setState(() {
                                _filterAllGrades = true;
                                _selectedGradeId = null;
                              });
                            },
                          ),
                          ...widget.availableGrades.map((grade) {
                            final isSelected =
                                !_filterAllGrades &&
                                _selectedGradeId == grade.id;
                            return _buildFilterChip(
                              context,
                              grade.name,
                              isSelected,
                              isDark,
                              () {
                                setState(() {
                                  _filterAllGrades = false;
                                  _selectedGradeId = grade.id;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Language Section
                      _buildSectionTitle(context, 'Language'),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: widget.availableLanguages.map((lang) {
                          final isSelected = _selectedLanguage == lang;
                          return _buildFilterChip(
                            context,
                            widget.languageNames[lang] ?? lang,
                            isSelected,
                            isDark,
                            () {
                              setState(() => _selectedLanguage = lang);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Apply Button
            Padding(
              padding: EdgeInsets.all(20.w),
              child: StyledButton(
                onPressed: () {
                  widget.onApply(
                    _selectedGradeId,
                    _selectedLanguage,
                    _filterAllGrades,
                  );
                  Navigator.pop(context);
                },
                text: 'Apply Filters',
                isPrimary: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    // Define colors for 3D effect
    final faceColor = isSelected
        ? theme.primaryColor
        : isDark
        ? const Color(0xFF2D3748) // Dark grey for dark mode
        : const Color(0xFFF1F5F9); // Slate 100 for light mode

    final shadowColor = isSelected
        ? Color.lerp(theme.primaryColor, Colors.black, 0.3)! // Darker primary
        : isDark
        ? const Color(0xFF1A202C) // Darker grey for dark mode
        : const Color(0xFFE2E8F0); // Slate 200 for light mode

    final textColor = isSelected
        ? Colors.white
        : isDark
        ? Colors.white
        : Colors.black; // High contrast for visibility

    return Padding(
      padding: EdgeInsets.only(right: 12.w, bottom: 8.h),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: faceColor,
              border: Border(
                bottom: BorderSide(
                  color: shadowColor,
                  width: 4.h, // Thick bottom border for 3D effect
                ),
                top: BorderSide(
                  color: shadowColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                left: BorderSide(
                  color: shadowColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                right: BorderSide(
                  color: shadowColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
