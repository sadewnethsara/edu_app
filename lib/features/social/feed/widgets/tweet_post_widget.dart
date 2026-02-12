import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/features/shared/presentation/screens/image_view_screen.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/core/widgets/poll_widget.dart';
import 'package:math/features/social/feed/widgets/report_bottom_sheet.dart';
import 'package:math/features/social/feed/widgets/post_options_bottom_sheet.dart';
import 'package:math/features/social/feed/widgets/social_video_player.dart';

import 'package:math/features/social/shared/widgets/user_profile_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:math/core/utils/avatar_color_generator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/widgets/modern_dialogs.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/features/social/community/widgets/community_quick_join_bottom_sheet.dart';
import 'package:math/core/widgets/linkable_text.dart';
import 'package:math/features/shared/presentation/screens/web_view_screen.dart';
import 'package:math/features/social/feed/services/cache_service.dart';
import 'package:math/features/social/feed/services/download_service.dart';
import 'package:math/core/widgets/download_progress_dialog.dart';

class TweetPostWidget extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final bool isMinimal;

  const TweetPostWidget({
    super.key,
    required this.post,
    this.onTap,
    this.isMinimal = false,
  });

  @override
  State<TweetPostWidget> createState() => _TweetPostWidgetState();
}

class _TweetPostWidgetState extends State<TweetPostWidget> {
  bool _isLiked = false;
  int _likeCount = 0;
  int _reShareCount = 0;
  int _shareCount = 0;
  bool _isFavorited = false;
  bool _isExpanded = false;

  PostModel get _effectivePost {
    if (widget.post.isReShare &&
        widget.post.text.isEmpty &&
        widget.post.pollData == null &&
        widget.post.imageUrls.isEmpty &&
        widget.post.imageUrl == null &&
        widget.post.originalPost != null) {
      return widget.post.originalPost!;
    }
    return widget.post;
  }

  @override
  void initState() {
    super.initState();
    _initStats();
    _checkIfLiked();
    _checkIfFavorited();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SocialService().incrementViewCount(_effectivePost.postId);
    });
  }

  @override
  void didUpdateWidget(TweetPostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      _initStats();
      if (_effectivePost.postId != oldWidget.post.postId &&
          _effectivePost.postId != oldWidget.post.originalPostId) {
        _checkIfLiked();
        _checkIfFavorited();
      }
    }
  }

  void _initStats() {
    _likeCount = _effectivePost.likeCount;
    _reShareCount = _effectivePost.reShareCount;
    _shareCount = _effectivePost.shareCount;
  }

  Future<void> _checkIfLiked() async {
    final uid = context.read<AuthService>().user?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(_effectivePost.postId)
          .collection('likes')
          .doc(uid)
          .get();

      if (mounted) {
        setState(() => _isLiked = doc.exists);
      }
    } catch (_) {}
  }

  Future<void> _checkIfFavorited() async {
    final uid = context.read<AuthService>().user?.uid;
    if (uid == null) return;
    final fav = await SocialService().isFavorited(uid, _effectivePost.postId);
    if (mounted) setState(() => _isFavorited = fav);
  }

  Future<void> _toggleFavorite() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    setState(() => _isFavorited = !_isFavorited);

    try {
      await SocialService().toggleFavorite(user.uid, _effectivePost.postId);
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorited = !_isFavorited);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favourite')),
        );
      }
    }
  }

  Future<void> _handleDownload() async {
    final post = _effectivePost;
    final mediaUrls = [...post.imageUrls];
    if (post.imageUrl != null) mediaUrls.add(post.imageUrl!);
    if (post.videoUrl != null) mediaUrls.add(post.videoUrl!);

    if (mediaUrls.isEmpty) return;

    final progress = ValueNotifier<double>(0.0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(progress: progress),
    );

    try {
      List<String> localPaths = [];
      double totalProgress = 0;

      for (var i = 0; i < mediaUrls.length; i++) {
        final url = mediaUrls[i];
        final ext = url.split('?').first.split('.').last;
        final fileName = '${post.postId}_$i.$ext';

        final path = await DownloadService().downloadFile(
          url,
          fileName,
          onProgress: (received, total) {
            if (total != -1) {
              final itemProgress = received / total;
              progress.value =
                  (totalProgress + itemProgress) / mediaUrls.length;
            }
          },
        );

        if (path != null) {
          localPaths.add(path);
        }
        totalProgress += 1.0;
        progress.value = totalProgress / mediaUrls.length;
      }

      await CacheService().cachePost(post, localPaths);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post saved offline successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download post')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    final authService = context.read<AuthService>();
    if (authService.user == null) {
      _showSignInSnack();
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    final error = await authService.likePost(
      _effectivePost.postId,
      _effectivePost.authorId,
      !_isLiked,
    );

    if (error != null && mounted) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _handleReShare() {
    final currentUser = context.read<AuthService>().user;
    if (currentUser == null) {
      _showSignInSnack();
      return;
    }

    context.pushNamed(AppRouter.createPostName, extra: _effectivePost);
  }

  Future<void> _handleShare() async {
    setState(() => _shareCount++);
    await SocialService().incrementShareCount(_effectivePost.postId);

    final url =
        'https://yourapp.com/post/${_effectivePost.postId}'; // Deep link placeholder

    await SharePlus.instance.share(
      ShareParams(
        text: 'Check out this post by ${_effectivePost.authorName}: $url',
      ),
    );
  }

  void _copyLink(PostModel post) {
    final url = 'https://yourapp.com/post/${post.postId}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Link copied to clipboard")));
  }

  void _showSignInSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please sign in to interact.")),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return DateFormat('MMM d').format(postTime);
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

  Future<void> _confirmDelete() async {
    ModernDeleteDialog.show(
      context,
      onDelete: () async {
        await SocialService().deletePost(widget.post.postId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = _effectivePost;
    final isDirectRepost =
        widget.post.isReShare &&
        widget.post.text.isEmpty &&
        widget.post.pollData == null &&
        widget.post.imageUrls.isEmpty &&
        widget.post.imageUrl == null;
    final reposterName = widget.post.authorName;

    final photoUrl = post.authorPhotoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final bgColor = AvatarColorGenerator.getColorForUser(post.authorId);

    return InkWell(
      onTap: () {
        if (widget.isMinimal) {
          final hasExtraContent =
              post.linkUrl != null ||
              post.subjectName != null ||
              post.tags.isNotEmpty ||
              post.category != PostCategory.general ||
              post.helpfulAnswerCount > 0 ||
              post.imageUrls.isNotEmpty ||
              post.imageUrl != null ||
              post.videoUrl != null ||
              post.pollData != null ||
              (!isDirectRepost && widget.post.originalPost != null);

          if (hasExtraContent && !_isExpanded) {
            setState(() => _isExpanded = true);
            return;
          }
        }

        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          context.push(
            AppRouter.postDetailPath.replaceFirst(':postId', post.postId),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDirectRepost)
              Padding(
                padding: EdgeInsets.only(
                  bottom: 6.h,
                  left: 36.w,
                ), // Indent to align with content
                child: Row(
                  children: [
                    Icon(
                      Iconsax.repeat_outline,
                      size: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Reposted by $reposterName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          UserProfileBottomSheet(userId: post.authorId),
                    );
                  },
                  child: SizedBox(
                    width: 44.r,
                    height: 44.r,
                    child: Stack(
                      children: [
                        Align(
                          alignment: post.communityId != null
                              ? Alignment.bottomRight
                              : Alignment.center,
                          child: Container(
                            width: post.communityId != null ? 34.r : 34.r,
                            height: post.communityId != null ? 34.r : 34.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: post.communityId != null ? 1.5 : 0,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: post.communityId != null ? 15.r : 17.r,
                              backgroundColor: bgColor,
                              backgroundImage: hasPhoto
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : null,
                              child: !hasPhoto
                                  ? Icon(
                                      Icons.person,
                                      size: post.communityId != null
                                          ? 14.sp
                                          : 16.sp,
                                      color:
                                          AvatarColorGenerator.getTextColorForBackground(
                                            bgColor,
                                          ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (post.communityId != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 24.r,
                              height: 24.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
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
                                          size: 14.r,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        post.authorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.sp,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "· ${_formatTimestamp(post.createdAt)}",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey.shade600,
                                            fontSize: 14.sp,
                                          ),
                                    ),
                                  ],
                                ),
                                if (post.communityId != null)
                                  GestureDetector(
                                    onTap: () {
                                      context.pushNamed(
                                        AppRouter.communityName,
                                        pathParameters: {
                                          'communityId': post.communityId!,
                                        },
                                      );
                                    },
                                    child: Text(
                                      'in ${post.communityName}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!widget.isMinimal || _isExpanded)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    final currentUser = context
                                        .read<AuthService>()
                                        .user;
                                    if (currentUser == null) {
                                      _showSignInSnack();
                                      return;
                                    }

                                    final isAuthor =
                                        currentUser.uid == widget.post.authorId;

                                    showModalBottomSheet(
                                      context: context,
                                      useRootNavigator: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => PostOptionsBottomSheet(
                                        isAuthor: isAuthor,
                                        onDelete: _confirmDelete,
                                        onReport: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            useRootNavigator: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => ReportBottomSheet(
                                              postId: widget.post.postId,
                                              onReportSubmitted:
                                                  (reason, details) async {
                                                    await SocialService()
                                                        .reportPost(
                                                          widget.post.postId,
                                                          reason,
                                                          details,
                                                          currentUser.uid,
                                                        );
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Report submitted. Thank you.',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            ),
                                          );
                                        },
                                        onHide: () async {
                                          await SocialService().hidePost(
                                            widget.post.postId,
                                            currentUser.uid,
                                          );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Post hidden'),
                                            ),
                                          );
                                        },
                                        onShare: _handleShare,
                                        onCopyLink: () => _copyLink(post),
                                        isFavorited: _isFavorited,
                                        onFavorite: _toggleFavorite,
                                        hasMedia:
                                            post.imageUrls.isNotEmpty ||
                                            post.imageUrl != null ||
                                            post.videoUrl != null,
                                        onDownload: _handleDownload,
                                        onEdit:
                                            (isAuthor &&
                                                post.replyCount == 0 &&
                                                (post.pollData?.totalVotes ??
                                                        0) ==
                                                    0)
                                            ? () {
                                                context.pushNamed(
                                                  AppRouter.createPostName,
                                                  extra: post,
                                                );
                                              }
                                            : null,
                                        onFollow:
                                            currentUser.uid == post.authorId
                                            ? null
                                            : () async {
                                                await SocialService()
                                                    .followUser(
                                                      currentUser.uid,
                                                      post.authorId,
                                                    );
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Following user',
                                                    ),
                                                  ),
                                                );
                                              },
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    child: Icon(
                                      Icons.more_horiz_rounded,
                                      size: 18.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                if (post.communityId != null ||
                                    post.originalPost?.communityId != null)
                                  Builder(
                                    builder: (context) {
                                      final user = context
                                          .read<AuthService>()
                                          .user;
                                      final targetPost =
                                          post.communityId != null
                                          ? post
                                          : post.originalPost!;

                                      if (user == null) {
                                        return Padding(
                                          padding: EdgeInsets.only(top: 4.h),
                                          child: _buildJoinButton(
                                            context,
                                            targetPost,
                                            theme,
                                          ),
                                        );
                                      }

                                      return FutureBuilder<bool>(
                                        future: CommunityService().isMember(
                                          targetPost.communityId!,
                                          user.uid,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                                  ConnectionState.waiting ||
                                              (snapshot.data ?? false)) {
                                            return const SizedBox.shrink();
                                          }

                                          return Padding(
                                            padding: EdgeInsets.only(top: 4.h),
                                            child: _buildJoinButton(
                                              context,
                                              targetPost,
                                              theme,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      if (post.text.isNotEmpty)
                        (widget.isMinimal && !_isExpanded)
                            ? Text(
                                post.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 15.sp,
                                  height: 1.3,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )
                            : LinkableText(
                                text: post.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 15.sp,
                                  height: 1.3,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),

                      if (post.linkUrl != null &&
                          (!widget.isMinimal || _isExpanded))
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: InkWell(
                            onTap: () {
                              if (post.linkUrl != null) {
                                WebViewScreen.show(context, post.linkUrl!);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.link_outline,
                                    size: 18.sp,
                                    color: theme.primaryColor,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      post.linkUrl!,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.none,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if ((post.subjectName != null ||
                              post.tags.isNotEmpty ||
                              post.category != PostCategory.general) &&
                          (!widget.isMinimal || _isExpanded))
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: [
                              if (post.subjectName != null)
                                GestureDetector(
                                  onTap: () => context.pushNamed(
                                    AppRouter.filteredPostsName,
                                    pathParameters: {
                                      'type': 'subject',
                                      'value': post.subjectName!,
                                    },
                                    extra: post.subjectName,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.subject,
                                          size: 12.sp,
                                          color: theme.primaryColor,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          post.subjectName!,
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (post.category != PostCategory.general)
                                GestureDetector(
                                  onTap: () => context.pushNamed(
                                    AppRouter.filteredPostsName,
                                    pathParameters: {
                                      'type': 'category',
                                      'value': post.category.name,
                                    },
                                    extra:
                                        post.category.name[0].toUpperCase() +
                                        post.category.name.substring(1),
                                  ),
                                  child: Container(
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
                                        fontSize: 11.sp,
                                        color: _getCategoryColor(post.category),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ...post.tags.take(3).map((tag) {
                                return GestureDetector(
                                  onTap: () {
                                    context.pushNamed(
                                      AppRouter.filteredPostsName,
                                      pathParameters: {
                                        'type': 'tag',
                                        'value': tag,
                                      },
                                      extra: '#$tag',
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: theme
                                            .colorScheme
                                            .onSecondaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                      if (post.helpfulAnswerCount > 0 &&
                          (!widget.isMinimal || _isExpanded))
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14.sp,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${post.helpfulAnswerCount} helpful answer${post.helpfulAnswerCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if ((post.imageUrls.isNotEmpty ||
                              post.imageUrl != null) &&
                          (!widget.isMinimal || _isExpanded))
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: _buildTweetImages(context, post),
                        ),

                      if (post.pollData != null &&
                          (!widget.isMinimal || _isExpanded))
                        PollWidget(
                          postId: post.postId,
                          pollData: post.pollData!,
                        ),

                      if (!isDirectRepost &&
                          widget.post.originalPost != null &&
                          (!widget.isMinimal || _isExpanded))
                        Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: _buildQuotePreview(
                            context: context,
                            theme: theme,
                            post: widget.post.originalPost!,
                          ),
                        ),

                      if (!widget.isMinimal || _isExpanded)
                        Padding(
                          padding: EdgeInsets.only(top: 12.h, right: 8.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _ActionButton(
                                icon: Iconsax.messages_2_outline,
                                label: post.replyCount > 0
                                    ? '${post.replyCount}'
                                    : '',
                                activeColor: Colors.blue,
                                onTap: () {
                                  if (post.commentsDisabled) {
                                    showModernInfoDialog(
                                      context: context,
                                      title: 'Replies Disabled',
                                      message:
                                          'The author of this post has disabled replies.',
                                      icon: Icons.chat_bubble_outline_rounded,
                                    );
                                    return;
                                  }
                                  context.push(
                                    AppRouter.postDetailPath.replaceFirst(
                                      ':postId',
                                      post.postId,
                                    ),
                                  );
                                },
                              ),
                              if (!post.resharingDisabled)
                                _ActionButton(
                                  icon: Iconsax.repeat_outline,
                                  label: _reShareCount > 0
                                      ? '$_reShareCount'
                                      : '',
                                  activeColor: Colors.green,
                                  onTap: _handleReShare,
                                ),
                              _ActionButton(
                                icon: _isLiked
                                    ? Iconsax.heart_bold
                                    : Iconsax.heart_outline,
                                label: _likeCount > 0 ? '$_likeCount' : '',
                                color: _isLiked
                                    ? Colors.pinkAccent
                                    : Colors.grey.shade500,
                                activeColor: Colors.pinkAccent,
                                onTap: _toggleLike,
                              ),
                              _ActionButton(
                                icon: Iconsax.chart_outline,
                                label: widget.post.viewCount > 0
                                    ? '${widget.post.viewCount}'
                                    : '',
                                activeColor: Colors.blue,
                                onTap: () {},
                              ),
                              if (!post.sharingDisabled)
                                _ActionButton(
                                  icon: Iconsax.export_3_outline,
                                  label: _shareCount > 0 ? '$_shareCount' : '',
                                  activeColor: Colors.blue,
                                  onTap: _handleShare,
                                ),
                            ],
                          ),
                        ),

                      if (widget.isMinimal)
                        Builder(
                          builder: (context) {
                            final hasExtraContent =
                                post.linkUrl != null ||
                                post.subjectName != null ||
                                post.tags.isNotEmpty ||
                                post.category != PostCategory.general ||
                                post.helpfulAnswerCount > 0 ||
                                post.imageUrls.isNotEmpty ||
                                post.imageUrl != null ||
                                post.videoUrl != null ||
                                post.pollData != null ||
                                (!isDirectRepost &&
                                    widget.post.originalPost != null);

                            if (!hasExtraContent) {
                              return const SizedBox.shrink();
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() => _isExpanded = !_isExpanded);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(
                                  _isExpanded ? "Show less" : "See more...",
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTweetImages(BuildContext context, PostModel post) {
    final urls = post.imageUrls;
    final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
    const double phi = 1.61803398875; // 🚀 Golden Ratio

    Widget buildVideo() {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageViewScreen(
                imageUrls: urls,
                videoUrl: post.videoUrl,
                initialIndex: 0,
                heroTagPrefix: '${post.postId}_video',
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SocialVideoPlayer(
            videoUrl: post.videoUrl!,
            autoPlay:
                context.read<AuthService>().userModel?.autoplayVideos ?? false,
          ),
        ),
      );
    }

    Widget buildImage(String url, int index) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageViewScreen(
                imageUrls: urls,
                videoUrl: post.videoUrl,
                initialIndex: hasVideo ? index + 1 : index,
                heroTagPrefix: post.postId,
              ),
            ),
          );
        },
        child: Hero(
          tag: '${post.postId}_$index',
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double goldenHeight = width / phi;

        if (hasVideo && urls.isEmpty) {
          return SizedBox(
            height: goldenHeight,
            width: width,
            child: buildVideo(),
          );
        }

        if (!hasVideo && urls.length == 1) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: AspectRatio(aspectRatio: phi, child: buildImage(urls[0], 0)),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            height: goldenHeight,
            child: Builder(
              builder: (context) {
                if (hasVideo && urls.length == 1) {
                  return Row(
                    children: [
                      Expanded(child: buildVideo()),
                      SizedBox(width: 2.w),
                      Expanded(child: buildImage(urls[0], 0)),
                    ],
                  );
                }

                if (urls.length == 2 && !hasVideo) {
                  return Row(
                    children: [
                      Expanded(child: buildImage(urls[0], 0)),
                      SizedBox(width: 2.w),
                      Expanded(child: buildImage(urls[1], 1)),
                    ],
                  );
                }

                if (hasVideo && urls.length == 2) {
                  return Row(
                    children: [
                      Expanded(child: buildVideo()),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: buildImage(urls[0], 0)),
                            SizedBox(height: 2.h),
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
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: buildImage(urls[1], 1)),
                            SizedBox(height: 2.h),
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
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: buildImage(
                              hasVideo ? urls[0] : urls[1],
                              hasVideo ? 0 : 1,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: buildImage(
                                    hasVideo ? urls[1] : urls[2],
                                    hasVideo ? 1 : 2,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      buildImage(
                                        hasVideo ? urls[2] : urls[3],
                                        hasVideo ? 2 : 3,
                                      ),
                                      if (urls.length > (hasVideo ? 3 : 4))
                                        Container(
                                          color: Colors.black54,
                                          child: Center(
                                            child: Text(
                                              '+${urls.length - (hasVideo ? 3 : 4)}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuotePreview({
    required BuildContext context,
    required ThemeData theme,
    required PostModel post,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.push(
          AppRouter.postDetailPath.replaceFirst(':postId', post.postId),
        );
      },
      child: Container(
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
            Row(
              children: [
                SizedBox(
                  width: 32.r,
                  height: 32.r,
                  child: Stack(
                    children: [
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
                if (post.communityId != null)
                  Builder(
                    builder: (context) {
                      final user = context.read<AuthService>().user;
                      if (user == null) {
                        return Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: _buildJoinButton(context, post, theme),
                        );
                      }

                      return FutureBuilder<bool>(
                        future: CommunityService().isMember(
                          post.communityId!,
                          user.uid,
                        ),
                        builder: (context, snapshot) {
                          final isJoined = snapshot.data ?? false;

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: _buildJoinButton(
                              context,
                              post,
                              theme,
                              isJoined: isJoined,
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),

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

            if (post.imageUrls.isNotEmpty ||
                post.imageUrl != null ||
                post.videoUrl != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: _buildQuotedMedia(post),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotedMedia(PostModel post) {
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
                        Expanded(
                          child: buildImage(
                            hasVideo ? urls[0] : urls[1],
                            hasVideo ? 0 : 1,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: buildImage(
                                  hasVideo ? urls[1] : urls[2],
                                  hasVideo ? 1 : 2,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    buildImage(
                                      hasVideo ? urls[2] : urls[3],
                                      hasVideo ? 2 : 3,
                                    ),
                                    if (urls.length > (hasVideo ? 3 : 4))
                                      Container(
                                        color: Colors.black54,
                                        child: Center(
                                          child: Text(
                                            '+${urls.length - (hasVideo ? 3 : 4)}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildJoinButton(
    BuildContext context,
    PostModel post,
    ThemeData theme, {
    bool isJoined = false,
  }) {
    return InkWell(
      onTap: () async {
        if (isJoined) {
          context.pushNamed(
            AppRouter.communityName,
            pathParameters: {'communityId': post.communityId!},
          );
          return;
        }

        final user = context.read<AuthService>().user;
        if (user == null) {
          _showSignInSnack();
          return;
        }
        await CommunityService().joinCommunity(post.communityId!, user.uid);
        if (context.mounted) {
          setState(() {});
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CommunityQuickJoinBottomSheet(
              communityId: post.communityId!,
              alreadyJoined: true,
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isJoined
              ? theme.disabledColor.withValues(alpha: 0.1)
              : theme.primaryColor,
          borderRadius: BorderRadius.circular(20.r),
          border: isJoined
              ? Border.all(color: theme.dividerColor.withValues(alpha: 0.1))
              : null,
          boxShadow: isJoined
              ? null
              : [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isJoined) ...[
              Icon(Iconsax.add_outline, size: 14.sp, color: Colors.white),
              SizedBox(width: 4.w),
            ],
            Text(
              isJoined ? 'Joined' : 'Join',
              style: TextStyle(
                color: isJoined ? theme.disabledColor : Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.grey.shade500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: effectiveColor),
            if (label.isNotEmpty) ...[
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
