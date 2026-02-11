import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class PushNotificationsScreen extends StatefulWidget {
  const PushNotificationsScreen({super.key});

  @override
  State<PushNotificationsScreen> createState() =>
      _PushNotificationsScreenState();
}

class _PushNotificationsScreenState extends State<PushNotificationsScreen> {
  // Master toggle
  bool _pauseAll = false;

  // Interaction toggles
  bool _relatedToYou_Likes = true;
  bool _relatedToYou_Reposts = true;
  bool _relatedToYou_Quotes = true;

  // From user request: "push notification it inside it on off all"
  // and "app color change like that images in dark mode"

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dark mode check for color logic if needed, currently reusing theme

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Push notifications",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // Master Toggle
          SwitchListTile(
            value: _pauseAll,
            onChanged: (val) => setState(() => _pauseAll = val),
            title: Text(
              "Pause all",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "Temporarily pause all push notifications.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            activeThumbColor: theme.colorScheme.primary,
          ),

          Divider(height: 32.h, thickness: 1, color: theme.dividerColor),

          if (!_pauseAll) ...[
            _buildSectionHeader(theme, "Related to you and your posts"),

            _buildSwitch(
              theme,
              "Likes",
              _relatedToYou_Likes,
              (v) => setState(() => _relatedToYou_Likes = v),
            ),
            _buildSwitch(
              theme,
              "Reposts",
              _relatedToYou_Reposts,
              (v) => setState(() => _relatedToYou_Reposts = v),
            ),
            _buildSwitch(
              theme,
              "Quotes",
              _relatedToYou_Quotes,
              (v) => setState(() => _relatedToYou_Quotes = v),
            ),

            Divider(height: 32.h, thickness: 1, color: theme.dividerColor),

            _buildSectionHeader(
              theme,
              "From X",
            ), // Using "From App" or "System" effectively
            _buildSwitch(theme, "Topics", true, (_) {}), // Mock
            _buildSwitch(theme, "News", false, (_) {}),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitch(
    ThemeData theme,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: theme.textTheme.bodyLarge),
      activeThumbColor: theme.colorScheme.primary,
      dense: false,
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.disabledColor,
        ),
      ),
    );
  }
}
