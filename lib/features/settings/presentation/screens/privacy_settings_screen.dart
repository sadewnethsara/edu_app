import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/widgets/message_banner.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _anonymousMode = false;
  bool _shareAnalytics = true;
  bool _hideOnlineStatus = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Privacy & Security",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, "Identity"),
            _buildTile(
              theme,
              title: "Anonymous Mode",
              subtitle:
                  "Post and browse communities without revealing your identity.",
              icon: EvaIcons.person_outline,
              trailing: Switch(
                value: _anonymousMode,
                onChanged: (val) {
                  setState(() => _anonymousMode = val);
                  MessageBanner.show(
                    context,
                    message: "Anonymous mode ${val ? 'enabled' : 'disabled'}",
                    type: MessageType.success,
                  );
                },
              ),
            ),
            SizedBox(height: 24.h),
            _buildSectionHeader(theme, "Visibility"),
            _buildTile(
              theme,
              title: "Hide Online Status",
              subtitle: "Others won't see when you're active.",
              icon: EvaIcons.eye_off_2_outline,
              trailing: Switch(
                value: _hideOnlineStatus,
                onChanged: (val) {
                  setState(() => _hideOnlineStatus = val);
                },
              ),
            ),
            SizedBox(height: 24.h),
            _buildSectionHeader(theme, "Data"),
            _buildTile(
              theme,
              title: "Share Analytics",
              subtitle: "Help us improve by sharing usage data.",
              icon: EvaIcons.pie_chart_outline,
              trailing: Switch(
                value: _shareAnalytics,
                onChanged: (val) {
                  setState(() => _shareAnalytics = val);
                },
              ),
            ),
            Divider(height: 32.h),
            _buildDangerTile(
              theme,
              title: "Delete Account",
              subtitle: "Permanently remove your account and all data.",
              icon: EvaIcons.trash_2_outline,
              onTap: () {
                // TODO: Implement delete account logic
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTile(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.primaryColor),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
            fontSize: 12.sp,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildDangerTile(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.error),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error.withValues(alpha: 0.7),
          fontSize: 12.sp,
        ),
      ),
      onTap: onTap,
    );
  }
}
