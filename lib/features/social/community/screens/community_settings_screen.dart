import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/features/social/community/models/community_model.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/widgets/message_banner.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';

class CommunitySettingsScreen extends StatefulWidget {
  final String communityId;
  const CommunitySettingsScreen({super.key, required this.communityId});

  @override
  State<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  final CommunityService _communityService = CommunityService();
  CommunityModel? _community;
  bool _isLoading = true;
  bool _isSaving = false;

  // Local settings state
  bool _isPrivate = false;
  bool _requiresJoinApproval = false;
  bool _requiresPostApproval = false;

  @override
  void initState() {
    super.initState();
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    try {
      final comm = await _communityService.getCommunity(widget.communityId);
      if (comm != null && mounted) {
        setState(() {
          _community = comm;
          _isPrivate = comm.isPrivate;
          _requiresJoinApproval = comm.requiresJoinApproval;
          _requiresPostApproval = comm.requiresPostApproval;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_community == null) return;

    // Optimistic Update
    setState(() {
      if (key == 'isPrivate') _isPrivate = value;
      if (key == 'requiresJoinApproval') _requiresJoinApproval = value;
      if (key == 'requiresPostApproval') _requiresPostApproval = value;
      _isSaving = true;
    });

    try {
      await _communityService.updateCommunity(widget.communityId, {key: value});
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Update successful',
          type: MessageType.success,
        );
      }
    } catch (e) {
      // Revert if failed
      _loadCommunity();
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to update setting',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : const Color(0xFF0B1C2C),
        elevation: 0,
        title: Text(
          'Community Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(theme, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(theme, "Privacy & Access"),
                        _buildSettingItem(
                          theme: theme,
                          isDark: isDark,
                          icon: Iconsax.lock_outline,
                          title: "Private Community",
                          subtitle: "Only members can view the content",
                          value: _isPrivate,
                          onChanged: (val) => _updateSetting('isPrivate', val),
                        ),
                        _buildSettingItem(
                          theme: theme,
                          isDark: isDark,
                          icon: Iconsax.user_add_outline,
                          title: "Member Approval",
                          subtitle: "Admin must approve join requests",
                          value: _requiresJoinApproval,
                          onChanged: (val) =>
                              _updateSetting('requiresJoinApproval', val),
                        ),
                        SizedBox(height: 24.h),
                        _buildSectionHeader(theme, "Content Management"),
                        _buildSettingItem(
                          theme: theme,
                          isDark: isDark,
                          icon: Iconsax.check_outline,
                          title: "Post Approval",
                          subtitle: "Admin must review all new posts",
                          value: _requiresPostApproval,
                          onChanged: (val) =>
                              _updateSetting('requiresPostApproval', val),
                        ),
                        SizedBox(height: 32.h),
                        _buildFooter(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    if (_community == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFF0B1C2C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: FadeInDown(
        duration: const Duration(milliseconds: 400),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 35.r,
                backgroundColor: theme.primaryColor,
                backgroundImage:
                    _community!.iconUrl != null &&
                        _community!.iconUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(_community!.iconUrl!)
                    : null,
                child:
                    (_community!.iconUrl == null ||
                        _community!.iconUrl!.isEmpty)
                    ? Text(
                        _community!.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _community!.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "${_community!.memberCount} Members",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: value
                ? theme.primaryColor.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: value ? theme.primaryColor : Colors.transparent,
                width: 4.w,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: value
                      ? theme.primaryColor.withValues(alpha: 0.1)
                      : isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: value
                      ? theme.primaryColor
                      : isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: value ? FontWeight.bold : FontWeight.w500,
                        color: value
                            ? theme.primaryColor
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          if (_isSaving)
            FadeIn(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12.w,
                    height: 12.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Syncing with cloud...",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              "Settings are automatically synchronized",
              style: TextStyle(fontSize: 12.sp, color: theme.disabledColor),
            ),
        ],
      ),
    );
  }
}
