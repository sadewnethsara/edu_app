import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:math/core/models/feedback_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'dart:io';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  FeedbackType _selectedType = FeedbackType.feedback;
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceInfo = '';
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        deviceInfo =
            '${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        deviceInfo =
            '${iosInfo.name} ${iosInfo.systemName} ${iosInfo.systemVersion}';
      }

      final feedback = FeedbackModel(
        userId: user?.uid ?? 'anonymous',
        userEmail: user?.email,
        message: _messageController.text,
        type: _selectedType,
        createdAt: Timestamp.now(),
        deviceInfo: deviceInfo,
        appVersion: packageInfo.version,
      );

      await FirebaseFirestore.instance
          .collection('feedback')
          .add(feedback.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback sent! Thank you!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      logger.e('Error sending feedback', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send feedback. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Feedback'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "How can we improve?",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Your feedback helps us make the app better for everyone.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
              SizedBox(height: 24.h),

              DropdownButtonFormField<FeedbackType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                items: FeedbackType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.name[0].toUpperCase() + type.name.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Describe your issue or suggestion',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Please calculate your feedback'
                    : null,
              ),
              SizedBox(height: 24.h),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitFeedback,
                icon: _isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.send_2_outline),
                label: Text(_isLoading ? 'Sending...' : 'Send Feedback'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
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
