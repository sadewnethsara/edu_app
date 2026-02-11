import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/features/social/feed/widgets/tweet_post_widget.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:provider/provider.dart';

class CommunityPostsReviewScreen extends StatefulWidget {
  final String communityId;
  const CommunityPostsReviewScreen({super.key, required this.communityId});

  @override
  State<CommunityPostsReviewScreen> createState() =>
      _CommunityPostsReviewScreenState();
}

class _CommunityPostsReviewScreenState
    extends State<CommunityPostsReviewScreen> {
  final CommunityService _communityService = CommunityService();
  List<PostModel> _pendingPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingPosts();
  }

  Future<void> _loadPendingPosts() async {
    try {
      final posts = await _communityService.getPendingPosts(widget.communityId);
      if (mounted) {
        setState(() {
          _pendingPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approvePost(String postId) async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    try {
      await _communityService.approvePost(postId, user.uid);
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Post approved and published',
          type: MessageType.success,
        );
        _loadPendingPosts();
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to approve post',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _rejectPost(String postId) async {
    try {
      await _communityService.rejectPost(postId);
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Post rejected',
          type: MessageType.info,
        );
        _loadPendingPosts();
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to reject post',
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Review Posts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingPosts.isEmpty
          ? const Center(child: Text('No posts pending review.'))
          : ListView.builder(
              itemCount: _pendingPosts.length,
              itemBuilder: (context, index) {
                final post = _pendingPosts[index];
                return Column(
                  children: [
                    TweetPostWidget(post: post),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _rejectPost(post.postId),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approvePost(post.postId),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
    );
  }
}
