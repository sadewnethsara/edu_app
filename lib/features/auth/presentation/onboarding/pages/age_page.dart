import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AgePage extends StatefulWidget {
  final ValueChanged<String?> onAgeSelected;
  final bool showError;
  final String? initialAge; // 🚀 ADDED

  const AgePage({
    super.key,
    required this.onAgeSelected,
    this.showError = false,
    this.initialAge, // 🚀 ADDED
  });

  @override
  State<AgePage> createState() => _AgePageState();
}

class _AgePageState extends State<AgePage> {
  String? _ageRange;

  final List<String> _ageOptions = [
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21+',
  ];

  // 🚀 --- UPDATED INITSTATE --- 🚀
  @override
  void initState() {
    super.initState();
    // Pre-fill the selection
    _ageRange = widget.initialAge;
  }
  // 🚀 --- END OF UPDATE --- 🚀

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isError = widget.showError && _ageRange == null;
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
              AnimatedEmojis.pencil,
              size: 100.sp,
              repeat: false,
            ),
          ),
          SizedBox(height: 16.h),
          // 🧠 Heading
          Text(
            "How old are you?",
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            "We use this to personalize your experience.",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (isError) ...[
            SizedBox(height: 8.h),
            Text(
              "Please select your age to continue",
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 40.h),

          // 🟩 Square Grid Layout
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ageOptions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 1, // perfect square
            ),
            itemBuilder: (context, index) {
              final label = _ageOptions[index];
              return _buildAgeCard(context, label);
            },
          ),
        ],
      ),
    );
  }

  // --- 🧩 Age Card (Square, Animated, Theme-aware) ---
  Widget _buildAgeCard(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isSelected = _ageRange == label;

    return GestureDetector(
      onTap: () {
        setState(() => _ageRange = label);
        widget.onAgeSelected(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
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
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 36.sp,
            ),
          ),
        ),
      ),
    );
  }
}
