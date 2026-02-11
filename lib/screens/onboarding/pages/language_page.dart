import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/l10n/app_localizations.dart';
import 'package:math/services/language_service.dart';
import 'package:provider/provider.dart';

class LanguagePage extends StatefulWidget {
  final ValueChanged<String> onLanguageSelected;
  final bool showError;

  const LanguagePage({
    super.key,
    required this.onLanguageSelected,
    required this.showError,
  });

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String? _selectedLanguage;

  final _languages = const [
    {'name': 'English (UK)', 'code': 'en', 'emoji': '🇬🇧'},
    {'name': 'සිංහල (LK)', 'code': 'si', 'emoji': '🇱🇰'},
    {'name': 'தமிழ் (LK)', 'code': 'ta', 'emoji': '🇱🇰'},
  ];

  @override
  void initState() {
    super.initState();
    // Don't pre-select any language - force user to explicitly choose
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bool isError = widget.showError && _selectedLanguage == null;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AnimatedEmoji(
                  AnimatedEmojis.globeShowingAsiaAustralia,
                  size: 100.sp,
                  repeat: false,
                ),
              ),
              SizedBox(height: 16.h),

              Text(
                l10n.chooseYourAppLanguage,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 28.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              Text(
                l10n.languagePageSubtitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _languages.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = _selectedLanguage == lang['code'];

                  Color tileBorderColor = colorScheme.outline.withValues(
                    alpha: 0.5,
                  );
                  double borderWidth = 1.5.w;
                  List<BoxShadow> tileShadow = [];

                  if (isError) {
                    tileBorderColor = colorScheme.error;
                    borderWidth = 3.0.w;
                  } else if (isSelected) {
                    tileBorderColor = colorScheme.primary;
                    borderWidth = 3.0.w;
                    tileShadow = [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 6.r,
                        offset: Offset(0, 3.h),
                      ),
                    ];
                  }

                  return InkWell(
                    onTap: () async {
                      setState(() {
                        _selectedLanguage = lang['code']!;
                      });

                      await Provider.of<LanguageService>(
                        context,
                        listen: false,
                      ).setLocale(lang['code']!);

                      widget.onLanguageSelected(lang['code']!);
                    },
                    borderRadius: BorderRadius.circular(15.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : colorScheme.surface,
                        border: Border.all(
                          color: tileBorderColor,
                          width: borderWidth,
                        ),
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: tileShadow,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 16.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                lang['emoji']!,
                                style: TextStyle(fontSize: 26.sp),
                              ),
                              SizedBox(width: 16.w),
                              Text(
                                lang['name']!,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: colorScheme.primary,
                                    size: 30.sp,
                                    key: const ValueKey('checked'),
                                  )
                                : Icon(
                                    Icons.circle_outlined,
                                    color: colorScheme.outline.withValues(
                                      alpha: 0.5,
                                    ),
                                    size: 30.sp,
                                    key: const ValueKey('unchecked'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              if (isError)
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Text(
                    l10n.pleaseSelectLanguage,
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
        ),
      ),
    );
  }
}
