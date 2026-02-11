import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NameInputPage extends StatefulWidget {
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onLastNameChanged;
  final bool showNameError;

  // 🚀 --- ADDED INITIAL VALUES --- 🚀
  final String? initialFirstName;
  final String? initialLastName;
  // 🚀 --- END OF ADDED VALUES --- 🚀

  const NameInputPage({
    super.key,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.showNameError,
    // 🚀 ADDED TO CONSTRUCTOR
    this.initialFirstName,
    this.initialLastName,
  });

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // 🚀 --- UPDATED INITSTATE --- 🚀
  @override
  void initState() {
    super.initState();
    // Pre-fill the text fields if initial data is provided
    if (widget.initialFirstName != null) {
      _firstNameController.text = widget.initialFirstName!;
      // Notify the parent once at the start
      widget.onFirstNameChanged(widget.initialFirstName!);
    }
    if (widget.initialLastName != null) {
      _lastNameController.text = widget.initialLastName!;
      // Notify the parent once at the start
      widget.onLastNameChanged(widget.initialLastName!);
    }
  }
  // 🚀 --- END OF UPDATE --- 🚀

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // 🎨 --- REDESIGNED BUILD METHOD --- 🎨
  @override
  Widget build(BuildContext context) {
    // Get theme properties
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Title and Subtitle
          Text(
            "What should we call you?",
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            "Enter your name to personalize your learning experience.",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),

          // 2. Thematic Emoji
          Center(
            child: AnimatedEmoji(
              AnimatedEmojis
                  .speakNoEvilMonkey, // Changed for a friendly greeting
              size: 100.sp, // Made slightly smaller
              repeat: false,
            ),
          ),
          SizedBox(height: 24.h),

          // 3. Name Input Fields (Side-by-Side)
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align fields if one has an error
            children: [
              Expanded(
                child: _buildTextField(
                  context,
                  controller: _firstNameController,
                  label: "First Name",
                  onChanged: widget.onFirstNameChanged,
                  isError:
                      widget.showNameError && _firstNameController.text.isEmpty,
                  errorMessage: "Required", // Pass error message
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildTextField(
                  context,
                  controller: _lastNameController,
                  label: "Last Name",
                  onChanged: widget.onLastNameChanged,
                  isError:
                      widget.showNameError && _lastNameController.text.isEmpty,
                  errorMessage: "Required", // Pass error message
                ),
              ),
            ],
          ),

          // 4. Removed the old error message from here
        ],
      ),
    );
  }

  // 🎨 --- UPDATED HELPER METHOD --- 🎨
  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    required bool isError,
    required String? errorMessage, // New parameter for inline error
  }) {
    // Get theme properties
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final inputTheme = theme.inputDecorationTheme;

    final Color focusedBorderColor = colorScheme.secondary;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      style: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
        filled: inputTheme.filled,
        fillColor: inputTheme.fillColor,

        // Use errorText to show inline errors
        errorText: isError ? errorMessage : null,
        errorStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),

        // --- BORDER STYLES ---
        border: inputTheme.border,

        // Standard border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1.5.w,
          ),
        ),

        // Focused border (no error)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: focusedBorderColor, width: 3.0.w),
        ),

        // Error border (not focused)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colorScheme.error, width: 2.0.w),
        ),

        // Error border (when focused)
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colorScheme.error, width: 3.0.w),
        ),

        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      ),
    );
  }
}
