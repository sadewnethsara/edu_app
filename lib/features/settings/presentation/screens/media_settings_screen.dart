import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/services/settings_service.dart';

class MediaSettingsScreen extends StatelessWidget {
  const MediaSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure SettingsService provider is available higher up or rely on simple instance usage if simple singleton
    // But ideally wrap in Provider or ChangeNotifierProvider in main.dart
    // For now, let's assume valid instance or rebuild on change.
    // The SettingsService is a ChangeNotifier.

    // We need to listen to SettingsService changes.
    // If not provided via Provider, we can use AnimatedBuilder with singleton.

    return Scaffold(
      appBar: AppBar(title: const Text('Media Quality')),
      body: AnimatedBuilder(
        animation: SettingsService(),
        builder: (context, _) {
          final settings = SettingsService();
          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _buildSectionHeader(context, "Upload Quality"),
              _buildQualityOption(
                context,
                title: "Standard Quality",
                subtitle:
                    "Compresses images to under 500KB. Faster uploads, saves data.",
                value: MediaQuality.standard,
                groupValue: settings.uploadQuality,
                onChanged: (val) => settings.setUploadQuality(val!),
              ),
              _buildQualityOption(
                context,
                title: "High Quality",
                subtitle:
                    "Compresses images max 1.2MB. Better detail, larger files.",
                value: MediaQuality.high,
                groupValue: settings.uploadQuality,
                onChanged: (val) => settings.setUploadQuality(val!),
              ),

              Divider(height: 32.h),

              _buildSectionHeader(context, "Download Quality"),
              _buildQualityOption(
                context,
                title: "Standard Quality",
                subtitle: "Faster loading, saves data.",
                value: MediaQuality.standard,
                groupValue: settings.downloadQuality,
                onChanged: (val) => settings.setDownloadQuality(val!),
              ),
              _buildQualityOption(
                context,
                title: "High Quality",
                subtitle: "Best viewing experience.",
                value: MediaQuality.high,
                groupValue: settings.downloadQuality,
                onChanged: (val) => settings.setDownloadQuality(val!),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 8.h),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildQualityOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required MediaQuality value,
    required MediaQuality groupValue,
    required ValueChanged<MediaQuality?> onChanged,
  }) {
    return RadioListTile<MediaQuality>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      activeColor: Theme.of(context).primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
