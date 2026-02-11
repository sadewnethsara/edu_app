import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/widgets/standard_bottom_sheet.dart';

class SortBottomSheet extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;

  const SortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sortOptions = [
      {'id': 'newest', 'label': 'Newest First', 'icon': EvaIcons.clock_outline},
      {
        'id': 'oldest',
        'label': 'Oldest First',
        'icon': EvaIcons.archive_outline,
      },
      {'id': 'likes', 'label': 'Most Liked', 'icon': EvaIcons.heart_outline},
      {
        'id': 'replies',
        'label': 'Most Replied',
        'icon': EvaIcons.message_circle_outline,
      },
    ];

    return StandardBottomSheet(
      title: "Sort By",
      icon: EvaIcons.shuffle_2_outline,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortOptions.length,
        itemBuilder: (context, index) {
          final option = sortOptions[index];
          final isSelected = currentSort == option['id'];

          return InkWell(
            onTap: () {
              onSortSelected(option['id'] as String);
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
                      option['icon'] as IconData,
                      size: 20.sp,
                      color: isSelected ? colorScheme.primary : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    option['label'] as String,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      EvaIcons.checkmark_circle_2,
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
