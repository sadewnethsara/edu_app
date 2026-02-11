import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/data/models/language_model.dart';
import 'package:math/services/api_service.dart';
import 'package:math/services/language_service.dart';
import 'package:provider/provider.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<LanguageModel> _languages = [];
  String? _selectedLanguage;
  bool _isLoading = true;
  bool _isSaving = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadLanguages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    final languages = await _apiService.getLanguages();
    setState(() {
      _languages = languages;
      _isLoading = false;
    });
  }

  Future<void> _saveLanguagePreference() async {
    if (_selectedLanguage == null) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'preferences': {'language': _selectedLanguage},
        }, SetOptions(merge: true));
      }

      // Update app language - this will refresh the UI automatically
      if (mounted) {
        await context.read<LanguageService>().setLocale(_selectedLanguage!);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Language changed to ${_languages.firstWhere((l) => l.code == _selectedLanguage).nativeName}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Go back to previous screen (or home if this is first time)
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving language: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    SizedBox(height: 40.h),
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 80.sp,
                            color: theme.primaryColor,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Choose Your Language',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Select the language for your learning experience',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),
                    // Language Cards
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        itemCount: _languages.length,
                        itemBuilder: (context, index) {
                          final language = _languages[index];
                          final isSelected = _selectedLanguage == language.code;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: _LanguageCard(
                              language: language,
                              isSelected: isSelected,
                              onTap: () {
                                setState(
                                  () => _selectedLanguage = language.code,
                                );
                                _animationController.forward(from: 0);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // Continue Button
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: AnimatedOpacity(
                        opacity: _selectedLanguage != null ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: _selectedLanguage != null && !_isSaving
                                ? _saveLanguagePreference
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: _selectedLanguage != null ? 4 : 0,
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    height: 24.h,
                                    width: 24.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 24.sp,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getLanguageIcon(String code) {
    switch (code) {
      case 'en':
        return Icons.abc_rounded;
      case 'si':
        return Icons.translate_rounded;
      case 'ta':
        return Icons.language_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 8 : 2,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected
                    ? theme.primaryColor
                    : Colors.grey.withValues(alpha: 0.2),
                width: isSelected ? 3 : 1,
              ),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        theme.primaryColor.withValues(alpha: 0.1),
                        theme.primaryColor.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getLanguageIcon(language.code),
                    size: 32.sp,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : Colors.grey[700],
                  ),
                ),
                SizedBox(width: 16.w),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.primaryColor
                              : theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        language.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Check Icon
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.primaryColor,
                    size: 32.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
