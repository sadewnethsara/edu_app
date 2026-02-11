import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/features/social/community/models/community_member_model.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/core/widgets/message_banner.dart';

class CommunityMembersScreen extends StatefulWidget {
  final String communityId;
  const CommunityMembersScreen({super.key, required this.communityId});

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  final CommunityService _communityService = CommunityService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Community Members',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<CommunityMemberModel>>(
        stream: _communityService.getCommunityMembers(widget.communityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final members = snapshot.data ?? [];
          if (members.isEmpty) {
            return const Center(child: Text('No members found.'));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final bool isPending = member.status == MemberStatus.pending;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    member.userId.isNotEmpty
                        ? member.userId[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(
                  member.userId,
                ), // In a real app, you'd fetch the user name
                subtitle: Text(
                  'Joined ${member.joinedAt.toDate().toString().split(' ')[0]}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPending) ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _updateStatus(member.userId, MemberStatus.approved),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _updateStatus(member.userId, MemberStatus.rejected),
                      ),
                    ] else ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(
                            member.role,
                            theme,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          member.role.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: _getRoleColor(member.role, theme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String userId, MemberStatus status) async {
    try {
      await _communityService.updateMemberStatus(
        widget.communityId,
        userId,
        status,
      );
      if (mounted) {
        MessageBanner.show(
          context,
          message: status == MemberStatus.approved
              ? 'Member approved'
              : 'Member rejected',
          type: MessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Failed to update status',
          type: MessageType.error,
        );
      }
    }
  }

  Color _getRoleColor(CommunityRole role, ThemeData theme) {
    switch (role) {
      case CommunityRole.admin:
        return Colors.red;
      case CommunityRole.moderator:
        return Colors.blue;
      default:
        return theme.textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }
}
