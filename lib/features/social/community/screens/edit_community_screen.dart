import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/widgets/message_banner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditCommunityScreen extends StatefulWidget {
  final String communityId;
  const EditCommunityScreen({super.key, required this.communityId});

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  final CommunityService _communityService = CommunityService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _rulesController;

  bool _isPrivate = false;
  bool _requiresJoinApproval = false;
  bool _requiresPostApproval = false;

  String? _profileUrl;
  String? _bannerUrl;
  File? _newProfileImage;
  File? _newBannerImage;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _rulesController = TextEditingController();
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    try {
      final community = await _communityService.getCommunity(
        widget.communityId,
      );
      if (community != null && mounted) {
        setState(() {
          _nameController.text = community.name;
          _descriptionController.text = community.description;
          _rulesController.text = community.rules.join('\n');
          _isPrivate = community.isPrivate;
          _requiresJoinApproval = community.requiresJoinApproval;
          _requiresPostApproval = community.requiresPostApproval;
          _profileUrl = community.iconUrl;
          _bannerUrl = community.bannerUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? profileUrl = _profileUrl;
      String? bannerUrl = _bannerUrl;

      if (_newProfileImage != null) {
        profileUrl = await _communityService.uploadCommunityPhoto(
          communityId: widget.communityId,
          file: _newProfileImage!,
          isBanner: false,
        );
      }

      if (_newBannerImage != null) {
        bannerUrl = await _communityService.uploadCommunityPhoto(
          communityId: widget.communityId,
          file: _newBannerImage!,
          isBanner: true,
        );
      }

      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'iconUrl': profileUrl,
        'bannerUrl': bannerUrl,
        'rules': _rulesController.text
            .trim()
            .split('\n')
            .where((r) => r.isNotEmpty)
            .toList(),
        'isPrivate': _isPrivate,
        'requiresJoinApproval': _requiresJoinApproval,
        'requiresPostApproval': _requiresPostApproval,
      };

      await _communityService.updateCommunity(widget.communityId, updates);
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Community updated',
          type: MessageType.success,
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Update failed',
          type: MessageType.error,
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Community',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_outline),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: TextButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      theme,
                      'Basic Information',
                      Iconsax.info_circle_outline,
                    ),
                    SizedBox(height: 16.h),
                    _buildMediaSection(theme),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      theme,
                      controller: _nameController,
                      label: 'Community Name',
                      hint: 'Enter community name',
                      validator: (val) =>
                          val?.isEmpty ?? true ? 'Required' : null,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      theme,
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'What is this community about?',
                      maxLines: 4,
                      validator: (val) =>
                          val?.isEmpty ?? true ? 'Required' : null,
                    ),
                    SizedBox(height: 24.h),
                    _buildSectionHeader(
                      theme,
                      'Privacy & Access',
                      Iconsax.security_safe_outline,
                    ),
                    SizedBox(height: 12.h),
                    _buildSwitchTile(
                      theme,
                      icon: Iconsax.lock_outline,
                      title: 'Private Community',
                      subtitle: 'Only members can see content',
                      value: _isPrivate,
                      onChanged: (val) => setState(() => _isPrivate = val),
                    ),
                    _buildSwitchTile(
                      theme,
                      icon: Iconsax.user_add_outline,
                      title: 'Approval Required to Join',
                      subtitle: 'Moderators must approve scholars',
                      value: _requiresJoinApproval,
                      onChanged: (val) =>
                          setState(() => _requiresJoinApproval = val),
                    ),
                    _buildSwitchTile(
                      theme,
                      icon: Iconsax.check_outline,
                      title: 'Approval Required for Posts',
                      subtitle: 'Moderate all shared insights',
                      value: _requiresPostApproval,
                      onChanged: (val) =>
                          setState(() => _requiresPostApproval = val),
                    ),
                    SizedBox(height: 24.h),
                    _buildSectionHeader(
                      theme,
                      'Community Rules',
                      Iconsax.judge_outline,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      theme,
                      controller: _rulesController,
                      label: 'Rules (one per line)',
                      hint: '1. Be respectful\n2. Share quality content',
                      maxLines: 6,
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        SizedBox(width: 8.w),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.disabledColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.disabledColor, fontSize: 14.sp),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: EdgeInsets.all(16.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData icon = Iconsax.setting_outline,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: value
                ? theme.primaryColor.withValues(alpha: 0.05)
                : theme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16.r),
            border: Border(
              left: BorderSide(
                color: value ? theme.primaryColor : Colors.transparent,
                width: 4.w,
              ),
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
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
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: value ? FontWeight.bold : FontWeight.w600,
                        color: value
                            ? theme.primaryColor
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.75,
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

  Widget _buildMediaSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Community Brand",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.disabledColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            // Profile Image
            GestureDetector(
              onTap: () => _pickImage(false),
              child: Stack(
                children: [
                  Container(
                    width: 70.r,
                    height: 70.r,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                      ),
                      image: _newProfileImage != null
                          ? DecorationImage(
                              image: FileImage(_newProfileImage!),
                              fit: BoxFit.cover,
                            )
                          : (_profileUrl != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      _profileUrl!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                    ),
                    child: (_newProfileImage == null && _profileUrl == null)
                        ? Icon(
                            Iconsax.camera_outline,
                            color: theme.primaryColor,
                            size: 24,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.edit_2_outline,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Banner Image
            Expanded(
              child: GestureDetector(
                onTap: () => _pickImage(true),
                child: Stack(
                  children: [
                    Container(
                      height: 70.h,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.2),
                        ),
                        image: _newBannerImage != null
                            ? DecorationImage(
                                image: FileImage(_newBannerImage!),
                                fit: BoxFit.cover,
                              )
                            : (_bannerUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        _bannerUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child: (_newBannerImage == null && _bannerUrl == null)
                          ? Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.image_outline,
                                    color: theme.disabledColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Add Banner",
                                    style: TextStyle(
                                      color: theme.disabledColor,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.edit_2_outline,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(bool isBanner) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        if (isBanner) {
          _newBannerImage = File(image.path);
        } else {
          _newProfileImage = File(image.path);
        }
      });
    }
  }
}
