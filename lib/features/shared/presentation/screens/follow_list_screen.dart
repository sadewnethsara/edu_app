import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/models/user_model.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Enum to define what list to show
enum FollowListType { followers, following }

class FollowListScreen extends StatefulWidget {
  final String userId;
  final FollowListType listType;
  final String? initialUsername; // To show in the AppBar immediately

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.listType,
    this.initialUsername,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<UserModel> _users = [];
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthService>().user?.uid ?? '';
    _loadUserList();
  }

  Future<void> _loadUserList() async {
    if (mounted) setState(() => _isLoading = true);

    List<UserModel> userList;
    if (widget.listType == FollowListType.followers) {
      userList = await _apiService.getFollowersList(widget.userId);
    } else {
      userList = await _apiService.getFollowingList(widget.userId);
    }

    if (mounted) {
      setState(() {
        _users = userList;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (widget.listType == FollowListType.followers
        ? 'Followers'
        : 'Following');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (widget.initialUsername != null)
              Text(
                widget.initialUsername!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.appBarTheme.foregroundColor?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _isLoading
            ? _buildShimmerList(theme)
            : _users.isEmpty
            ? _buildEmptyState(theme, title)
            : RefreshIndicator(
                onRefresh: _loadUserList,
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _UserTile(
                      user: user,
                      // Hide follow button if it's the current user
                      isCurrentUser: user.uid == _currentUserId,
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 80.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'No $title Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This list will show users who\n${title.toLowerCase()} this profile.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.scaffoldBackgroundColor,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(backgroundColor: Colors.white, radius: 24.r),
          title: Container(height: 16.h, width: 150.w, color: Colors.white),
          subtitle: Container(height: 12.h, width: 100.w, color: Colors.white),
          trailing: Container(height: 30.h, width: 80.w, color: Colors.white),
        ),
      ),
    );
  }
}

/// A reusable tile for displaying a user in a list
class _UserTile extends StatefulWidget {
  final UserModel user;
  final bool isCurrentUser;

  const _UserTile({required this.user, this.isCurrentUser = false});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    if (widget.isCurrentUser) {
      setState(() => _isLoading = false);
      return;
    }

    final currentUserId = context.read<AuthService>().user?.uid;
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final followDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(widget.user.uid)
          .get();

      if (mounted) {
        setState(() {
          _isFollowing = followDoc.exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();

    String? error;
    if (_isFollowing) {
      error = await authService.unfollowUser(widget.user.uid);
      if (error == null) {
        setState(() => _isFollowing = false);
      }
    } else {
      error = await authService.followUser(widget.user.uid);
      if (error == null) {
        setState(() => _isFollowing = true);
      }
    }

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          // Navigate to this user's profile
          if (!widget.isCurrentUser) {
            context.push('${AppRouter.profilePath}?id=${widget.user.uid}');
          } else {
            context.push(AppRouter.profilePath);
          }
        },
        child: CircleAvatar(
          radius: 24.r,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (widget.user.photoURL != null)
              ? CachedNetworkImageProvider(widget.user.photoURL!)
              : null,
          child: (widget.user.photoURL == null)
              ? Icon(Icons.person, size: 24.sp, color: Colors.grey.shade400)
              : null,
        ),
      ),
      title: Text(
        widget.user.displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${widget.user.points} points',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
      ),
      trailing: widget.isCurrentUser
          ? null // Don't show a button for yourself
          : _isLoading
          ? SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton(
              onPressed: _toggleFollow,
              style: _isFollowing
                  ? FilledButton.styleFrom(
                      backgroundColor: theme.cardColor,
                      foregroundColor: theme.textTheme.bodyLarge?.color,
                      side: BorderSide(color: theme.dividerColor),
                      elevation: 0,
                    )
                  : null,
              child: Text(_isFollowing ? 'Following' : 'Follow'),
            ),
    );
  }
}
