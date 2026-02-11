import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/models/reply_model.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:math/features/shared/presentation/screens/image_view_screen.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:math/features/social/feed/widgets/report_bottom_sheet.dart';
import 'package:math/features/social/feed/widgets/post_options_bottom_sheet.dart';
import 'package:math/core/widgets/modern_dialogs.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart'; // 🚀 ADDED
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/core/router/app_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/widgets/poll_widget.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/features/social/feed/widgets/social_video_player.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/features/social/community/widgets/community_quick_join_bottom_sheet.dart';
import 'package:math/core/utils/avatar_color_generator.dart';
import 'package:math/core/widgets/linkable_text.dart';
import 'package:math/features/shared/presentation/screens/web_view_screen.dart';
import 'package:math/features/social/feed/services/cache_service.dart';
import 'package:math/features/social/feed/services/download_service.dart';
import 'package:math/core/widgets/download_progress_dialog.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  bool _isLoadingPost = true;
  bool _isLoadingReplies = true;
  bool _isPostingReply = false;
  List<AssetEntity> _selectedReplyAssets = [];
  String? _replyVideoUrl;
  bool _isPostAsAnswer = false;

  PostModel? _post;
  List<ReplyModel> _replies = [];
  ReplyModel? _replyingTo;
  final FocusNode _replyFocusNode = FocusNode();

  // Filtering
  final ValueNotifier<String> _sortBy = ValueNotifier<String>(
    'newest',
  ); // newest, top, helpful

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    _sortBy.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadPost(), _loadReplies()]);
  }

  Future<void> _loadPost() async {
    if (mounted) setState(() => _isLoadingPost = true);
    try {
      final doc = await _firestore.collection('posts').doc(widget.postId).get();
      if (doc.exists) {
        _post = PostModel.fromSnapshot(doc);
        SocialService().incrementViewCount(widget.postId);
      }
    } catch (e, s) {
      logger.e('Failed to load post', error: e, stackTrace: s);
    }
    if (mounted) setState(() => _isLoadingPost = false);
  }

  Future<void> _loadReplies() async {
    if (mounted) setState(() => _isLoadingReplies = true);
    try {
      var query = _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('replies');

      // Sort by chosen filter
      Query finalQuery;
      if (_sortBy.value == 'top') {
        finalQuery = query.orderBy('likeCount', descending: true);
      } else if (_sortBy.value == 'helpful') {
        finalQuery = query.orderBy('helpfulCount', descending: true);
      } else {
        finalQuery = query.orderBy('createdAt', descending: true);
      }

      final snap = await finalQuery.get();

      final allReplies = snap.docs
          .map((doc) => ReplyModel.fromSnapshot(doc))
          .toList();

      // Threaded Tree Structure Logic
      final Map<String, List<ReplyModel>> childrenMap = {};
      final List<ReplyModel> roots = [];

      for (var reply in allReplies) {
        if (reply.parentId == null) {
          roots.add(reply);
        } else {
          childrenMap.putIfAbsent(reply.parentId!, () => []).add(reply);
        }
      }

      final List<ReplyModel> sorted = [];
      void addRecursive(ReplyModel node) {
        sorted.add(node);
        final children = childrenMap[node.replyId] ?? [];
        // Optionally sort children by the same criteria if they don't follow global sort
        for (var child in children) {
          addRecursive(child);
        }
      }

      for (var root in roots) {
        addRecursive(root);
      }

      if (mounted) {
        setState(() {
          _replies = sorted;
          _isLoadingReplies = false;
        });
      }
    } catch (e, s) {
      logger.e('Failed to load replies', error: e, stackTrace: s);
      if (mounted) setState(() => _isLoadingReplies = false);
    }
  }

  Future<void> _publishReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty &&
        _selectedReplyAssets.isEmpty &&
        _replyVideoUrl == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isPostingReply = true);

    final authService = context.read<AuthService>();
    final user = authService.user;

    if (user == null) {
      MessageBanner.show(
        context,
        message: 'You must be logged in to reply.',
        type: MessageType.warning,
      );
      setState(() => _isPostingReply = false);
      return;
    }

    if (_replyController.text.trim().isEmpty && _selectedReplyAssets.isEmpty) {
      if (mounted) setState(() => _isPostingReply = false);
      return;
    }

    try {
      String? imageUrl;
      // 🚀 Upload Image if selected
      if (_selectedReplyAssets.isNotEmpty) {
        final file = await _selectedReplyAssets.first.file;
        if (file != null) {
          imageUrl = await SocialService().uploadReplyImage(file, user.uid);
        }
      }

      final replyDoc = _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('replies')
          .doc();

      final newReply = ReplyModel(
        replyId: replyDoc.id,
        authorId: user.uid,
        authorName: user.displayName ?? 'Anonymous User',
        authorPhotoUrl: user.photoURL,
        text: text,
        imageUrl: imageUrl, // 🚀 ADDED
        createdAt: Timestamp.now(),
        likeCount: 0,
        parentId: _replyingTo?.replyId, // Link to parent
        replyToUserId: _replyingTo?.authorId, // Link to user being replied to
        replyToUserName: _replyingTo?.authorName,
      );

      await replyDoc.set(newReply.toJson());

      // Increment reply count safely using a transaction or batch if preferred,
      // but simple update is fine for MVP.
      await _firestore.collection('posts').doc(widget.postId).update({
        'replyCount': FieldValue.increment(1),
      });

      // --- Send Notification ---
      if (_replyingTo != null) {
        // Notify Parent Comment Author
        await SocialService().sendNotification(
          toUserId: _replyingTo!.authorId,
          title: 'New Reply',
          message: '${user.displayName} replied to your comment.',
          type: 'postReply',
          senderId: user.uid,
          senderName: user.displayName,
          senderPhotoUrl: user.photoURL,
          targetContentId: widget.postId,
        );
      } else if (_post != null) {
        // Notify Post Author
        await SocialService().sendNotification(
          toUserId: _post!.authorId,
          title: 'New Comment',
          message: '${user.displayName} commented on your post.',
          type: 'postReply',
          senderId: user.uid,
          senderName: user.displayName,
          senderPhotoUrl: user.photoURL,
          targetContentId: widget.postId,
        );
      }

      _replyController.clear();
      _replyController.clear();
      setState(() {
        _replyingTo = null; // Reset replying state
        _selectedReplyAssets.clear(); // 🚀 Clear image
      });
      await _loadReplies();
      // Also reload post to update reply count in UI
      await _loadPost();
    } catch (e) {
      logger.e('Failed to publish reply', error: e);
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to publish reply.',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingReply = false);
    }
  }

  void _handleReplyTo(ReplyModel reply) {
    setState(() {
      _replyingTo = reply;
    });
    FocusScope.of(context).requestFocus(_replyFocusNode);
  }

  // 🚀 Pick Image Method
  Future<void> _pickReplyImage() async {
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
        title: 'Select Image',
        pickerTheme: pickerTheme,
        gridCount: 3,
      ),
      maxAssets: 1,
      selectedAssets: _selectedReplyAssets,
      onCompleted: (Stream<InstaAssetsExportDetails> stream) {
        stream.listen((details) {
          if (mounted) {
            setState(() {
              _selectedReplyAssets = details.selectedAssets;
            });
          }
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _post?.category.name.toUpperCase() ?? 'POST',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14.sp,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _isLoadingPost && _post == null
                          ? _buildPostShimmer(theme)
                          : _post != null
                          ? _MainPostWidget(
                              post: _post!,
                              replyFocusNode: _replyFocusNode,
                            )
                          : const Center(child: Text('Post not found')),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        minHeight: 50.h,
                        maxHeight: 50.h,
                        child: Container(
                          color: theme.scaffoldBackgroundColor,
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: theme.primaryColor,
                            indicatorWeight: 3,
                            labelColor: theme.primaryColor,
                            unselectedLabelColor: Colors.grey,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            tabs: const [
                              Tab(text: 'General'),
                              Tab(text: 'Answers'),
                              Tab(text: 'Resources'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRepliesTab(theme),
                    _buildAnswersTab(theme),
                    _buildResourcesTab(theme),
                  ],
                ),
              ),
            ),
            _buildReplyInput(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesTab(ThemeData theme) {
    if (_isLoadingReplies) return _buildRepliesShimmer(theme);
    if (_replies.isEmpty) return _buildEmptyState('No replies yet');

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _replies.length,
      itemBuilder: (context, index) {
        return _ReplyWidget(
          reply: _replies[index],
          postId: widget.postId,
          onReply: _handleReplyTo,
        );
      },
    );
  }

  Widget _buildAnswersTab(ThemeData theme) {
    final answers = _replies
        .where((r) => r.isAnswer || r.isMarkedHelpful)
        .toList();
    if (answers.isEmpty) return _buildEmptyState('No expert answers yet');

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: answers.length,
      itemBuilder: (context, index) {
        return _ReplyWidget(
          reply: answers[index],
          postId: widget.postId,
          onReply: _handleReplyTo,
        );
      },
    );
  }

  Widget _buildResourcesTab(ThemeData theme) {
    final List<String> images = [];
    if (_post != null) {
      images.addAll(_post!.imageUrls);
    }
    for (var r in _replies) {
      images.addAll(r.imageUrls);
    }

    if (images.isEmpty) return _buildEmptyState('No resources found');

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageViewScreen(
                  imageUrls: images,
                  initialIndex: index,
                  heroTagPrefix: 'resource',
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.message_outline,
                size: 48.sp,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 8.h),
              Text(message, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Row(
              children: [
                Text(
                  'Replying to ${_replyingTo!.authorName}',
                  style: TextStyle(fontSize: 12.sp, color: theme.primaryColor),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _replyingTo = null),
                ),
              ],
            ),

          if (_selectedReplyAssets.isNotEmpty)
            SizedBox(
              height: 60.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedReplyAssets.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: AssetEntityImage(
                    _selectedReplyAssets[index],
                    width: 60.h,
                    height: 60.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  focusNode: _replyFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    fillColor: theme.brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: _isPostingReply
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Icon(Iconsax.send_1_outline, color: theme.primaryColor),
                onPressed: _publishReply,
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                flex: 5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: _pickReplyImage,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Iconsax.gallery_outline,
                          color: theme.primaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Select images to reply',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: 24.h,
                child: VerticalDivider(
                  width: 16,
                  thickness: 1,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
              ),

              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Switch(
                        value: _isPostAsAnswer,
                        onChanged: (val) =>
                            setState(() => _isPostAsAnswer = val),
                        activeTrackColor: theme.primaryColor.withValues(
                          alpha: 0.4,
                        ),
                        activeThumbColor: theme.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Post as a Answer',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shimmer effect for post loading
  Widget _buildPostShimmer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(
              children: [
                CircleAvatar(radius: 22.r, backgroundColor: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: 14.h,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Text content shimmer
            Container(
              height: 20.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              height: 20.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              height: 20.h,
              width: 220.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 16.h),
            // Image placeholder shimmer (optional)
            Container(
              height: 220.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48.sp,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Timestamp shimmer
            Container(
              height: 14.h,
              width: 150.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 24.h),
            // Action buttons shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (index) =>
                    CircleAvatar(radius: 20.r, backgroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer effect for replies loading
  Widget _buildRepliesShimmer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 18.r, backgroundColor: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 14.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: 14.h,
                        width: 180.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainPostWidget extends StatefulWidget {
  final PostModel post;
  final FocusNode replyFocusNode;
  const _MainPostWidget({required this.post, required this.replyFocusNode});

  @override
  State<_MainPostWidget> createState() => _MainPostWidgetState();
}

class _MainPostWidgetState extends State<_MainPostWidget> {
  bool _isLiked = false;
  int _likeCount = 0;
  int _reShareCount = 0;
  int _shareCount = 0;
  int _viewCount = 0;
  bool _isFavorited = false;
  bool _isJoined = false;

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

  Map<String, String> _cachedMedia = {};

  @override
  void initState() {
    super.initState();
    _initStats();
    _checkIfLiked();
    _checkIfFavorited();
    _checkIfJoined();
    _checkCache();
  }

  Future<void> _checkCache() async {
    final cachedData = CacheService().getCachedPost(_effectivePost.postId);
    if (cachedData != null && cachedData['localPaths'] != null) {
      final List<dynamic> localPathsDynamic = cachedData['localPaths'];
      final List<String> localPaths = List<String>.from(localPathsDynamic);
      final post = _effectivePost;

      // Reconstruct original URLs order to map them
      final mediaUrls = [...post.imageUrls];
      if (post.imageUrl != null) mediaUrls.add(post.imageUrl!);
      if (post.videoUrl != null) mediaUrls.add(post.videoUrl!);

      if (mediaUrls.length == localPaths.length) {
        final Map<String, String> cacheMap = {};
        for (int i = 0; i < mediaUrls.length; i++) {
          final file = File(localPaths[i]);
          if (await file.exists()) {
            cacheMap[mediaUrls[i]] = localPaths[i];
          }
        }
        if (mounted) setState(() => _cachedMedia = cacheMap);
      }
    }
  }

  void _initStats() {
    final post = _effectivePost;
    _likeCount = post.likeCount;
    _reShareCount = post.reShareCount;
    _shareCount = post.shareCount;
    _viewCount = post.viewCount;
  }

  @override
  void didUpdateWidget(_MainPostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.postId != widget.post.postId ||
        oldWidget.post.likeCount != widget.post.likeCount ||
        oldWidget.post.reShareCount != widget.post.reShareCount ||
        oldWidget.post.shareCount != widget.post.shareCount ||
        oldWidget.post.viewCount != widget.post.viewCount) {
      _initStats();
    }

    // Re-check join status if post changes
    if (oldWidget.post.postId != widget.post.postId) {
      _checkIfJoined();
    }
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
      if (mounted) setState(() => _isLiked = doc.exists);
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final authService = context.read<AuthService>();
    if (authService.user == null) {
      MessageBanner.show(
        context,
        message: "Please sign in to like posts.",
        type: MessageType.warning,
      );
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
    }
  }

  Future<void> _handleShare() async {
    // 1. Increment Share Count
    await SocialService().incrementShareCount(_effectivePost.postId);
    if (mounted) {
      setState(() {
        _shareCount++;
      });
    }

    // 2. Open Share Sheet
    final url = 'https://yourapp.com/post/${_effectivePost.postId}';
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

  Future<void> _handleShareSheet() async {
    // 1. Increment Share Count
    await SocialService().incrementShareCount(_effectivePost.postId);

    // 2. Open Share Sheet
    final url = 'https://yourapp.com/post/${_effectivePost.postId}';

    await SharePlus.instance.share(
      ShareParams(
        text: 'Check out this post by ${_effectivePost.authorName}: $url',
      ),
    );
  }

  Future<void> _confirmDelete() async {
    ModernDeleteDialog.show(
      context,
      onDelete: () async {
        try {
          // Store navigator before async gap
          final navigator = Navigator.of(context);

          await SocialService().deletePost(widget.post.postId);

          if (mounted) {
            // Pop back to feed
            navigator.pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Post deleted')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete post: $e')),
            );
          }
        }
      },
    );
  }

  Future<void> _handleReport(String reason, String details) async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    try {
      await SocialService().reportPost(
        widget.post.postId,
        reason,
        details,
        user.uid,
      );
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Report submitted for review.',
          type: MessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to submit report.',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _hidePost() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    try {
      await SocialService().hidePost(widget.post.postId, user.uid);
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Post hidden from your feed.',
          type: MessageType.success,
        );
        Navigator.of(context).pop(); // Close detail screen as post is hidden
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to hide post.',
          type: MessageType.error,
        );
      }
    }
  }

  void _handleReShare() {
    final currentUser = context.read<AuthService>().user;
    if (currentUser == null) {
      MessageBanner.show(
        context,
        message: 'Please sign in to repost.',
        type: MessageType.warning,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.repeat_rounded, color: Colors.green),
              title: Text(
                'Repost',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _executeReShare();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_note_rounded, color: Colors.blue),
              title: Text(
                'Quote',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Add a comment'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.createPostPath, extra: widget.post);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeReShare() async {
    final currentUser = context.read<AuthService>().user;
    if (currentUser == null) return;

    try {
      await SocialService().reSharePost(
        postId: widget.post.postId,
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'User',
        userPhotoUrl: currentUser.photoURL,
        originalPost: widget.post,
      );
      if (mounted) {
        setState(() {
          _reShareCount++;
        });
        MessageBanner.show(
          context,
          message: 'Reposted to your feed',
          type: MessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to repost: $e',
          type: MessageType.error,
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('h:mm a · MMM d, yyyy').format(timestamp.toDate());
  }

  Future<void> _checkIfFavorited() async {
    final auth = context.read<AuthService>();
    final user = auth.user;
    if (user == null || user.uid.isEmpty) return;

    try {
      final isFavoritedFound = await SocialService().isFavorited(
        user.uid,
        _effectivePost.postId,
      );
      if (mounted) {
        setState(() {
          _isFavorited = isFavoritedFound;
        });
      }
    } catch (_) {
      // Fail silently for background checks
    }
  }

  Future<void> _toggleFavorite() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    setState(() {
      _isFavorited = !_isFavorited;
    });

    await SocialService().toggleFavorite(user.uid, _effectivePost.postId);
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

  Future<void> _handleDownload() async {
    final post = widget.post;
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
      if (mounted) await _checkCache();

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

  Widget _buildPostMedia(BuildContext context, PostModel post) {
    final urls = post.imageUrls;
    final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
    const double phi = 1.61803398875; // 🚀 Golden Ratio

    // Standardize to list
    final mediaUrls = urls.isNotEmpty
        ? urls
        : (post.imageUrl != null ? [post.imageUrl!] : <String>[]);

    String getVideoSource() {
      return _cachedMedia[post.videoUrl] ?? post.videoUrl!;
    }

    ImageProvider getImageProvider(String url) {
      final localPath = _cachedMedia[url];
      if (localPath != null) {
        return FileImage(File(localPath));
      }
      return CachedNetworkImageProvider(url);
    }

    void openImageViewer(int index) {
      final providers = mediaUrls.map((url) => getImageProvider(url)).toList();
      final videoSrc = hasVideo ? getVideoSource() : null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageViewScreen(
            imageUrls: null, // Use providers instead
            imageProviders: providers, // Pass cached providers
            videoUrl: videoSrc,
            initialIndex: index,
            heroTagPrefix: 'detail_${post.postId}${hasVideo ? '_video' : ''}',
          ),
        ),
      );
    }

    Widget buildVideo() {
      return GestureDetector(
        onTap: () => openImageViewer(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SocialVideoPlayer(videoUrl: getVideoSource(), autoPlay: false),
        ),
      );
    }

    Widget buildImage(String url, int index) {
      final localPath = _cachedMedia[url];
      final imageWidget = localPath != null
          ? Image.file(
              File(localPath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const Icon(Icons.error),
            )
          : CachedNetworkImage(
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
            );

      return GestureDetector(
        onTap: () => openImageViewer(hasVideo ? index + 1 : index),
        child: Hero(tag: 'detail_${post.postId}_$index', child: imageWidget),
      );
    }

    if (!hasVideo && mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double goldenHeight = width / phi;

          if (hasVideo && mediaUrls.isEmpty) {
            return SizedBox(
              height: goldenHeight,
              width: width,
              child: buildVideo(),
            );
          }

          if (!hasVideo && mediaUrls.length == 1) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: AspectRatio(
                aspectRatio: phi,
                child: buildImage(mediaUrls[0], 0),
              ),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              height: goldenHeight,
              child: Builder(
                builder: (context) {
                  // Case 1: Video + 1 Image or just 2 Images
                  if (hasVideo && mediaUrls.length == 1) {
                    return Row(
                      children: [
                        Expanded(child: buildVideo()),
                        SizedBox(width: 2.w),
                        Expanded(child: buildImage(mediaUrls[0], 0)),
                      ],
                    );
                  }

                  if (mediaUrls.length == 2 && !hasVideo) {
                    return Row(
                      children: [
                        Expanded(child: buildImage(mediaUrls[0], 0)),
                        SizedBox(width: 2.w),
                        Expanded(child: buildImage(mediaUrls[1], 1)),
                      ],
                    );
                  }

                  // Case 2: Video + 2 Images or just 3 Images
                  if (hasVideo && mediaUrls.length == 2) {
                    return Row(
                      children: [
                        Expanded(child: buildVideo()),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: buildImage(mediaUrls[0], 0)),
                              SizedBox(height: 2.h),
                              Expanded(child: buildImage(mediaUrls[1], 1)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  if (mediaUrls.length == 3 && !hasVideo) {
                    return Row(
                      children: [
                        Expanded(child: buildImage(mediaUrls[0], 0)),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: buildImage(mediaUrls[1], 1)),
                              SizedBox(height: 2.h),
                              Expanded(child: buildImage(mediaUrls[2], 2)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Default fallback for other cases (e.g. 4+ images) - simplifying for now or handling as per original logic if it had one.
                  // Original code ended at 3 images logic. I'll maintain that.
                  // Check if there are more complex cases?
                  // The viewing window showed up to Case 2. I'll assume that's the extent or return a generic Grid/List if needed.
                  // For safety, if none match, return first image or something safe.

                  return SizedBox(
                    height: goldenHeight,
                    child: !hasVideo && mediaUrls.isNotEmpty
                        ? buildImage(mediaUrls[0], 0)
                        : (hasVideo ? buildVideo() : const SizedBox.shrink()),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkIfJoined() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    final targetPost = _effectivePost.communityId != null
        ? _effectivePost
        : _effectivePost.originalPost;

    if (targetPost == null || targetPost.communityId == null) return;

    try {
      final isMember = await CommunityService().isMember(
        targetPost.communityId!,
        user.uid,
      );
      if (mounted) {
        setState(() {
          _isJoined = isMember;
        });
      }
    } catch (_) {
      // Fail silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = _effectivePost;
    final username = '@${post.authorName.replaceAll(' ', '').toLowerCase()}';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Community Header (If Applicable) ---
          _buildCommunityHeader(context, theme, post),
          if (post.communityName != null ||
              post.originalPost?.communityName != null)
            SizedBox(height: 4.h),

          // --- Header (User Info) ---
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (post.authorPhotoUrl != null)
                    ? CachedNetworkImageProvider(post.authorPhotoUrl!)
                    : null,
                child: (post.authorPhotoUrl == null)
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),

              SizedBox(width: 12.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    Text(
                      username,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),

              /// RIGHT SIDE (Options + Join)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.more_outline, color: Colors.grey),
                    onPressed: () {
                      final user = context.read<AuthService>().user;

                      if (user == null) {
                        MessageBanner.show(
                          context,
                          message: 'Please sign in for options',
                          type: MessageType.warning,
                        );
                        return;
                      }

                      final isAuthor = user.uid == widget.post.authorId;

                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => PostOptionsBottomSheet(
                          isAuthor: isAuthor,
                          onDelete: _confirmDelete,
                          onHide: _hidePost,
                          onShare: _handleShareSheet,
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
                                  (post.pollData?.totalVotes ?? 0) == 0)
                              ? () {
                                  context.pushNamed(
                                    AppRouter.createPostName,
                                    extra: post,
                                  );
                                }
                              : null,
                          onFollow: user.uid == post.authorId
                              ? null
                              : () async {
                                  await SocialService().followUser(
                                    user.uid,
                                    post.authorId,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Following user'),
                                    ),
                                  );
                                },
                          onReport: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useRootNavigator: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ReportBottomSheet(
                                postId: post.postId,
                                onReportSubmitted: _handleReport,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // --- Post Content ---
          if (post.text.isNotEmpty)
            LinkableText(
              text: post.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 20.sp,
                height: 1.4,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),

          // 🚀 Subject & Category Badges
          if (post.subjectName != null ||
              post.tags.isNotEmpty ||
              post.category != PostCategory.general)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
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
                          color: theme.primaryColor.withValues(alpha: 0.1),
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
                          pathParameters: {'type': 'tag', 'value': tag},
                          extra: '#$tag',
                        );
                      },
                      child: Container(
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
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // 🚀 Formal Link Attachment
          if (post.linkUrl != null)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: InkWell(
                onTap: () {
                  if (post.linkUrl != null) {
                    WebViewScreen.show(context, post.linkUrl!);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.link_outline,
                        size: 20.sp,
                        color: theme.primaryColor,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          post.linkUrl!,
                          style: TextStyle(
                            fontSize: 15.sp,
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
                        size: 16.sp,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- Media Section (Images & Video) ---
          _buildPostMedia(context, post),

          // --- Poll ---
          if (post.pollData != null)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: PollWidget(postId: post.postId, pollData: post.pollData!),
            ),

          // --- Quoted Post Preview ---
          if (post.originalPost != null)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: _buildQuotePreview(
                context: context,
                theme: theme,
                post: post.originalPost!,
              ),
            ),

          SizedBox(height: 16.h),

          // --- Timestamp ---
          Text(
            _formatTimestamp(post.createdAt),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 14.sp,
            ),
          ),

          if (_viewCount > 0) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  '$_viewCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Views',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],

          Divider(height: 24.h, thickness: 0.5),

          // --- Stats (Reposts, Likes, Shares) ---
          if (_likeCount > 0 ||
              post.replyCount > 0 ||
              _reShareCount > 0 ||
              _shareCount > 0) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: [
                  if (post.replyCount > 0)
                    _buildStatItem('Replies', post.replyCount),
                  if (_reShareCount > 0)
                    _buildStatItem('Reposts', _reShareCount),
                  if (_likeCount > 0) _buildStatItem('Likes', _likeCount),
                  if (_shareCount > 0) _buildStatItem('Shares', _shareCount),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
          ],

          // --- Action Bar ---
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Iconsax.messages_2_outline,
                  color: Colors.grey.shade600,
                  onTap: () {
                    // Logic to focus reply field
                    widget.replyFocusNode.requestFocus();
                  },
                ),
                _buildActionButton(
                  icon: Iconsax.repeat_outline,
                  color: _reShareCount > 0
                      ? Colors.green
                      : Colors.grey.shade600,
                  onTap: _handleReShare,
                ),
                _buildActionButton(
                  icon: _isLiked ? Iconsax.heart_bold : Iconsax.heart_outline,
                  color: _isLiked ? Colors.pink : Colors.grey.shade600,
                  onTap: _toggleLike,
                ),
                _buildActionButton(
                  icon: Iconsax.export_3_outline,
                  color: _shareCount > 0
                      ? theme.primaryColor
                      : Colors.grey.shade600,
                  onTap: _handleShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityHeader(
    BuildContext context,
    ThemeData theme,
    PostModel post,
  ) {
    final targetPostNullable = post.communityId != null
        ? post
        : post.originalPost;
    if (targetPostNullable?.communityId == null) return const SizedBox.shrink();

    final targetPost = targetPostNullable!;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            context.pushNamed(
              AppRouter.communityName,
              pathParameters: {'communityId': targetPost.communityId!},
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 24.sp,
                height: 24.sp,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child:
                      targetPost.communityIcon != null &&
                          targetPost.communityIcon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: targetPost.communityIcon!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          padding: EdgeInsets.all(4.w),
                          child: Icon(
                            Icons.groups_rounded,
                            size: 14.sp,
                            color: theme.primaryColor,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetPost.communityName ?? 'Community',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (post.isReShare)
                    Text(
                      'Reshared from',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),

        // Join Button
        Builder(
          builder: (context) {
            final user = context.read<AuthService>().user;

            // If not logged in, show join button
            if (user == null) {
              return _buildJoinButton(
                context: context,
                post: targetPost,
                theme: theme,
              );
            }

            return _buildJoinButton(
              context: context,
              post: targetPost,
              theme: theme,
              isJoined: _isJoined,
            );
          },
        ),
      ],
    );
  }

  Widget _buildJoinButton({
    required BuildContext context,
    required PostModel post,
    required ThemeData theme,
    bool isJoined = false,
  }) {
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  if (isJoined) {
                    context.pushNamed(
                      AppRouter.communityName,
                      pathParameters: {'communityId': post.communityId!},
                    );
                    return;
                  }
                  final user = context.read<AuthService>().user;

                  if (user == null) {
                    MessageBanner.show(
                      context,
                      message: 'Please sign in to join communities.',
                      type: MessageType.info,
                    );
                    return;
                  }

                  setLocalState(() => isLoading = true);

                  await CommunityService().joinCommunity(
                    post.communityId!,
                    user.uid,
                  );

                  if (!context.mounted) return;

                  // Update state immediately
                  setState(() {
                    _isJoined = true;
                  });

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommunityQuickJoinBottomSheet(
                      communityId: post.communityId!,
                      alreadyJoined: true,
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isJoined
                ? theme.disabledColor.withValues(alpha: 0.1)
                : theme.primaryColor,
            foregroundColor: isJoined ? theme.disabledColor : Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            minimumSize: Size(60.w, 32.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: isJoined
                  ? BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))
                  : BorderSide.none,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 12.sp,
                  height: 12.sp,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isJoined ? 'Joined' : 'Join',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isJoined ? FontWeight.normal : FontWeight.bold,
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
                // 🚀 Header Join Button
                if (post.communityId != null)
                  Builder(
                    builder: (context) {
                      final user = context.read<AuthService>().user;
                      if (user == null) {
                        return Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: _buildJoinButton(
                            context: context,
                            post: post,
                            theme: theme,
                          ),
                        );
                      }

                      return FutureBuilder<bool>(
                        future: CommunityService().isMember(
                          post.communityId!,
                          user.uid,
                        ),
                        builder: (context, snapshot) {
                          final isJoined = snapshot.data ?? false;

                          return Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: _buildJoinButton(
                              context: context,
                              post: post,
                              theme: theme,
                              isJoined: isJoined,
                            ),
                          );
                        },
                      );
                    },
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

            // Quoted Media Preview
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 24.sp),
      color: color,
      onPressed: onTap,
      splashRadius: 24.r,
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Padding(
      padding: EdgeInsets.only(right: 20.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15.sp),
          ),
        ],
      ),
    );
  }
}

class _ReplyWidget extends StatefulWidget {
  final ReplyModel reply;
  final String postId;
  final Function(ReplyModel)? onReply;

  const _ReplyWidget({required this.reply, required this.postId, this.onReply});

  @override
  State<_ReplyWidget> createState() => _ReplyWidgetState();
}

class _ReplyWidgetState extends State<_ReplyWidget> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isHelpful = false;
  int _helpfulCount = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.reply.likeCount;
    _helpfulCount = widget.reply.helpfulCount;
    _isHelpful = widget.reply.isMarkedHelpful;
    _checkIfLiked();
    _checkIfHelpful();
  }

  Future<void> _checkIfHelpful() async {
    final uid = context.read<AuthService>().user?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('replies')
          .doc(widget.reply.replyId)
          .collection('helpful')
          .doc(uid)
          .get();
      if (mounted) {
        setState(() => _isHelpful = doc.exists || widget.reply.isMarkedHelpful);
      }
    } catch (_) {}
  }

  Future<void> _toggleHelpful() async {
    final authService = context.read<AuthService>();
    if (authService.user == null) {
      MessageBanner.show(
        context,
        message: 'Please sign in to mark answers as helpful',
        type: MessageType.warning,
      );
      return;
    }

    final wasHelpful = _isHelpful;
    setState(() {
      _isHelpful = !_isHelpful;
      _helpfulCount += _isHelpful ? 1 : -1;
    });

    try {
      await _apiService.markAnswerAsHelpful(
        postId: widget.postId,
        replyId: widget.reply.replyId,
        userId: authService.user!.uid,
        isHelpful: _isHelpful,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isHelpful = wasHelpful;
          _helpfulCount += _isHelpful ? 1 : -1;
        });
        MessageBanner.show(
          context,
          message: 'Failed to update helpful status',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _checkIfLiked() async {
    final uid = context.read<AuthService>().user?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('replies')
          .doc(widget.reply.replyId)
          .collection('likes')
          .doc(uid)
          .get();
      if (mounted) setState(() => _isLiked = doc.exists);
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final authService = context.read<AuthService>();
    if (authService.user == null) return;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    final error = await authService.likeReply(
      widget.postId,
      widget.reply.replyId,
      widget.reply.authorId,
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

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reply = widget.reply;
    final isNested = reply.parentId != null;

    return Container(
      padding: EdgeInsets.only(
        left: isNested ? 48.w : 16.w,
        right: 16.w,
        top: 8.h,
        bottom: 8.h,
      ),
      color: reply.isAnswer ? Colors.green.withValues(alpha: 0.05) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundImage: (reply.authorPhotoUrl != null)
                ? CachedNetworkImageProvider(reply.authorPhotoUrl!)
                : null,
            child: (reply.authorPhotoUrl == null)
                ? const Icon(Icons.person, size: 16, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.authorName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reply.isAnswer) ...[
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'ANSWER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatTimestamp(reply.createdAt),
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                if (reply.replyToUserName != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      'Replying to @${reply.replyToUserName}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                LinkableText(
                  text: reply.text,
                  style: theme.textTheme.bodyMedium,
                ),

                // Multi-Image Display
                if (reply.imageUrls.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: reply.imageUrls.length > 1 ? 2 : 1,
                          crossAxisSpacing: 4.w,
                          mainAxisSpacing: 4.h,
                          childAspectRatio: reply.imageUrls.length == 1
                              ? 16 / 9
                              : 1,
                        ),
                        itemCount: reply.imageUrls.length,
                        itemBuilder: (context, idx) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewScreen(
                                  imageUrls: reply.imageUrls,
                                  initialIndex: idx,
                                  heroTagPrefix: 'reply_${reply.replyId}',
                                ),
                              ),
                            );
                          },
                          child: CachedNetworkImage(
                            imageUrl: reply.imageUrls[idx],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Video Display
                if (reply.videoUrl != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: SocialVideoPlayer(
                        videoUrl: reply.videoUrl!,
                        autoPlay: false,
                      ),
                    ),
                  ),

                SizedBox(height: 12.h),
                Row(
                  children: [
                    _buildReplyAction(
                      icon: _isLiked
                          ? Iconsax.heart_bold
                          : Iconsax.heart_outline,
                      label: '$_likeCount',
                      color: _isLiked ? Colors.pink : Colors.grey,
                      onTap: _toggleLike,
                    ),
                    SizedBox(width: 24.w),
                    _buildReplyAction(
                      icon: (_isHelpful || reply.isMarkedHelpful)
                          ? Iconsax.tick_circle_bold
                          : Iconsax.tick_circle_outline,
                      label: '$_helpfulCount',
                      color: (_isHelpful || reply.isMarkedHelpful)
                          ? Colors.green
                          : Colors.grey,
                      onTap: _toggleHelpful,
                    ),
                    SizedBox(width: 24.w),
                    _buildReplyAction(
                      icon: Iconsax.messages_outline,
                      label: 'Reply',
                      color: Colors.grey,
                      onTap: () => widget.onReply?.call(reply),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
