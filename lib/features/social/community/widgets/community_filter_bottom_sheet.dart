import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/widgets/standard_bottom_sheet.dart';

class CommunityFilterBottomSheet extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterSelected;

  const CommunityFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StandardBottomSheet(
      title: 'Filter Community',
      icon: BoxIcons.bx_slider_alt,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          _buildFilterOption(
            context: context,
            title: 'All Posts',
            subtitle: 'Show everything from the community',
            icon: Icons.view_agenda_rounded,
            value: 'all',
          ),
          _buildFilterOption(
            context: context,
            title: 'Following',
            subtitle: 'Only show posts from people you follow',
            icon: Icons.people_alt_rounded,
            value: 'following',
          ),
          _buildFilterOption(
            context: context,
            title: 'Trending',
            subtitle: 'Popular posts with high engagement',
            icon: Icons.trending_up_rounded,
            value: 'trending',
          ),
          _buildFilterOption(
            context: context,
            title: 'Questions',
            subtitle: 'Help others by answering questions',
            icon: Icons.help_outline_rounded,
            value: 'question',
          ),
          _buildFilterOption(
            context: context,
            title: 'Resources',
            subtitle: 'Study materials and useful links',
            icon: Icons.auto_stories_rounded,
            value: 'resource',
          ),
          _buildFilterOption(
            context: context,
            title: 'Polls',
            subtitle: 'Interactive polls and surveys',
            icon: Icons.poll_outlined,
            value: 'poll',
          ),
          _buildFilterOption(
            context: context,
            title: 'Expert Verified',
            subtitle: 'Posts with helpful verified answers',
            icon: Icons.verified_user_rounded,
            value: 'verified',
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = currentFilter == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onFilterSelected(value);
          Navigator.pop(context);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? theme.primaryColor : Colors.transparent,
                width: 4.w,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.15)
                      : isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? theme.primaryColor
                      : isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.primaryColor,
                  size: 24.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
