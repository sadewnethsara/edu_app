import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/widgets/standard_bottom_sheet.dart';

class PostTimerBottomSheet extends StatelessWidget {
  final int? initialDays;
  final Function(int?) onDaysSelected;

  const PostTimerBottomSheet({
    super.key,
    this.initialDays,
    required this.onDaysSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final timerOptions = [
      {
        'days': null,
        'label': 'No Expiration',
        'icon': Iconsax.timer_pause_outline,
      },
      {'days': 1, 'label': '1 Day', 'icon': Iconsax.clock_outline},
      {'days': 3, 'label': '3 Days', 'icon': Iconsax.clock_outline},
      {'days': 7, 'label': '7 Days', 'icon': Iconsax.clock_outline},
      {'days': 30, 'label': '30 Days', 'icon': Iconsax.clock_outline},
    ];

    return StandardBottomSheet(
      title: "Set Expiration",
      icon: Iconsax.clock_outline,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: timerOptions.length,
        itemBuilder: (context, index) {
          final option = timerOptions[index];
          final days = option['days'] as int?;
          final isSelected = initialDays == days;

          return InkWell(
            onTap: () {
              onDaysSelected(days);
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
                      Iconsax.tick_circle_bold,
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
