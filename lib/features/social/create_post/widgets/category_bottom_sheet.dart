import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/features/social/feed/models/post_model.dart';
import 'package:math/widgets/standard_bottom_sheet.dart';

class CategoryBottomSheet extends StatelessWidget {
  final PostCategory selectedCategory;
  final Function(PostCategory) onCategorySelected;

  const CategoryBottomSheet({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StandardBottomSheet(
      title: "Select Category",
      icon: Icons.category_outlined,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: PostCategory.values.length,
        itemBuilder: (context, index) {
          final category = PostCategory.values[index];
          final isSelected = selectedCategory == category;

          return InkWell(
            onTap: () {
              onCategorySelected(category);
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
                      _getCategoryIcon(category),
                      size: 20.sp,
                      color: isSelected ? colorScheme.primary : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    category.name[0].toUpperCase() + category.name.substring(1),
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

  IconData _getCategoryIcon(PostCategory category) {
    switch (category) {
      case PostCategory.general:
        return Icons.public_rounded;
      case PostCategory.question:
        return Icons.help_outline_rounded;
      case PostCategory.discussion:
        return Icons.forum_outlined;
      case PostCategory.resource:
        return Icons.menu_book_rounded;
      case PostCategory.achievement:
        return Icons.emoji_events_outlined;
    }
  }
}
