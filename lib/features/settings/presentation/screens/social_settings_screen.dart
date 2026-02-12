import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/user_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/router/app_router.dart';
import 'package:provider/provider.dart';

class SocialSettingsScreen extends StatefulWidget {
  const SocialSettingsScreen({super.key});

  @override
  State<SocialSettingsScreen> createState() => _SocialSettingsScreenState();
}

class _SocialSettingsScreenState extends State<SocialSettingsScreen> {
  final SocialService _socialService = SocialService();
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userModel = UserModel.fromJson(doc.data()!);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_userModel == null) return;

    setState(() {
      final json = _userModel!.toJson();
      json[key] = value;
      _userModel = UserModel.fromJson(json);
    });

    try {
      await _socialService.updateUserSettings(_userModel!.uid, {key: value});
      if (mounted) {
        MessageBanner.show(
          context,
          message: "Settings updated",
          type: MessageType.success,
        );
      }
    } catch (e) {
      _loadUserData();
      if (mounted) {
        MessageBanner.show(
          context,
          message: "Failed to update settings",
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Community Settings")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Community Settings",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, "Privacy & Safety"),
            _buildPrivacySection(theme, primaryColor),

            SizedBox(height: 24.h),

            _buildSectionHeader(theme, "Interactions"),
            _buildInteractionsSection(theme, primaryColor),

            SizedBox(height: 24.h),

            _buildSectionHeader(theme, "Content"),
            _buildContentSection(theme, primaryColor),

            SizedBox(height: 24.h),

            _buildSectionHeader(theme, "Feed Preferences"),
            _buildFeedPreferencesSection(theme, primaryColor),

            SizedBox(height: 24.h),

            _buildSectionHeader(theme, "Offline & Storage"),
            _buildStorageSection(theme, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection(ThemeData theme, Color primaryColor) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        title: const Text("Clear Social Cache"),
        subtitle: Text(
          "Manage downloaded posts and media",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
            fontSize: 12.sp,
          ),
        ),
        leading: Icon(Iconsax.box_outline, color: primaryColor),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14.sp,
          color: theme.disabledColor,
        ),
        onTap: () => context.push(AppRouter.clearCachePath),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPrivacySection(ThemeData theme, Color primaryColor) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _userModel?.isPrivateAccount ?? false,
            onChanged: (val) => _updateSetting('isPrivateAccount', val),
            activeThumbColor: primaryColor,
            title: Text("Private Account", style: theme.textTheme.bodyLarge),
            subtitle: Text(
              "Only people you approve can see your posts.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
                fontSize: 12.sp,
              ),
            ),
            secondary: Icon(EvaIcons.lock_outline, color: primaryColor),
          ),
          Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
          ListTile(
            title: Text("Blocked Accounts", style: theme.textTheme.bodyLarge),
            subtitle: Text(
              "${_userModel?.blockedUsers.length ?? 0} accounts",
              style: theme.textTheme.bodySmall,
            ),
            leading: Icon(EvaIcons.slash_outline, color: primaryColor),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              color: theme.disabledColor,
            ),
            onTap: () => context.push(AppRouter.blockedAccountsPath),
          ),
          Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
          ListTile(
            title: Text("Muted Accounts", style: theme.textTheme.bodyLarge),
            subtitle: Text(
              "${_userModel?.mutedUsers.length ?? 0} accounts",
              style: theme.textTheme.bodySmall,
            ),
            leading: Icon(EvaIcons.volume_off_outline, color: primaryColor),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              color: theme.disabledColor,
            ),
            onTap: () => context.push(AppRouter.mutedAccountsPath),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionsSection(ThemeData theme, Color primaryColor) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text("Who can reply?", style: theme.textTheme.bodyLarge),
            subtitle: Text(
              _userModel?.replyPreference ?? 'Everyone',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
                fontSize: 12.sp,
              ),
            ),
            leading: Icon(EvaIcons.message_circle_outline, color: primaryColor),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              color: theme.disabledColor,
            ),
            onTap: () => _showReplyPreferencePicker(theme),
          ),
          Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
          SwitchListTile(
            value: _userModel?.allowTagging ?? true,
            onChanged: (val) => _updateSetting('allowTagging', val),
            activeThumbColor: primaryColor,
            title: Text("Allow Tagging", style: theme.textTheme.bodyLarge),
            subtitle: Text(
              "Let others find and tag you in posts.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
                fontSize: 12.sp,
              ),
            ),
            secondary: Icon(EvaIcons.at_outline, color: primaryColor),
          ),
        ],
      ),
    );
  }

  void _showReplyPreferencePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Who can reply?",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 16.h),
              _buildPickerOption(
                theme: theme,
                title: "Everyone",
                icon: EvaIcons.globe_outline,
                isSelected: _userModel?.replyPreference == 'Everyone',
                onTap: () {
                  _updateSetting('replyPreference', 'Everyone');
                  Navigator.pop(context);
                },
              ),
              _buildPickerOption(
                theme: theme,
                title: "Followers",
                icon: EvaIcons.people_outline,
                isSelected: _userModel?.replyPreference == 'Followers',
                onTap: () {
                  _updateSetting('replyPreference', 'Followers');
                  Navigator.pop(context);
                },
              ),
              _buildPickerOption(
                theme: theme,
                title: "Private",
                icon: EvaIcons.lock_outline,
                isSelected: _userModel?.replyPreference == 'Private',
                onTap: () {
                  _updateSetting('replyPreference', 'Private');
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentSection(ThemeData theme, Color primaryColor) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _userModel?.autoplayVideos ?? true,
            onChanged: (val) => _updateSetting('autoplayVideos', val),
            activeThumbColor: primaryColor,
            title: Text("Autoplay Videos", style: theme.textTheme.bodyLarge),
            secondary: Icon(EvaIcons.video_outline, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedPreferencesSection(ThemeData theme, Color primaryColor) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text("Default Feed View", style: theme.textTheme.bodyLarge),
            subtitle: const Text(
              "Select your preferred starting view",
              style: TextStyle(fontSize: 12),
            ),
            leading: Icon(EvaIcons.grid_outline, color: primaryColor),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              color: theme.disabledColor,
            ),
            onTap: () => _showFeedViewPicker(theme),
          ),
        ],
      ),
    );
  }

  void _showFeedViewPicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Default Feed View",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 16.h),
              _buildPickerOption(
                theme: theme,
                title: "All Posts",
                icon: EvaIcons.grid_outline,
                isSelected: true, // Placeholder logic, should match state
                onTap: () => Navigator.pop(context),
              ),
              _buildPickerOption(
                theme: theme,
                title: "Following",
                icon: EvaIcons.people_outline,
                isSelected: false,
                onTap: () => Navigator.pop(context),
              ),
              _buildPickerOption(
                theme: theme,
                title: "Trending",
                icon: EvaIcons.trending_up_outline,
                isSelected: false,
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : theme.dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          color: isSelected ? theme.primaryColor : theme.disabledColor,
          size: 20.sp,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? theme.primaryColor
              : theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: theme.primaryColor,
              size: 22.sp,
            )
          : null,
    );
  }
}
