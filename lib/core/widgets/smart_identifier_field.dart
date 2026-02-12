import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';

class SmartIdentifierField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<bool>?
  onModeChanged; // Callback to notify parent if phone/email

  const SmartIdentifierField({
    super.key,
    required this.controller,
    this.validator,
    this.onModeChanged,
  });

  @override
  State<SmartIdentifierField> createState() => _SmartIdentifierFieldState();
}

class _SmartIdentifierFieldState extends State<SmartIdentifierField> {
  bool? _isPhoneMode; // null means undecided yet

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    _handleTyping(widget.controller.text);
  }

  IconData _getDynamicIcon() {
    if (widget.controller.text.isEmpty) {
      return Bootstrap.person; // 👤 start icon
    } else if (_isPhoneMode == true) {
      return Icons.phone_android_outlined; // 📱
    } else {
      return Icons.email_outlined; // ✉️
    }
  }

  String _getDynamicLabel() {
    if (widget.controller.text.isEmpty) {
      return "Enter email or mobile number to continue";
    } else if (_isPhoneMode == true) {
      return "Phone Number";
    } else if (_isPhoneMode == false) {
      return "Email Address";
    }
    return "Enter email or mobile number";
  }

  void _handleTyping(String value) {
    if (value.length >= 3) {
      bool hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
      bool hasNumber = RegExp(r'\d').hasMatch(value);

      if (hasLetter && _isPhoneMode != false) {
        setState(() => _isPhoneMode = false);
        widget.onModeChanged?.call(false);
      } else if (hasNumber && !hasLetter && _isPhoneMode != true) {
        setState(() => _isPhoneMode = true);
        widget.onModeChanged?.call(true);
      }

      if (_isPhoneMode == true && value.length >= 3) {
        String formatted = _formatPhone(value);
        if (formatted != value) {
          widget.controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    } else {
      if (_isPhoneMode != null) {
        setState(() => _isPhoneMode = null);
      }
    }
  }

  String _formatPhone(String value) {
    String cleaned = value.replaceAll(RegExp(r'\s+'), '');

    if (cleaned.startsWith('0')) {
      cleaned = '+94 ${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+94') && cleaned.length >= 3) {
      cleaned = '+94 $cleaned';
    }

    cleaned = cleaned.replaceFirstMapped(
      RegExp(r'(\+94)(\d{2})(\d+)'),
      (m) => '${m[1]} ${m[2]} ${m[3]}',
    );

    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.emailAddress,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: _getDynamicLabel(),
        labelStyle: TextStyle(fontSize: 14.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        prefixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Stack(
            alignment: Alignment.center,
            key: ValueKey(_getDynamicIcon()),
            children: [
              Icon(_getDynamicIcon(), size: 24),
              if (widget.controller.text.isEmpty)
                Positioned(
                  bottom: 10,
                  right: 8,
                  child: Icon(
                    Icons.add,
                    size: 12,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        ),
      ),
      validator:
          widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your email or phone number";
            }
            if (_isPhoneMode == true) {
              if (!RegExp(r'^\+94\s?\d{2}\s?\d{6,7}$').hasMatch(value)) {
                return "Enter a valid phone number";
              }
            } else if (_isPhoneMode == false) {
              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
                return "Enter a valid email address";
              }
            }
            return null;
          },
    );
  }
}
