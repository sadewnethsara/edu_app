import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/features/notifications/presentation/screens/push_notifications_screen.dart';

import 'package:math/core/widgets/message_banner.dart';
import 'package:icons_plus/icons_plus.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Local state for toggles
  bool _qualityFilter = true;
  bool _unreadCountBadge = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use specific colors to match the "X" dark mode aesthetic if requested,
    // otherwise stick to App Theme.
    // The user mentioned "app color change like that images in dark mode".
    // We'll try to keep it consistent with the current app theme but ensure it looks premium.

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Notification settings",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FILTERS SECTION ---
            _buildSectionHeader(theme, "Filters"),
            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _qualityFilter,
                    onChanged: (val) {
                      setState(() => _qualityFilter = val);
                      MessageBanner.show(
                        context,
                        message: "Quality filter saved",
                        type: MessageType.success,
                      );
                    },
                    activeThumbColor: theme.colorScheme.primary,
                    title: Text(
                      "Quality filter",
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      "Filter lower-quality content.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.disabledColor,
                        fontSize: 12.sp,
                      ),
                    ),
                    secondary: Icon(
                      EvaIcons.options_2_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
                  ListTile(
                    title: Text(
                      "Muted notifications",
                      style: theme.textTheme.bodyLarge,
                    ),
                    leading: Icon(
                      EvaIcons.bell_off_outline,
                      color: theme.colorScheme.primary,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14.sp,
                      color: theme.disabledColor,
                    ),
                    onTap: () {
                      MessageBanner.show(
                        context,
                        message: "Muted notifications settings",
                        type: MessageType.info,
                      );
                    },
                  ),
                  Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
                  ListTile(
                    title: Text(
                      "Muted words",
                      style: theme.textTheme.bodyLarge,
                    ),
                    leading: Icon(
                      EvaIcons.text_outline,
                      color: theme.colorScheme.primary,
                    ), // or similar
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14.sp,
                      color: theme.disabledColor,
                    ),
                    onTap: () {
                      MessageBanner.show(
                        context,
                        message: "Muted words settings",
                        type: MessageType.info,
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // --- PREFERENCES SECTION ---
            _buildSectionHeader(theme, "Preferences"),
            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _unreadCountBadge,
                    onChanged: (val) {
                      setState(() => _unreadCountBadge = val);
                      MessageBanner.show(
                        context,
                        message: "Badge settings saved",
                        type: MessageType.success,
                      );
                    },
                    activeThumbColor: theme.colorScheme.primary,
                    title: Text(
                      "Unread count badge",
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      "Show unread count on app icon.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.disabledColor,
                        fontSize: 12.sp,
                      ),
                    ),
                    secondary: Icon(
                      EvaIcons.checkmark_circle_2_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
                  ListTile(
                    title: Text(
                      "Push notifications",
                      style: theme.textTheme.bodyLarge,
                    ),
                    leading: Icon(
                      EvaIcons.bell_outline,
                      color: theme.colorScheme.primary,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14.sp,
                      color: theme.disabledColor,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PushNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
                  ListTile(
                    title: Text(
                      "SMS notifications",
                      style: theme.textTheme.bodyLarge,
                    ),
                    leading: Icon(
                      EvaIcons.message_square_outline,
                      color: theme.colorScheme.primary,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14.sp,
                      color: theme.disabledColor,
                    ),
                    onTap: () {
                      MessageBanner.show(
                        context,
                        message: "SMS notifications coming soon",
                        type: MessageType.info,
                      );
                    },
                  ),
                  Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
                  ListTile(
                    title: Text(
                      "Email notifications",
                      style: theme.textTheme.bodyLarge,
                    ),
                    leading: Icon(
                      EvaIcons.email_outline,
                      color: theme.colorScheme.primary,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14.sp,
                      color: theme.disabledColor,
                    ),
                    onTap: () {
                      MessageBanner.show(
                        context,
                        message: "Email notifications coming soon",
                        type: MessageType.info,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
