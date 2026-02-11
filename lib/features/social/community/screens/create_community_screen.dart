import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:provider/provider.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _rulesControllers = [];

  File? _iconFile;
  File? _bannerFile;
  bool _isPrivate = false;
  bool _isLoading = false;

  final CommunityService _communityService = CommunityService();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var c in _rulesControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage({required bool isIcon}) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isIcon) {
            _iconFile = File(image.path);
          } else {
            _bannerFile = File(image.path);
          }
        });
      }
    } catch (e) {
      MessageBanner.show(
        context,
        message: 'Failed to pick image',
        type: MessageType.error,
      );
    }
  }

  void _addRuleField() {
    setState(() {
      _rulesControllers.add(TextEditingController());
    });
  }

  void _removeRuleField(int index) {
    setState(() {
      _rulesControllers[index].dispose();
      _rulesControllers.removeAt(index);
    });
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate rules (remove empty ones)
    final rules = _rulesControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthService>().user;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final communityId = await _communityService.createCommunity(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        rules: rules,
        creatorId: user.uid,
        iconFile: _iconFile,
        bannerFile: _bannerFile,
        isPrivate: _isPrivate,
      );

      if (communityId != null) {
        if (mounted) {
          MessageBanner.show(
            context,
            message: 'Community created successfully!',
            type: MessageType.success,
          );
          // Navigate to the new community or back
          context.pop(true);
        }
      } else {
        throw Exception('Failed to create community');
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Error: ${e.toString()}',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Community'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createCommunity,
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Images Section ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Picker
                  GestureDetector(
                    onTap: () => _pickImage(isIcon: true),
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                        image: _iconFile != null
                            ? DecorationImage(
                                image: FileImage(_iconFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _iconFile == null
                          ? Icon(Icons.camera_alt_outlined, color: Colors.grey)
                          : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Banner Picker
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(isIcon: false),
                      child: Container(
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: theme.dividerColor),
                          image: _bannerFile != null
                              ? DecorationImage(
                                  image: FileImage(_bannerFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _bannerFile == null
                            ? Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Add Banner',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // --- Basic Info ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Community Name',
                  hintText: 'e.g. Mathematics Enthusiasts',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.length < 3) return 'Name must be at least 3 chars';
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this community about?',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // --- Privacy ---
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Private Community'),
                subtitle: const Text('Only approved members can view posts'),
                value: _isPrivate,
                onChanged: (val) => setState(() => _isPrivate = val),
              ),
              const Divider(),
              SizedBox(height: 16.h),

              // --- Rules ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rules',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addRuleField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Rule'),
                  ),
                ],
              ),
              if (_rulesControllers.isEmpty)
                const Text(
                  'No rules added yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ...List.generate(_rulesControllers.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rulesControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Rule ${index + 1}',
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeRuleField(index),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
