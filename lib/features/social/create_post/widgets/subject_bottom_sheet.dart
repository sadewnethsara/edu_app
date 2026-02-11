import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/subject_model.dart';
import 'package:math/core/widgets/standard_bottom_sheet.dart';

class SubjectBottomSheet extends StatelessWidget {
  final String? selectedSubjectId;
  final List<SubjectModel> subjects;
  final Function(String, String) onSubjectSelected;

  const SubjectBottomSheet({
    super.key,
    this.selectedSubjectId,
    required this.subjects,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StandardBottomSheet(
      title: "Select Subject",
      icon: Icons.subject,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final isSelected = selectedSubjectId == subject.id;

          return InkWell(
            onTap: () {
              onSubjectSelected(subject.id, subject.name);
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border(
                        left: BorderSide(
                          color: colorScheme.primary,
                          width: 4.w,
                        ),
                      )
                    : null,
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.05)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.sp),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.book_outlined,
                      size: 20.sp,
                      color: isSelected ? colorScheme.primary : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      subject.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 20.sp,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
