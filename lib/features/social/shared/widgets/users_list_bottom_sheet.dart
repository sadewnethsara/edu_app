import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/user_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/features/social/shared/widgets/user_profile_bottom_sheet.dart';
import 'package:math/core/widgets/standard_bottom_sheet.dart';

enum UserListType { followers, following }

class UsersListBottomSheet extends StatefulWidget {
  final String userId;
  final UserListType type;

  const UsersListBottomSheet({
    super.key,
    required this.userId,
    required this.type,
  });

  @override
  State<UsersListBottomSheet> createState() => _UsersListBottomSheetState();
}

class _UsersListBottomSheetState extends State<UsersListBottomSheet> {
  final SocialService _socialService = SocialService();
  List<String> _userIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserIds();
  }

  Future<void> _fetchUserIds() async {
    try {
      final snapshot = widget.type == UserListType.followers
          ? await _socialService.getFollowersStream(widget.userId).first
          : await _socialService.getFollowingStream(widget.userId).first;

      if (mounted) {
        setState(() {
          _userIds = snapshot.docs.map((doc) => doc.id).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == UserListType.followers
        ? 'Followers'
        : 'Following';

    if (_isLoading) {
      return StandardBottomSheet(
        title: title,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_userIds.isEmpty) {
      return StandardBottomSheet(
        title: title,
        isContentScrollable: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'No users found',
                  style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userIds = _userIds;
    return FutureBuilder<List<UserModel>>(
      future: _socialService.getUsers(userIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading users'));
        }

        final users = snapshot.data ?? [];
        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoURL != null
                    ? CachedNetworkImageProvider(user.photoURL!)
                    : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
              title: Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '@${user.displayName.replaceAll(' ', '').toLowerCase()}',
              ),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      UserProfileBottomSheet(userId: user.uid),
                );
              },
            );
          },
        );
      },
    );
  }
}
