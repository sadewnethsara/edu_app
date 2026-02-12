import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NameInputPage extends StatefulWidget {
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onLastNameChanged;
  final bool showNameError;

  final String? initialFirstName;
  final String? initialLastName;

  const NameInputPage({
    super.key,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.showNameError,
    this.initialFirstName,
    this.initialLastName,
  });

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFirstName != null) {
      _firstNameController.text = widget.initialFirstName!;
      widget.onFirstNameChanged(widget.initialFirstName!);
    }
    if (widget.initialLastName != null) {
      _lastNameController.text = widget.initialLastName!;
      widget.onLastNameChanged(widget.initialLastName!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          Center(
            child: AnimatedEmoji(
              AnimatedEmojis
                  .speakNoEvilMonkey, // Changed for a friendly greeting
              size: 100.sp, // Made slightly smaller
              repeat: false,
            ),
          ),
          SizedBox(height: 24.h),

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
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    required bool isError,
    required String? errorMessage, // New parameter for inline error
  }) {
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

        errorText: isError ? errorMessage : null,
        errorStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),

        border: inputTheme.border,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1.5.w,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: focusedBorderColor, width: 3.0.w),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colorScheme.error, width: 2.0.w),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colorScheme.error, width: 3.0.w),
        ),

        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      ),
    );
  }
}
