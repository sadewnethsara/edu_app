import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/grade_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:shimmer/shimmer.dart';

class GradeSelectionPage extends StatefulWidget {
  final ValueChanged<List<String>> onGradesSelected;
  final ApiService? apiService;

  const GradeSelectionPage({
    super.key,
    required this.onGradesSelected,
    this.apiService,
  });

  @override
  State<GradeSelectionPage> createState() => _GradeSelectionPageState();
}

class _GradeSelectionPageState extends State<GradeSelectionPage> {
  late final ApiService _apiService;
  final List<String> _selectedGrades = [];
  List<GradeModel> _grades = [];
  bool _isLoading = true;
  final String _selectedLanguage = 'en'; // Default language

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final grades = await _apiService.getGrades(_selectedLanguage);

      if (grades.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _grades = grades.where((g) => g.isActive).toList();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _grades = _getDefaultGrades();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _grades = _getDefaultGrades();
        _isLoading = false;
      });
    }
  }

  List<GradeModel> _getDefaultGrades() {
    return List.generate(
      7,
      (index) => GradeModel(
        id: 'grade_${index + 6}',
        order: index + 1,
        name: 'Grade ${index + 6}',
        description: '',
        isActive: true,
      ),
    )..add(
      GradeModel(
        id: 'grade_13',
        order: 8,
        name: 'Grade 13 (A/L)',
        description: '',
        isActive: true,
      ),
    );
  }

  void _toggleGrade(String gradeId) {
    setState(() {
      _selectedGrades.clear();
      _selectedGrades.add(gradeId);
      widget.onGradesSelected(_selectedGrades);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedEmoji(
              AnimatedEmojis.bee,
              size: 80.sp,
              repeat: false,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "What is your current grade level?",
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            "Select the grade you need help with.",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40.h),

          Text(
            "Select your grade of focus",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 12.h),

          if (_isLoading)
            Wrap(
              spacing: 10.w,
              runSpacing: 8.h,
              children: List.generate(8, (index) => _buildShimmerChip()),
            )
          else if (_grades.isEmpty)
            Center(
              child: Text(
                "No grades available",
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            )
          else
            Wrap(
              spacing: 10.w,
              runSpacing: 8.h,
              children: _grades.map((grade) {
                final isSelected = _selectedGrades.contains(grade.id);
                return DuolingoGradeChip(
                  label: grade.name,
                  isSelected: isSelected,
                  onTap: () => _toggleGrade(grade.id),
                );
              }).toList(),
            ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildShimmerChip() {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.scaffoldBackgroundColor,
      child: Container(
        height: 44.h,
        width: 90.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.r),
        ),
      ),
    );
  }
}

class DuolingoGradeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const DuolingoGradeChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 3.0.w : 1.5.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.highlightColor.withValues(alpha: 0.4),
                    offset: Offset(0, 3.h),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: textTheme.bodyLarge?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}
