import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:math/data/models/user_model.dart';
import 'package:math/features/social/feed/models/post_model.dart';
import 'package:math/features/social/community/models/community_model.dart';
import 'package:math/data/models/subject_model.dart';
import 'package:math/services/auth_service.dart';
import 'package:math/services/api_service.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/features/social/community/models/community_member_model.dart';
import 'package:math/services/logger_service.dart';
import 'package:math/services/media_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:math/router/app_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:math/screens/image_view_screen.dart';
import 'package:math/widgets/message_banner.dart';
import 'package:math/features/social/create_post/widgets/post_timer_bottom_sheet.dart';
import 'package:math/features/social/create_post/widgets/category_bottom_sheet.dart';
import 'package:math/features/social/create_post/widgets/subject_bottom_sheet.dart';
import 'package:math/features/social/create_post/widgets/post_settings_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math/widgets/linkable_text.dart';
import 'package:math/features/social/feed/widgets/social_video_player.dart';
import 'package:math/utils/avatar_color_generator.dart';
import 'package:animate_do/animate_do.dart'; // Ensure it's in pubspec or use standard animations

class CreatePostScreen extends StatefulWidget {
  final PostModel? quotedPost;
  final String? communityId;
  final String? communityName;
  final String? communityIcon;

  const CreatePostScreen({
    super.key,
    this.quotedPost,
    this.communityId,
    this.communityName,
    this.communityIcon,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final LinkableTextEditingController _textController =
      LinkableTextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final ApiService _apiService = ApiService();
  final CommunityService _communityService = CommunityService();
  bool _isLoading = false;
  List<AssetEntity> _imageAssets = [];
  final ReplyPermission _replyPermission = ReplyPermission.everyone;

  // 🚀 URL Detection State
  String? _detectedUrl;
  String? _attachedLink;

  // 🚀 Enhanced Community Fields
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  List<SubjectModel> _availableSubjects = [];
  final List<String> _tags = [];
  List<Map<String, dynamic>> _tagSuggestions = [];
  PostCategory _postCategory = PostCategory.general;

  // 🚀 Community Fields
  String? _selectedCommunityId;
  String? _selectedCommunityName;
  String? _selectedCommunityIcon;

  // Poll State
  bool _isPollActive = false;
  final List<TextEditingController> _pollOptions = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultipleVotes = false;
  int? _expirationDays = 30; // 🚀 Default to 30 days
  bool _commentsDisabled = false;
  bool _sharingDisabled = false;
  bool _resharingDisabled = false;

  // 🚀 User Tagging Suggestions
  List<UserModel> _userSuggestions = [];
  final List<String> _taggedUserIds = [];
  final List<String> _taggedUserNames = [];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateState);
    for (var controller in _pollOptions) {
      controller.addListener(_updateState);
    }
    _selectedCommunityId = widget.communityId;
    _selectedCommunityName = widget.communityName;
    _selectedCommunityIcon = widget.communityIcon;
    _loadUserSubjects();
  }

  Future<void> _loadUserSubjects() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();
        final String medium = userData?['learningMedium'] as String? ?? 'en';
        final List<dynamic>? grades = userData?['grades'] as List<dynamic>?;
        final String? gradeId = (grades != null && grades.isNotEmpty)
            ? grades.first.toString()
            : null;

        if (gradeId != null) {
          final subjects = await _apiService.getSubjects(gradeId, medium);
          if (mounted) {
            setState(() {
              _availableSubjects = subjects;
            });
          }
        }
      }
    } catch (e) {
      logger.e('Error loading subjects', error: e);
    }
  }

  void _updateState() {
    // URL Detection
    final RegExp urlRegex = RegExp(
      r'((https?:\/\/)|(www\.))[^\s]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(_textController.text);
    final newUrl = match?.group(0);

    if (newUrl != _detectedUrl) {
      setState(() {
        _detectedUrl = newUrl;
      });
    }

    // --- Mention Detection ---
    final text = _textController.text;
    final selection = _textController.selection;

    if (selection.isCollapsed && selection.baseOffset > 0) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      final lastAt = textBeforeCursor.lastIndexOf('@');

      if (lastAt != -1 && !textBeforeCursor.substring(lastAt).contains(' ')) {
        final query = textBeforeCursor.substring(lastAt + 1);
        if (query.length >= 2) {
          _searchUsersForTagging(query);
        } else {
          if (_userSuggestions.isNotEmpty) {
            setState(() => _userSuggestions = []);
          }
        }
      } else {
        if (_userSuggestions.isNotEmpty) {
          setState(() => _userSuggestions = []);
        }
      }
    } else {
      if (_userSuggestions.isNotEmpty) {
        setState(() => _userSuggestions = []);
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _searchUsersForTagging(String query) async {
    final results = await _apiService.searchUsers(query);
    if (mounted) {
      setState(() {
        _userSuggestions = results
            .where((u) => u.allowTagging) // Respect setting
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagController.dispose();
    for (var controller in _pollOptions) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canPost {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasImages = _imageAssets.isNotEmpty;

    // If poll is active, we MUST have text (question) AND at least 2 valid options
    if (_isPollActive) {
      final validOptions = _pollOptions
          .where((c) => c.text.trim().isNotEmpty)
          .length;
      return hasText && validOptions >= 2;
    }

    return hasText || hasImages || (widget.quotedPost != null);
  }

  Future<void> _pickImages() async {
    // ... Simplified permission handling
    PermissionStatus status;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Request both photos and videos
        final statuses = await [Permission.photos, Permission.videos].request();
        status =
            statuses[Permission.photos] == PermissionStatus.granted &&
                statuses[Permission.videos] == PermissionStatus.granted
            ? PermissionStatus.granted
            : PermissionStatus.denied;
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request(); // iOS
    }

    if (!context.mounted) return;
    if (!status.isGranted && !status.isLimited) {
      MessageBanner.show(
        context,
        message: 'Permission denied',
        type: MessageType.error,
      );
      return;
    }

    if (!mounted) return;

    final theme = Theme.of(context);
    final pickerTheme = InstaAssetPicker.themeData(theme.primaryColor).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        elevation: 0,
      ),
    );

    await InstaAssetPicker.pickAssets(
      context,
      pickerConfig: InstaAssetPickerConfig(
        title: 'Select media',
        pickerTheme: pickerTheme,
        gridCount: 3,
        specialItemBuilder: (context, path, length) {
          return const Center(child: Icon(Iconsax.camera_outline, size: 48));
        },
      ),
      requestType: RequestType.common, // Allow both images and videos
      maxAssets: 4,
      selectedAssets: _imageAssets,
      onCompleted: (Stream<InstaAssetsExportDetails> stream) {
        stream.listen((details) {
          if (mounted) {
            final selected = details.selectedAssets;
            final videos = selected
                .where((a) => a.type == AssetType.video)
                .toList();

            if (videos.length > 1) {
              MessageBanner.show(
                context,
                message: 'You can only upload 1 video per post',
                type: MessageType.error,
              );
              return;
            }

            setState(() {
              _imageAssets = selected;
            });
          }
        });
        Navigator.pop(context);
      },
    );
  }

  Future<Map<String, dynamic>> _uploadAssets(
    String postId,
    String userId,
  ) async {
    List<String> imageUrls = [];
    String? videoUrl;

    for (int i = 0; i < _imageAssets.length; i++) {
      final asset = _imageAssets[i];
      final File? file = await asset.file;
      if (file == null) continue;

      File fileToUpload = file;
      try {
        if (asset.type == AssetType.image) {
          fileToUpload = await MediaService().compressImage(file);
        } else if (asset.type == AssetType.video) {
          fileToUpload = await MediaService().compressVideo(file);
        }
      } catch (e) {
        logger.e('Compression failed, using original', error: e);
      }

      if (asset.type == AssetType.image) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child(userId)
            .child('${postId}_${imageUrls.length}.jpg');
        final snapshot = await ref.putFile(fileToUpload);
        imageUrls.add(await snapshot.ref.getDownloadURL());
      } else if (asset.type == AssetType.video) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('post_videos')
            .child(userId)
            .child('$postId.mp4');
        final snapshot = await ref.putFile(fileToUpload);
        videoUrl = await snapshot.ref.getDownloadURL();
      }
    }
    return {'imageUrls': imageUrls, 'videoUrl': videoUrl};
  }

  Future<void> _publishPost() async {
    if (!_canPost) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final user = context.read<AuthService>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final postDoc = FirebaseFirestore.instance.collection('posts').doc();
      List<String> imageUrls = [];
      String? videoUrl;

      if (_imageAssets.isNotEmpty) {
        final assets = await _uploadAssets(postDoc.id, user.uid);
        imageUrls = assets['imageUrls'] as List<String>;
        videoUrl = assets['videoUrl'] as String?;
      }

      PollData? pollData;
      if (_isPollActive) {
        final options = _pollOptions
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (!context.mounted) return;
        if (options.length < 2) {
          MessageBanner.show(
            context,
            message: 'Poll must have at least 2 options',
            type: MessageType.error,
          );
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        // Use selected expiration or default to 7 days for polls if not set
        final durationDays = _expirationDays ?? 7;

        pollData = PollData(
          options: options,
          voteCounts: List.filled(options.length, 0),
          totalVotes: 0,
          lengthDays: durationDays,
          endsAt: Timestamp.fromDate(
            DateTime.now().add(Duration(days: durationDays)),
          ),
          allowMultipleVotes: _allowMultipleVotes,
        );
      }

      // 🚀 Fetch User Profile for filtering metadata
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();

      // 🚀 Check for Ban Status
      final bool isBanned = userData?['isBanned'] as bool? ?? false;
      if (isBanned) {
        final Timestamp? banExpiresAt = userData?['banExpiresAt'] as Timestamp?;
        final String? banReason = userData?['banReason'] as String?;

        if (banExpiresAt == null ||
            banExpiresAt.toDate().isAfter(DateTime.now())) {
          String message = "You are banned from posting.";
          if (banExpiresAt != null) {
            message +=
                " Ban expires on ${DateFormat('MMM d, y').format(banExpiresAt.toDate())}.";
          } else {
            message += " This ban is permanent.";
          }
          if (banReason != null && banReason.isNotEmpty) {
            message += "\nReason: $banReason";
          }

          if (mounted) {
            setState(() => _isLoading = false);
            MessageBanner.show(
              context,
              message: message,
              type: MessageType.error,
            );
          }
          return;
        }
      }

      final String? medium = userData?['learningMedium'] as String?;
      final List<dynamic>? grades = userData?['grades'] as List<dynamic>?;
      final String? gradeId = (grades != null && grades.isNotEmpty)
          ? grades.first.toString()
          : null;

      final newPost = PostModel(
        postId: postDoc.id,
        authorId: user.uid,
        authorName: user.displayName ?? 'Anonymous User',
        authorPhotoUrl: user.photoURL,
        text: _textController.text.trim(),
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        createdAt: Timestamp.now(),
        replyPermission: _replyPermission,
        pollData: pollData,
        expiresAt: _expirationDays != null
            ? Timestamp.fromDate(
                DateTime.now().add(Duration(days: _expirationDays!)),
              )
            : null,
        gradeId: gradeId,
        medium: medium,
        originalPostId: widget.quotedPost?.postId,
        originalPost: widget.quotedPost,
        subjectId: _selectedSubjectId,
        subjectName: _selectedSubjectName,
        tags: _tags,
        category: _postCategory,
        commentsDisabled: _commentsDisabled,
        sharingDisabled: _sharingDisabled,
        resharingDisabled: _resharingDisabled,
        communityId: _selectedCommunityId,
        communityName: _selectedCommunityName,
        communityIcon: _selectedCommunityIcon,
        linkUrl: _attachedLink,
        mentions: _taggedUserIds,
        mentionedNames: _taggedUserNames,
      );

      // --- Community Post Approval Logic ---
      PostStatus postStatus = PostStatus.approved;
      CommunityModel? selectedCommunity;
      if (_selectedCommunityId != null) {
        selectedCommunity = await _communityService.getCommunity(
          _selectedCommunityId!,
        );
        final member = await _communityService.getMember(
          _selectedCommunityId!,
          user.uid,
        );

        if (member != null && member.status == MemberStatus.pending) {
          postStatus = PostStatus.draft;
        } else if (selectedCommunity != null &&
            selectedCommunity.requiresPostApproval) {
          // Check if user is admin/owner
          final bool isAdmin =
              member != null &&
              (member.role == CommunityRole.admin ||
                  member.role == CommunityRole.moderator ||
                  selectedCommunity.creatorId == user.uid);

          if (!isAdmin) {
            postStatus = PostStatus.pending;
          }
        }
      }

      final finalPost = newPost.copyWith(status: postStatus);

      // --- Admin Notification for Pending Posts ---
      if (postStatus == PostStatus.pending && selectedCommunity != null) {
        await SocialService().sendNotification(
          toUserId: selectedCommunity.creatorId,
          title: 'New Post Pending Approval',
          message:
              '${user.displayName ?? "A user"} posted in "${selectedCommunity.name}". Needs your review.',
          type: 'post_pending_approval',
          senderId: user.uid,
          targetContentId: selectedCommunity.id,
        );
      }

      // 3. Create Post & Handle Repost Logic
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // A. If it's a repost, increment the original post's reShareCount
        if (finalPost.originalPostId != null) {
          final originalPostRef = FirebaseFirestore.instance
              .collection('posts')
              .doc(finalPost.originalPostId);

          transaction.update(originalPostRef, {
            'reShareCount': FieldValue.increment(1),
          });
        }

        // B. Create the new post
        transaction.set(postDoc, finalPost.toJson());
      });

      // C. Update Tag Counts (Outside Transaction)
      for (final tag in finalPost.tags) {
        await SocialService().updateTagCount(tag, 1);
      }

      // 4. Send Notification if Repost (Outside Transaction)
      if (finalPost.originalPostId != null && finalPost.originalPost != null) {
        // Don't notify self
        if (finalPost.originalPost!.authorId != user.uid) {
          await SocialService().sendNotification(
            toUserId: finalPost.originalPost!.authorId,
            title: 'New Repost',
            message: '${user.displayName ?? "Someone"} reposted your post.',
            type: 'postReply', // reusing existing type
            senderId: user.uid,
            senderName: user.displayName ?? 'Unknown',
            senderPhotoUrl: user.photoURL,
            targetContentId: finalPost.originalPostId,
          );
        }
      }

      if (mounted) {
        if (postStatus == PostStatus.pending) {
          MessageBanner.show(
            context,
            message: 'Post submitted for approval',
            type: MessageType.info,
          );
        }
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      logger.e("Post failed", error: e);
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to post',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryBottomSheet(
        selectedCategory: _postCategory,
        onCategorySelected: (category) {
          setState(() => _postCategory = category);
        },
      ),
    );
  }

  void _showSubjectPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SubjectBottomSheet(
        selectedSubjectId: _selectedSubjectId,
        subjects: _availableSubjects,
        onSubjectSelected: (id, name) {
          setState(() {
            _selectedSubjectId = id;
            _selectedSubjectName = name;
          });
        },
      ),
    );
  }

  Widget _buildQuotePreview(ThemeData theme) {
    final post = widget.quotedPost!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Author & Community
          Row(
            children: [
              SizedBox(
                width: 32.r,
                height: 32.r,
                child: Stack(
                  children: [
                    // User Photo
                    Align(
                      alignment: post.communityId != null
                          ? Alignment.bottomRight
                          : Alignment.center,
                      child: CircleAvatar(
                        radius: post.communityId != null ? 10.r : 14.r,
                        backgroundColor: AvatarColorGenerator.getColorForUser(
                          post.authorId,
                        ),
                        backgroundImage:
                            post.authorPhotoUrl != null &&
                                post.authorPhotoUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(post.authorPhotoUrl!)
                            : null,
                        child:
                            (post.authorPhotoUrl == null ||
                                post.authorPhotoUrl!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: post.communityId != null ? 8.sp : 12.sp,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    // Community Icon
                    if (post.communityId != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 18.r,
                          height: 18.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9.r),
                            child:
                                (post.communityIcon != null &&
                                    post.communityIcon!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: post.communityIcon!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: theme.primaryColor,
                                    child: Icon(
                                      Icons.groups_rounded,
                                      size: 10.r,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${post.authorName}${post.communityId != null ? " in ${post.communityName}" : ""}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // 🚀 Category, Subject, Tags Row
          if (post.subjectId != null ||
              post.category != PostCategory.general ||
              post.tags.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (post.subjectId != null)
                      Container(
                        margin: EdgeInsets.only(right: 6.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 10.sp,
                              color: theme.primaryColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              post.subjectName!,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (post.category != PostCategory.general)
                      Container(
                        margin: EdgeInsets.only(right: 6.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            post.category,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          post.category.name[0].toUpperCase() +
                              post.category.name.substring(1),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: _getCategoryColor(post.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ...post.tags.take(3).map((tag) {
                      return Container(
                        margin: EdgeInsets.only(right: 6.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // 🚀 Helpful Answer Indicator
          if (post.helpfulAnswerCount > 0)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 12.sp, color: Colors.green),
                  SizedBox(width: 4.w),
                  Text(
                    '${post.helpfulAnswerCount} helpful answer${post.helpfulAnswerCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (post.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                post.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, height: 1.3),
              ),
            ),

          // Poll Summary
          if (post.pollData != null)
            Container(
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.poll_outlined,
                        size: 12.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Poll',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  ...post.pollData!.options
                      .take(2)
                      .map(
                        (opt) => Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle_outlined,
                                size: 10.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  opt,
                                  style: TextStyle(fontSize: 11.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),

          // Quoted Media Preview
          if (post.imageUrls.isNotEmpty ||
              post.imageUrl != null ||
              post.videoUrl != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: _buildQuotedMediaPreview(post),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuotedMediaPreview(PostModel post) {
    final urls = post.imageUrls;
    final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
    const double phi = 1.61803398875; // 🚀 Golden Ratio

    Widget buildVideo() {
      return SocialVideoPlayer(videoUrl: post.videoUrl!, autoPlay: false);
    }

    Widget buildImage(String url, int index) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double goldenHeight = width / phi;

        if (hasVideo && urls.isEmpty) {
          return SizedBox(
            height: goldenHeight,
            width: double.infinity,
            child: buildVideo(),
          );
        }

        if (!hasVideo && urls.length == 1) {
          return SizedBox(
            height: goldenHeight,
            width: double.infinity,
            child: buildImage(urls[0], 0),
          );
        }

        return SizedBox(
          height: goldenHeight,
          child: Builder(
            builder: (context) {
              if (hasVideo && urls.length == 1) {
                return Row(
                  children: [
                    Expanded(child: buildVideo()),
                    SizedBox(width: 1.w),
                    Expanded(child: buildImage(urls[0], 0)),
                  ],
                );
              }

              if (urls.length == 2 && !hasVideo) {
                return Row(
                  children: [
                    Expanded(child: buildImage(urls[0], 0)),
                    SizedBox(width: 1.w),
                    Expanded(child: buildImage(urls[1], 1)),
                  ],
                );
              }

              if (hasVideo && urls.length == 2) {
                return Row(
                  children: [
                    Expanded(child: buildVideo()),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: buildImage(urls[0], 0)),
                          SizedBox(height: 1.h),
                          Expanded(child: buildImage(urls[1], 1)),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (urls.length == 3 && !hasVideo) {
                return Row(
                  children: [
                    Expanded(child: buildImage(urls[0], 0)),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: buildImage(urls[1], 1)),
                          SizedBox(height: 1.h),
                          Expanded(child: buildImage(urls[2], 2)),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: hasVideo ? buildVideo() : buildImage(urls[0], 0),
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: buildImage(urls[hasVideo ? 0 : 1], 1)),
                        SizedBox(height: 1.h),
                        Expanded(child: buildImage(urls[hasVideo ? 1 : 2], 2)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUrlTooltip(ThemeData theme) {
    if (_detectedUrl == null || _attachedLink == _detectedUrl) {
      return const SizedBox.shrink();
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.link_outline, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                'Add Link: $_detectedUrl',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () {
                setState(() {
                  _attachedLink = _detectedUrl;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachedLink(ThemeData theme) {
    if (_attachedLink == null) return const SizedBox.shrink();

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.link_outline,
              color: theme.primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attached Link',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _attachedLink!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _attachedLink = null;
              });
            },
            icon: Icon(
              Iconsax.close_circle_outline,
              color: Colors.grey,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<AuthService>().user;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.feedPath);
            }
          },
          icon: Icon(Icons.close, color: theme.iconTheme.color),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: ElevatedButton(
              onPressed: (_canPost && !_isLoading) ? _publishPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                disabledBackgroundColor: theme.primaryColor.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: CircleAvatar(
                        radius: 20.r,
                        backgroundImage: (user?.photoURL != null)
                            ? CachedNetworkImageProvider(user!.photoURL!)
                            : null,
                        child: (user?.photoURL == null)
                            ? Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Input Area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply constraint button (e.g. "Everyone")
                          if (_replyPermission != ReplyPermission.everyone)
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.primaryColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: 14.sp,
                                      color: theme.primaryColor,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "Reply constraint active",
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          TextField(
                            controller: _textController,
                            autofocus: false,
                            maxLines: null,
                            minLines: 3,
                            style: TextStyle(fontSize: 18.sp),
                            decoration: const InputDecoration(
                              hintText: "What to ask?",
                              border: InputBorder.none,
                            ),
                          ),

                          if (_imageAssets.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child: _buildImageGrid(),
                            ),

                          // 🚀 Poll UI
                          if (_isPollActive)
                            Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.poll_outlined,
                                                size: 20.sp,
                                                color: theme.primaryColor,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Poll',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.sp,
                                                  color: theme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16.h),
                                          ...List.generate(_pollOptions.length, (
                                            index,
                                          ) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 12.h,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller:
                                                          _pollOptions[index],
                                                      decoration: InputDecoration(
                                                        hintText:
                                                            'Option ${index + 1}',
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 16.w,
                                                              vertical: 12.h,
                                                            ),
                                                        filled: true,
                                                        fillColor:
                                                            theme.brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.05,
                                                                  )
                                                            : Colors
                                                                  .grey
                                                                  .shade50,
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.r,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: theme
                                                                .dividerColor,
                                                          ),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12.r,
                                                                  ),
                                                              borderSide: BorderSide(
                                                                color: theme
                                                                    .dividerColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    ),
                                                              ),
                                                            ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12.r,
                                                                  ),
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: theme
                                                                        .primaryColor,
                                                                  ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (_pollOptions.length > 2)
                                                    IconButton(
                                                      icon: Icon(
                                                        Iconsax
                                                            .minus_cirlce_outline,
                                                        size: 20.sp,
                                                        color: Colors.red
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _pollOptions[index]
                                                              .dispose();
                                                          _pollOptions.removeAt(
                                                            index,
                                                          );
                                                        });
                                                      },
                                                    ),
                                                ],
                                              ),
                                            );
                                          }),
                                          if (_pollOptions.length < 4)
                                            TextButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  _pollOptions.add(
                                                    TextEditingController(),
                                                  );
                                                });
                                              },
                                              icon: const Icon(
                                                Iconsax.add_circle_outline,
                                              ),
                                              label: const Text('Add option'),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    theme.primaryColor,
                                              ),
                                            ),
                                          const Divider(),
                                          SwitchListTile(
                                            title: Text(
                                              'Allow multiple answers',
                                              style: TextStyle(fontSize: 13.sp),
                                            ),
                                            value: _allowMultipleVotes,
                                            onChanged: (bool value) {
                                              setState(() {
                                                _allowMultipleVotes = value;
                                              });
                                            },
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Close button to remove poll
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: Icon(
                                          Iconsax.close_circle_outline,
                                          size: 20.sp,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPollActive = false;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // 🚀 Attached Link Preview
                          _buildAttachedLink(theme),

                          // Quote Preview (Re-post)
                          if (widget.quotedPost != null)
                            Padding(
                              padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
                              child: _buildQuotePreview(theme),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Tags Section ---
            if (isKeyboardVisible && _tags.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: _tags
                      .map(
                        (tag) => Chip(
                          label: Text(
                            '#$tag',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                          deleteIcon: Icon(Icons.close, size: 14.sp),
                          backgroundColor: theme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // --- Community Selection Bar ---
            _buildCommunitySelector(theme),

            // 🚀 URL Tooltip (Floats above bottom section)
            _buildUrlTooltip(theme),

            // 🚀 User Suggestions for @mentions
            _buildUserSuggestions(theme),

            // Dynamic Bottom Section
            _buildBottomSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitySelector(ThemeData theme) {
    return GestureDetector(
      onTap: _showCommunityPicker,
      child: Container(
        margin: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            if (_selectedCommunityId != null)
              CircleAvatar(
                radius: 12.r,
                backgroundImage: _selectedCommunityIcon != null
                    ? CachedNetworkImageProvider(_selectedCommunityIcon!)
                    : null,
                child: _selectedCommunityIcon == null
                    ? Icon(Iconsax.people_outline, size: 14.sp)
                    : null,
              )
            else
              Icon(
                Iconsax.global_outline,
                size: 18.sp,
                color: theme.primaryColor,
              ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _selectedCommunityName ?? 'Select Community',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: _selectedCommunityId != null
                      ? theme.primaryColor
                      : Colors.grey,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_right, size: 18.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _showCommunityPicker() async {
    final result = await context.pushNamed(AppRouter.communitySelectionName);
    if (result is CommunityModel && mounted) {
      setState(() {
        _selectedCommunityId = result.id;
        _selectedCommunityName = result.name;
        _selectedCommunityIcon = result.iconUrl;
      });
    }
  }

  void _showTagInput() {
    // Initial load of popular tags
    SocialService().getPopularTags().then((tags) {
      if (mounted) setState(() => _tagSuggestions = tags);
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 24.h,
              ),
              backgroundColor: Colors.transparent, // IMPORTANT
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border(
                    top: BorderSide(
                      width: 3,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.4
                            : 0.15,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildTagContent(theme, setDialogState)],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTagContent(ThemeData theme, StateSetter setDialogState) {
    return Column(
      mainAxisSize: MainAxisSize.min, // IMPORTANT for dialog
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer_rounded,
                  size: 18.sp,
                  color: theme.primaryColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        Row(
          children: [
            Expanded(
              child: TextField(
                autofocus: true,
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add tag...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onChanged: (val) async {
                  final results = await SocialService().searchTags(val);
                  setDialogState(() {
                    _tagSuggestions = results;
                  });
                },
                onSubmitted: (tag) => _addTagWithState(tag, setDialogState),
              ),
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: () =>
                  _addTagWithState(_tagController.text, setDialogState),
              icon: Icon(
                Iconsax.add_square_outline,
                color: theme.primaryColor,
                size: 32.sp,
              ),
            ),
          ],
        ),

        if (_tagSuggestions.isNotEmpty) ...[
          SizedBox(height: 8.h),
          SizedBox(
            height: 40.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tagSuggestions.length,
              itemBuilder: (context, index) {
                final tagData = _tagSuggestions[index];
                final tagName = tagData['tag'] as String;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ActionChip(
                    label: Text('#$tagName'),
                    onPressed: () => _addTagWithState(tagName, setDialogState),
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.05),
                    padding: EdgeInsets.zero,
                    labelStyle: TextStyle(fontSize: 11.sp),
                  ),
                );
              },
            ),
          ),
        ],

        if (_tags.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: _tags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                deleteIcon: const Icon(Icons.close_rounded),
                onDeleted: () {
                  setState(() => _tags.remove(tag));
                  setDialogState(() {});
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _addTagWithState(String tag, StateSetter setDialogState) {
    if (tag.isEmpty) return;
    final trimmedTag = tag.trim().toLowerCase().replaceAll('#', '');
    if (trimmedTag.isNotEmpty &&
        !_tags.contains(trimmedTag) &&
        _tags.length < 5) {
      setState(() {
        _tags.add(trimmedTag);
      });
      setDialogState(() {
        _tagController.clear();
        _tagSuggestions = [];
      });
      // Refresh popular tags for next use
      SocialService().getPopularTags().then((tags) {
        setDialogState(() => _tagSuggestions = tags);
      });
    }
  }

  Widget _buildBottomSection(ThemeData theme) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (isKeyboardVisible) {
      return Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 2.h,
        ), // Reduced padding
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              IconButton(
                onPressed: _pickImages,
                icon: Icon(
                  Iconsax.gallery_add_outline,
                  color: _imageAssets.isNotEmpty
                      ? theme.primaryColor
                      : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _isPollActive = !_isPollActive);
                },
                icon: Icon(
                  Iconsax.task_square_outline,
                  color: _isPollActive ? theme.primaryColor : Colors.grey,
                ),
              ),

              IconButton(
                onPressed: _showTagInput,
                icon: Icon(
                  Iconsax.hashtag_up_outline,
                  color: _tags.isNotEmpty ? theme.primaryColor : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: _showSubjectPicker,
                icon: Icon(
                  Iconsax.book_square_outline,
                  color: _selectedSubjectId != null
                      ? theme.primaryColor
                      : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: _showCategoryPicker,
                icon: Icon(
                  Iconsax.category_outline,
                  color: _postCategory != PostCategory.general
                      ? theme.primaryColor
                      : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: _showExpirationPicker,
                icon: Icon(
                  Iconsax.timer_1_outline,
                  color: _expirationDays != null
                      ? theme.primaryColor
                      : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: _showSettingsPicker,
                icon: Icon(
                  Iconsax.setting_2_outline,
                  color:
                      (_commentsDisabled ||
                          _sharingDisabled ||
                          _resharingDisabled)
                      ? theme.primaryColor
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Keyboard Closed: Two Rows
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Category & Subject
          Row(
            children: [
              Expanded(
                child: _buildPickerButton(
                  theme: theme,
                  icon: Iconsax.category_outline,
                  label:
                      _postCategory.name[0].toUpperCase() +
                      _postCategory.name.substring(1),
                  onTap: _showCategoryPicker,
                  isActive: _postCategory != PostCategory.general,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildPickerButton(
                  theme: theme,
                  icon: Iconsax.book_1_outline,
                  label: _selectedSubjectName ?? 'No Subject',
                  onTap: _showSubjectPicker,
                  isActive: _selectedSubjectId != null,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Row 2: Image, Poll, Timer, Settings
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildSmallIconButton(
                  theme: theme,
                  icon: Iconsax.gallery_add_outline,
                  onTap: _pickImages,
                  isActive: _imageAssets.isNotEmpty,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 3,
                child: _buildSmallIconButton(
                  theme: theme,
                  icon: Iconsax.task_square_outline,
                  onTap: () => setState(() => _isPollActive = !_isPollActive),
                  isActive: _isPollActive,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 3, // Slightly more width for Timer
                child: _buildSmallIconButton(
                  theme: theme,
                  icon: Iconsax.hashtag_up_outline,
                  onTap: _showTagInput,
                  isActive: _tags.isNotEmpty,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 4, // Slightly more width for Timer
                child: _buildSmallIconButton(
                  theme: theme,
                  icon: Iconsax.timer_1_outline,
                  onTap: _showExpirationPicker,
                  isActive: _expirationDays != null,
                  label: _expirationDays != null ? '${_expirationDays}d' : null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 3,
                child: _buildSmallIconButton(
                  theme: theme,
                  icon: Iconsax.setting_2_outline,
                  onTap: _showSettingsPicker,
                  isActive:
                      (_commentsDisabled ||
                      _sharingDisabled ||
                      _resharingDisabled),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isActive ? theme.primaryColor : Colors.grey,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 18.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallIconButton({
    required ThemeData theme,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    String? label,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive
              ? theme.primaryColor.withValues(alpha: 0.1)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive
                ? theme.primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isActive ? theme.primaryColor : Colors.grey,
            ),
            if (label != null)
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    int count = _imageAssets.length;
    double height = 250.h;
    Radius r = Radius.circular(12.r);

    // 1 Image
    if (count == 1) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: _buildGridImage(0, BorderRadius.all(r)),
      );
    }
    // 2 Images
    else if (count == 2) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: _buildGridImage(0, BorderRadius.horizontal(left: r)),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildGridImage(1, BorderRadius.horizontal(right: r)),
            ),
          ],
        ),
      );
    }
    // 3 Images
    else if (count == 3) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: _buildGridImage(0, BorderRadius.horizontal(left: r)),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _buildGridImage(1, BorderRadius.only(topRight: r)),
                  ),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: _buildGridImage(
                      2,
                      BorderRadius.only(bottomRight: r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // 4 Images
    else {
      return SizedBox(
        height: height,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildGridImage(0, BorderRadius.only(topLeft: r)),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: _buildGridImage(1, BorderRadius.only(topRight: r)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildGridImage(2, BorderRadius.only(bottomLeft: r)),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: _buildGridImage(
                      3,
                      BorderRadius.only(bottomRight: r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildGridImage(int index, BorderRadiusGeometry borderRadius) {
    final asset = _imageAssets[index];
    final heroTagPrefix = 'create_post'; // Base prefix

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            // Create list of providers
            final providers = _imageAssets
                .map((e) => AssetEntityImageProvider(e, isOriginal: true))
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageViewScreen(
                  imageProviders: providers,
                  initialIndex: index,
                  heroTagPrefix: heroTagPrefix,
                ),
              ),
            );
          },
          child: Hero(
            tag: '${heroTagPrefix}_$index', // Tag must match index
            child: ClipRRect(
              borderRadius: borderRadius,
              child: AssetEntityImage(
                asset,
                isOriginal: false, // Thumbnail
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (asset.type == AssetType.video)
          const IgnorePointer(
            child: Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _imageAssets.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostSettingsBottomSheet(
        commentsDisabled: _commentsDisabled,
        sharingDisabled: _sharingDisabled,
        resharingDisabled: _resharingDisabled,
        onSettingsChanged: (comments, sharing, resharing) {
          setState(() {
            _commentsDisabled = comments;
            _sharingDisabled = sharing;
            _resharingDisabled = resharing;
          });
        },
      ),
    );
  }

  void _showExpirationPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostTimerBottomSheet(
        initialDays: _expirationDays,
        onDaysSelected: (days) {
          setState(() {
            _expirationDays = days;
          });
        },
      ),
    );
  }

  Widget _buildUserSuggestions(ThemeData theme) {
    if (_userSuggestions.isEmpty) return const SizedBox.shrink();

    return FadeInUp(
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 60.h,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          itemCount: _userSuggestions.length,
          itemBuilder: (context, index) {
            final user = _userSuggestions[index];
            return InkWell(
              onTap: () => _applyMention(user),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor: AvatarColorGenerator.getColorForUser(
                        user.uid,
                      ),
                      backgroundImage:
                          user.photoURL != null && user.photoURL!.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                      child: (user.photoURL == null || user.photoURL!.isEmpty)
                          ? Icon(Icons.person, size: 16.sp)
                          : null,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _applyMention(UserModel user) {
    final text = _textController.text;
    final selection = _textController.selection;
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final lastAt = textBeforeCursor.lastIndexOf('@');

    if (lastAt != -1) {
      final newText =
          text.substring(0, lastAt) +
          "@${user.displayName} " +
          text.substring(selection.baseOffset);

      _textController.text = newText;
      _textController.selection = TextSelection.collapsed(
        offset: lastAt + user.displayName.length + 2,
      );

      if (!_taggedUserIds.contains(user.uid)) {
        _taggedUserIds.add(user.uid);
        _taggedUserNames.add(user.displayName);
      }

      setState(() {
        _userSuggestions = [];
      });
    }
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.question:
        return Colors.blue;
      case PostCategory.discussion:
        return Colors.purple;
      case PostCategory.resource:
        return Colors.green;
      case PostCategory.achievement:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
