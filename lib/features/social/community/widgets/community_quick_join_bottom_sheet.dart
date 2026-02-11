import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/features/social/community/models/community_model.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/widgets/standard_bottom_sheet.dart';
import 'package:provider/provider.dart';

class CommunityQuickJoinBottomSheet extends StatefulWidget {
  final String communityId;
  final bool alreadyJoined;
  const CommunityQuickJoinBottomSheet({
    super.key,
    required this.communityId,
    this.alreadyJoined = false,
  });

  @override
  State<CommunityQuickJoinBottomSheet> createState() =>
      _CommunityQuickJoinBottomSheetState();
}

class _CommunityQuickJoinBottomSheetState
    extends State<CommunityQuickJoinBottomSheet> {
  bool _isLoading = true;
  CommunityModel? _community;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    final community = await CommunityService().getCommunity(widget.communityId);
    if (mounted) {
      setState(() {
        _community = community;
        _isLoading = false;
      });
    }
  }

  Future<void> _joinCommunity() async {
    final user = context.read<AuthService>().user;
    if (user == null || _community == null) return;

    setState(() => _isJoining = true);
    try {
      await CommunityService().joinCommunity(_community!.id, user.uid);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Joined ${_community!.name}!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join community')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: 300.h,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_community == null) {
      return Container(
        height: 200.h,
        padding: EdgeInsets.all(20.sp),
        child: const Center(child: Text('Community not found')),
      );
    }

    return StandardBottomSheet(
      title: widget.alreadyJoined ? 'Community Info' : 'Join Community',
      icon: Icons.groups_rounded,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border(
                  left: BorderSide(color: theme.primaryColor, width: 4.w),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: _community!.iconUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _community!.iconUrl!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.groups_rounded,
                              size: 28.sp,
                              color: theme.primaryColor,
                            ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _community!.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${_community!.memberCount} members',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              _community!.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.start,
            ),
          ),

          SizedBox(height: 32.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ElevatedButton(
              onPressed: (_isJoining || widget.alreadyJoined)
                  ? (widget.alreadyJoined
                        ? () {
                            Navigator.pop(context);
                            // Maybe open community details? For now just close or do nothing special.
                            // User can tap header in post detail to go to community.
                          }
                        : null)
                  : _joinCommunity,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.alreadyJoined
                    ? Colors.green.withValues(alpha: 0.1)
                    : theme.primaryColor,
                foregroundColor: widget.alreadyJoined
                    ? Colors.green
                    : Colors.white,
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: widget.alreadyJoined
                      ? const BorderSide(color: Colors.green)
                      : BorderSide.none,
                ),
                elevation: 0,
              ),
              child: _isJoining
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.alreadyJoined
                              ? Icons.check_circle_outline
                              : Icons.add_circle_outline,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          widget.alreadyJoined
                              ? 'Already Joined'
                              : 'Join Community',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: 12.h),

          if (!widget.alreadyJoined)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
