import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/grade_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:shimmer/shimmer.dart';

class GradeSelectionSheet extends StatefulWidget {
  final String? currentGradeId;
  final ValueChanged<GradeModel> onGradeSelected;

  const GradeSelectionSheet({
    super.key,
    this.currentGradeId,
    required this.onGradeSelected,
  });

  @override
  State<GradeSelectionSheet> createState() => _GradeSelectionSheetState();
}

class _GradeSelectionSheetState extends State<GradeSelectionSheet> {
  final ApiService _apiService = ApiService();
  List<GradeModel> _grades = [];
  bool _isLoading = true;
  final String _selectedLanguage = 'en'; // Defaults to English for fetch

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final grades = await _apiService.getGrades(_selectedLanguage);
      if (mounted) {
        setState(() {
          if (grades.isNotEmpty) {
            _grades = grades.where((g) => g.isActive).toList();
          } else {
            _grades = _getDefaultGrades();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _grades = _getDefaultGrades();
          _isLoading = false;
        });
      }
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Column(
                children: [
                  AnimatedEmoji(AnimatedEmojis.bee, size: 48.sp, repeat: false),
                  SizedBox(height: 8.h),
                  Text(
                    "Select Grade",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Choose your current grade level",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
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

            SizedBox(height: 12.h),

            Flexible(
              child: _isLoading
                  ? _buildShimmerGrid(isDark)
                  : RawScrollbar(
                      thumbColor: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                      thickness: 3.w,
                      radius: Radius.circular(10.r),
                      child: GridView.builder(
                        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: _grades.length,
                        itemBuilder: (context, index) {
                          final grade = _grades[index];
                          final isSelected = widget.currentGradeId == grade.id;
                          return _buildGradeChip(
                            context,
                            grade,
                            isSelected,
                            isDark,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 2.2,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  Widget _buildGradeChip(
    BuildContext context,
    GradeModel grade,
    bool isSelected,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => widget.onGradeSelected(grade),
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: isSelected
              ? Border(
                  left: BorderSide(color: colorScheme.primary, width: 4.w),
                  top: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  right: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  bottom: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                )
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  width: 1.0,
                ),
          boxShadow: [
            if (isSelected && !isDark)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            grade.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? colorScheme.primary
                  : theme.textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
