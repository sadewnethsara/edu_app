import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/data/models/grade_model.dart';
import 'package:math/widgets/styled_button.dart'; // 🚀 IMPORTED

class FilterBottomSheet extends StatelessWidget {
  final List<String> years;
  final List<String> paperTypes;
  final List<String> terms;
  final List<GradeModel> grades;
  final String? selectedYear;
  final String selectedPaperType;
  final String selectedTerm;
  final String? selectedGrade;
  final Function(String?) onYearSelected;
  final Function(String) onTypeSelected;
  final Function(String) onTermSelected;
  final Function(String?) onGradeSelected;
  final VoidCallback onReset;

  const FilterBottomSheet({
    super.key,
    required this.years,
    required this.paperTypes,
    required this.terms,
    required this.grades,
    required this.selectedYear,
    required this.selectedPaperType,
    required this.selectedTerm,
    required this.selectedGrade,
    required this.onYearSelected,
    required this.onTypeSelected,
    required this.onTermSelected,
    required this.onGradeSelected,
    required this.onReset,
  });

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
                    'Filter Papers',
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
                      onReset();
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
              child: RawScrollbar(
                thumbColor: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                thickness: 3.w,
                radius: Radius.circular(10.r),
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
                        children: grades.map((grade) {
                          return _buildFilterChip(
                            context,
                            grade.name,
                            selectedGrade == grade.id,
                            isDark,
                            () => onGradeSelected(grade.id),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24.h),

                      _buildSectionTitle(context, 'Year'),
                      SizedBox(height: 12.h),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              context,
                              'All Years',
                              selectedYear == null,
                              isDark,
                              () => onYearSelected(null),
                            ),
                            ...years.map((year) {
                              return _buildFilterChip(
                                context,
                                year,
                                selectedYear == year,
                                isDark,
                                () => onYearSelected(year),
                              );
                            }),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      _buildSectionTitle(context, 'Paper Type'),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: paperTypes.map((type) {
                          return _buildFilterChip(
                            context,
                            type,
                            selectedPaperType == type,
                            isDark,
                            () => onTypeSelected(type),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24.h),

                      _buildSectionTitle(context, 'Term'),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: terms.map((term) {
                          return _buildFilterChip(
                            context,
                            term,
                            selectedTerm == term,
                            isDark,
                            () => onTermSelected(term),
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
                onPressed: () => Navigator.pop(context),
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
