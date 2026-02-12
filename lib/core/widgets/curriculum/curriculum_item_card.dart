import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum CurriculumItemType { subject, lesson, subtopic }

class CurriculumItemCard extends StatelessWidget {
  final String name;
  final String description;
  final int order;
  final VoidCallback onTap;
  final CurriculumItemType type;
  final String? iconName; // For subjects
  final Widget? contentBadges; // For lessons/subtopics

  const CurriculumItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.order,
    required this.onTap,
    required this.type,
    this.iconName,
    this.contentBadges,
  });

  IconData _getIcon() {
    if (type == CurriculumItemType.subject) {
      switch (iconName?.toLowerCase()) {
        case 'calculator':
        case 'math':
          return Icons.calculate_rounded;
        case 'science':
          return Icons.science_rounded;
        case 'book':
        case 'language':
          return Icons.menu_book_rounded;
        case 'history':
          return Icons.history_edu_rounded;
        case 'geography':
          return Icons.public_rounded;
        case 'art':
          return Icons.palette_rounded;
        case 'music':
          return Icons.music_note_rounded;
        case 'sports':
          return Icons.sports_rounded;
        default:
          return Icons.school_rounded;
      }
    }
    return Icons.school_rounded; // Default, not used for lessons/subtopics
  }

  Color _getColor() {
    if (type == CurriculumItemType.subject) {
      final colors = [
        const Color(0xFF6366F1), // Indigo
        const Color(0xFFEC4899), // Pink
        const Color(0xFF10B981), // Green
        const Color(0xFFF59E0B), // Amber
        const Color(0xFF8B5CF6), // Purple
        const Color(0xFF3B82F6), // Blue
        const Color(0xFFEF4444), // Red
        const Color(0xFF14B8A6), // Teal
      ];
      return colors[order % colors.length];
    } else if (type == CurriculumItemType.lesson) {
      final colors = [
        const Color(0xFF3B82F6), // Blue
        const Color(0xFF8B5CF6), // Purple
        const Color(0xFF10B981), // Green
        const Color(0xFFF59E0B), // Amber
        const Color(0xFFEF4444), // Red
        const Color(0xFF06B6D4), // Cyan
      ];
      return colors[order % colors.length];
    } else {
      final colors = [
        const Color(0xFF8B5CF6), // Purple
        const Color(0xFFEC4899), // Pink
        const Color(0xFF06B6D4), // Cyan
        const Color(0xFF10B981), // Green
        const Color(0xFFF59E0B), // Amber
        const Color(0xFFEF4444), // Red
      ];
      return colors[order % colors.length];
    }
  }

  Widget _buildLeadingWidget(Color color) {
    if (type == CurriculumItemType.subject) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(_getIcon(), color: color, size: 28.sp),
      );
    } else {
      return Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Text(
            '$order',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemColor = _getColor();
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                _buildLeadingWidget(itemColor),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (contentBadges != null) ...[
                        SizedBox(height: 8.h),
                        contentBadges!,
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.iconTheme.color?.withValues(alpha: 0.5),
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
