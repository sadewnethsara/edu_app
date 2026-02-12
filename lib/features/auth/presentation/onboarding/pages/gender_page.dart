import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GenderPage extends StatefulWidget {
  final ValueChanged<String?> onGenderSelected;
  final bool showError;
  final String? initialGender; // 🚀 ADDED

  const GenderPage({
    super.key,
    required this.onGenderSelected,
    this.showError = false,
    this.initialGender, // 🚀 ADDED
  });

  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  String? _gender;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool isError = widget.showError && _gender == null;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedEmoji(
              AnimatedEmojis.anatomicalHeart,
              size: 100.sp,
              repeat: false,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "Tell us about your gender",
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            "This information is optional and helps us personalize your learning experience.",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (isError) ...[
            SizedBox(height: 8.h),
            Text(
              "Please select your gender to continue",
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 40.h),

          Row(
            children: [
              Expanded(
                child: _buildGenderCard(context, 'Male', Icons.male_rounded),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildGenderCard(
                  context,
                  'Female',
                  Icons.female_rounded,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildGenderCard(
                  context,
                  'Transgender',
                  Icons.transgender_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildGenderCard(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isSelected = _gender == label;

    return GestureDetector(
      onTap: () {
        setState(() => _gender = label);
        widget.onGenderSelected(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 100.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 3.0.w : 1.5.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              size: 28.sp,
            ),
            SizedBox(height: 8.h),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
