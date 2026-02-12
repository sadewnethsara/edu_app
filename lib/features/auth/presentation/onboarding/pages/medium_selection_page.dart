import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/language_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:shimmer/shimmer.dart';

class MediumSelectionPage extends StatefulWidget {
  final ValueChanged<String> onMediumSelected;
  final bool showError;
  final ApiService? apiService;

  const MediumSelectionPage({
    super.key,
    required this.onMediumSelected,
    required this.showError,
    this.apiService,
  });

  @override
  State<MediumSelectionPage> createState() => _MediumSelectionPageState();
}

class _MediumSelectionPageState extends State<MediumSelectionPage> {
  late final ApiService _apiService;
  String? _selectedMedium;
  List<LanguageModel> _languages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final languages = await _apiService.getLanguages();

      if (languages.isNotEmpty) {
        setState(() {
          _languages = languages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _languages = _getDefaultLanguages();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _languages = _getDefaultLanguages();
        _isLoading = false;
      });
    }
  }

  List<LanguageModel> _getDefaultLanguages() {
    return [
      LanguageModel(
        code: 'si',
        label: 'සිංහල මාධ්‍යය',
        nativeName: 'සිංහල',
        isActive: true,
        order: 1,
      ),
      LanguageModel(
        code: 'ta',
        label: 'தமிழ் மாத்திரை',
        nativeName: 'தமிழ்',
        isActive: true,
        order: 2,
      ),
      LanguageModel(
        code: 'en',
        label: 'English Medium',
        nativeName: 'English',
        isActive: true,
        order: 3,
      ),
    ];
  }

  String _getIcon(String code) {
    switch (code) {
      case 'en':
        return '📚';
      case 'si':
        return '🇱🇰';
      case 'ta':
        return '🇮🇳';
      default:
        return '🌐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool isError = widget.showError && _selectedMedium == null;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedEmoji(
              AnimatedEmojis.graduationCap,
              size: 100.sp,
              repeat: false,
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            "Select Your Learning Language",
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),

          Text(
            "Choose the language you’d like to use while exploring lessons and resources.",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),

          if (_isLoading)
            Column(children: List.generate(3, (index) => _buildShimmerTile()))
          else if (_languages.isEmpty)
            Center(
              child: Text(
                "No languages available",
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            )
          else
            Column(
              children: _languages.map((language) {
                final isSelected = _selectedMedium == language.code;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: MediumSelectionTile(
                    label: language.label,
                    icon: _getIcon(language.code),
                    isSelected: isSelected,
                    isError: isError, // Pass error state
                    onTap: () {
                      setState(() => _selectedMedium = language.code);
                      widget.onMediumSelected(language.code);
                    },
                  ),
                );
              }).toList(),
            ),

          if (isError)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Text(
                "Please select a medium to continue.",
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerTile() {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Shimmer.fromColors(
        baseColor: theme.cardColor,
        highlightColor: theme.scaffoldBackgroundColor,
        child: Container(
          height: 70.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
      ),
    );
  }
}

class MediumSelectionTile extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final bool isError;
  final VoidCallback onTap;

  const MediumSelectionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Color tileBorderColor = colorScheme.outline.withValues(
      alpha: 0.5,
    ); // Default
    double borderWidth = 1.5.w;
    List<BoxShadow> tileShadow = [];

    if (isError) {
      tileBorderColor = colorScheme.error;
      borderWidth = 3.w;
    } else if (isSelected) {
      tileBorderColor = colorScheme.primary;
      borderWidth = 3.w;
      tileShadow = [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.3),
          blurRadius: 6.r,
          offset: Offset(0, 3.h),
        ),
      ];
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: tileBorderColor, width: borderWidth),
          boxShadow: tileShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icon, style: TextStyle(fontSize: 24.sp)),
                SizedBox(width: 16.w),
                Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                      size: 28.sp,
                      key: const ValueKey('check'),
                    )
                  : Icon(
                      Icons.radio_button_off_rounded,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                      size: 28.sp,
                      key: const ValueKey('radio'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
