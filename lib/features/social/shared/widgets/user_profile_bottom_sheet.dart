import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/user_model.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/features/social/shared/widgets/user_posts_bottom_sheet.dart';
import 'package:math/features/social/shared/widgets/users_list_bottom_sheet.dart';
import 'package:math/core/widgets/standard_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:math/features/profile/presentation/screens/edit_profile_screen.dart';

class UserProfileBottomSheet extends StatefulWidget {
  final String userId;

  const UserProfileBottomSheet({super.key, required this.userId});

  @override
  State<UserProfileBottomSheet> createState() => _UserProfileBottomSheetState();
}

class _UserProfileBottomSheetState extends State<UserProfileBottomSheet> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isMe = false;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final myUid = context.read<AuthService>().user?.uid;
    if (widget.userId == myUid) {
      _isMe = true;
    }

    final user = await SocialService().getUserProfile(widget.userId);

    bool isFollowing = false;
    if (myUid != null && !_isMe) {
      isFollowing = await SocialService().checkIsFollowing(
        myUid,
        widget.userId,
      );
    }

    if (mounted) {
      setState(() {
        _user = user;
        _isFollowing = isFollowing;
        _followersCount = user?.followersCount ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final myUid = context.read<AuthService>().user?.uid;
    if (myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to follow.')),
      );
      return;
    }

    setState(() {
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
    });

    try {
      if (_isFollowing) {
        await SocialService().followUser(myUid, widget.userId);
      } else {
        await SocialService().unfollowUser(myUid, widget.userId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _followersCount += _isFollowing ? 1 : -1;
        });
      }
    }
  }

  void _showUserPosts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserPostsBottomSheet(userId: widget.userId),
    );
  }

  void _showUserList(UserListType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          UsersListBottomSheet(userId: widget.userId, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const StandardBottomSheet(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_user == null) {
      return const StandardBottomSheet(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text("User not found")),
        ),
      );
    }

    final theme = Theme.of(context);

    return StandardBottomSheet(
      title: 'User Profile',
      icon: Icons.account_circle_outlined,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar & Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _user!.photoURL != null
                    ? CachedNetworkImageProvider(_user!.photoURL!)
                    : null,
                child: _user!.photoURL == null
                    ? Icon(Icons.person, size: 40.sp, color: Colors.grey)
                    : null,
              ),

              if (_isMe)
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? Colors.transparent
                          : theme.primaryColor,
                      foregroundColor: _isFollowing
                          ? theme.textTheme.bodyLarge?.color
                          : Colors.white,
                      elevation: 0,
                      side: _isFollowing
                          ? BorderSide(color: Colors.grey.shade300)
                          : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 10.h,
                      ),
                    ),
                    child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Name & Handle
          Text(
            _user!.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '@${_user!.displayName.replaceAll(' ', '').toLowerCase()}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4.h),
          if (_user!.province != null)
            Text(
              '${_user!.gradeString ?? "Grade"} • ${_user!.province}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),

          SizedBox(height: 16.h),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showUserPosts,
                child: _buildStat(context, 'Posts', '${_user!.postCount}'),
              ),
              SizedBox(width: 24.w),
              GestureDetector(
                onTap: () => _showUserList(UserListType.followers),
                child: _buildStat(context, 'Followers', '$_followersCount'),
              ),
              SizedBox(width: 24.w),
              GestureDetector(
                onTap: () => _showUserList(UserListType.following),
                child: _buildStat(
                  context,
                  'Following',
                  '${_user!.followingCount}',
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),
          Divider(),
          SizedBox(height: 12.h),

          // Achievements Section
          Text(
            'Achievements',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          _user!.achievements.isEmpty
              ? Text(
                  "No achievements yet.",
                  style: TextStyle(color: Colors.grey),
                )
              : Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: _user!.achievements.entries.map((entry) {
                    return Chip(
                      avatar: Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 18.sp,
                      ),
                      label: Text(entry.key),
                      backgroundColor: theme.canvasColor,
                      side: BorderSide(color: Colors.grey.shade300),
                    );
                  }).toList(),
                ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

extension on UserModel {
  String? get gradeString => grades.isNotEmpty ? grades.first : null;
}
