import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:math/features/social/community/models/community_resource_model.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:provider/provider.dart';

class AddCommunityResourceScreen extends StatefulWidget {
  final String communityId;
  final bool isCreator;

  const AddCommunityResourceScreen({
    super.key,
    required this.communityId,
    required this.isCreator,
  });

  @override
  State<AddCommunityResourceScreen> createState() =>
      _AddCommunityResourceScreenState();
}

class _AddCommunityResourceScreenState
    extends State<AddCommunityResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  final _communityService = CommunityService();

  ResourceType _selectedType = ResourceType.video;
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_selectedType == ResourceType.video) {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() => _selectedFile = File(video.path));
      }
    } else if (_selectedType == ResourceType.document) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFile = File(result.files.single.path!));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthService>().user?.uid;
    if (userId == null) return;

    setState(() => _isUploading = true);

    try {
      String finalUrl = _urlController.text.trim();

      if (_selectedFile != null) {
        // Simple progress simulation or actual progress if supported
        final uploadedUrl = await _communityService.uploadResourceFile(
          communityId: widget.communityId,
          resourceId: DateTime.now().millisecondsSinceEpoch
              .toString(), // Temp ID
          file: _selectedFile!,
          type: _selectedType.name,
        );

        if (uploadedUrl == null) throw Exception("Upload failed");
        finalUrl = uploadedUrl;
      }

      if (finalUrl.isEmpty && _selectedType == ResourceType.link) {
        MessageBanner.show(
          context,
          message: "URL is required for links",
          type: MessageType.error,
        );
        setState(() => _isUploading = false);
        return;
      }

      await _communityService.addResource(
        communityId: widget.communityId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        url: finalUrl,
        userId: userId,
        isAutoApproved: widget.isCreator,
      );

      if (mounted) {
        MessageBanner.show(
          context,
          message: widget.isCreator
              ? "Resource added"
              : "Submitted for approval",
          type: MessageType.success,
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: "Failed to add resource",
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Resource",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _submit,
              child: Text(
                "Submit",
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text(
                    "Uploading resource...",
                    style: TextStyle(color: theme.disabledColor),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(theme),
                    SizedBox(height: 24.h),
                    _buildTextField(
                      theme,
                      controller: _titleController,
                      label: "Title",
                      hint: "Resource Name",
                      validator: (v) => v?.isEmpty ?? true ? "Required" : null,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      theme,
                      controller: _descController,
                      label: "Description",
                      hint: "Briefly explain what this is",
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? "Required" : null,
                    ),
                    SizedBox(height: 24.h),
                    if (_selectedType == ResourceType.link)
                      _buildTextField(
                        theme,
                        controller: _urlController,
                        label: "External Link URL",
                        hint: "https://example.com/...",
                        validator: (v) =>
                            v?.isEmpty ?? true ? "Required" : null,
                      )
                    else
                      _buildUploadSection(theme),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Resource Type",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.disabledColor,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: ResourceType.values.map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedType = type;
                  _selectedFile = null;
                }),
                child: Container(
                  margin: EdgeInsets.only(
                    right: type == ResourceType.values.last ? 0 : 8.w,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor.withValues(alpha: 0.1)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryColor
                          : theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        type == ResourceType.video
                            ? Iconsax.video_circle_outline
                            : type == ResourceType.document
                            ? Iconsax.document_text_outline
                            : Iconsax.link_outline,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.disabledColor,
                        size: 20,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        type.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isSelected
                              ? theme.primaryColor
                              : theme.disabledColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUploadSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upload File",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.disabledColor,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 32.h),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFile != null
                      ? Iconsax.tick_circle_outline
                      : Iconsax.document_upload_outline,
                  color: _selectedFile != null
                      ? Colors.green
                      : theme.primaryColor,
                  size: 32,
                ),
                SizedBox(height: 8.h),
                Text(
                  _selectedFile != null
                      ? _selectedFile!.path.split('/').last
                      : "Select ${_selectedType.name} file",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: _selectedFile != null
                        ? theme.textTheme.bodyLarge?.color
                        : theme.disabledColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.disabledColor,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(16.w),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
