import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:math/data/models/user_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/services/auth_service.dart';
import 'package:math/widgets/message_banner.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum UserListType { muted, blocked }

class UserListScreen extends StatefulWidget {
  final UserListType type;

  const UserListScreen({super.key, required this.type});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final SocialService _socialService = SocialService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authService = context.read<AuthService>();
    final userModel = authService.userModel;
    if (userModel == null) return;

    final uids = widget.type == UserListType.muted
        ? userModel.mutedUsers
        : userModel.blockedUsers;

    if (uids.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final users = await _socialService.getUsers(uids);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(UserModel user) async {
    final authService = context.read<AuthService>();
    final myUid = authService.user?.uid;
    if (myUid == null) return;

    try {
      if (widget.type == UserListType.muted) {
        await _socialService.unmuteUser(myUid, user.uid);
      } else {
        await _socialService.unblockUser(myUid, user.uid);
      }

      setState(() {
        _users.removeWhere((u) => u.uid == user.uid);
      });

      if (mounted) {
        MessageBanner.show(
          context,
          message: widget.type == UserListType.muted
              ? "${user.displayName} unmuted"
              : "${user.displayName} unblocked",
          type: MessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: "Failed to perform action",
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.type == UserListType.muted
        ? "Muted Accounts"
        : "Blocked Accounts";

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return _buildUserTile(user, theme);
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.type == UserListType.muted
                ? EvaIcons.bell_off_outline
                : EvaIcons.slash_outline,
            size: 64.sp,
            color: theme.disabledColor.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            widget.type == UserListType.muted
                ? "No muted accounts"
                : "No blocked accounts",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                ? CachedNetworkImageProvider(user.photoURL!)
                : null,
            child: (user.photoURL == null || user.photoURL!.isEmpty)
                ? Text(user.displayName[0].toUpperCase())
                : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.bio != null)
                  Text(
                    user.bio!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _handleAction(user),
            child: Text(
              widget.type == UserListType.muted ? "Unmute" : "Unblock",
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
