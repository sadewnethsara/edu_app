import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/data/models/notification_model.dart';
import 'package:math/router/app_router.dart';
import 'package:math/services/api_service.dart';
import 'package:math/services/auth_service.dart';
import 'package:math/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthService>().user?.uid;
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    try {
      final notifications = await _apiService.getNotifications(_currentUserId!);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      logger.e('Failed to load notifications', error: e, stackTrace: s);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNotificationTapped(NotificationModel notification) {
    if (_currentUserId == null) return;

    // 1. Mark as read (runs in background)
    if (!notification.isRead) {
      _apiService.markNotificationAsRead(_currentUserId!, notification.id);
    }

    // 2. Navigate based on type
    switch (notification.type) {
      case NotificationType.newFollower:
        if (notification.senderId != null) {
          context.push('${AppRouter.profilePath}?id=${notification.senderId}');
        }
        break;
      case NotificationType.postLike:
      case NotificationType.postReply:
        if (notification.targetContentId != null) {
          context.push(
            AppRouter.postDetailPath.replaceFirst(
              ':postId',
              notification.targetContentId!,
            ),
          );
        }
        break;
      case NotificationType.achievement:
        context.push(AppRouter.profilePath); // Navigate to profile
        break;
      case NotificationType.communityJoin:
      case NotificationType.communityMemberJoin:
      case NotificationType.communityCreated:
        if (notification.targetContentId != null) {
          context.push(
            AppRouter.communityPath.replaceFirst(
              ':communityId',
              notification.targetContentId!,
            ),
          );
        }
        break;
      case NotificationType.postApproved:
        if (notification.targetContentId != null) {
          context.push(
            AppRouter.postDetailPath.replaceFirst(
              ':postId',
              notification.targetContentId!,
            ),
          );
        }
        break;
      case NotificationType.postPendingApproval:
        if (notification.targetContentId != null) {
          context.push(
            AppRouter.communityReviewPath.replaceFirst(
              ':communityId',
              notification.targetContentId!,
            ),
          );
        }
        break;
      case NotificationType.adminMessage:
      case NotificationType.system:
      case NotificationType.grade:
      case NotificationType.unknown:
        // No navigation
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.primaryColor,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context.pop(),
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30.w,
                          bottom: -30.h,
                          child: Icon(
                            Iconsax.notification_status_outline,
                            size: 160.sp,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              if (_isLoading)
                _buildShimmerList(theme)
              else if (_notifications.isEmpty)
                _buildEmptyState(theme)
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final notification = _notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => _onNotificationTapped(notification),
                    );
                  }, childCount: _notifications.length),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.notification_status_outline,
              size: 80.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Notifications',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your recent notifications will appear here.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList(ThemeData theme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: theme.cardColor,
          highlightColor: theme.scaffoldBackgroundColor,
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.white, radius: 24.r),
            title: Container(height: 16.h, width: 150.w, color: Colors.white),
            subtitle: Container(
              height: 12.h,
              width: 100.w,
              color: Colors.white,
            ),
            trailing: CircleAvatar(backgroundColor: Colors.white, radius: 6.r),
          ),
        ),
        childCount: 10,
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  IconData _getIconForType() {
    switch (notification.type) {
      case NotificationType.newFollower:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.postLike:
        return Icons.favorite_rounded;
      case NotificationType.postReply:
        return Icons.chat_bubble_rounded;
      case NotificationType.achievement:
        return Icons.emoji_events_rounded;
      case NotificationType.communityJoin:
      case NotificationType.communityMemberJoin:
        return Icons.group_add_rounded;
      case NotificationType.communityCreated:
        return Icons.groups_rounded;
      case NotificationType.postPendingApproval:
        return Icons.pending_actions_rounded;
      case NotificationType.postApproved:
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(ThemeData theme) {
    switch (notification.type) {
      case NotificationType.newFollower:
        return Colors.blue;
      case NotificationType.postLike:
        return Colors.red;
      case NotificationType.postReply:
        return theme.primaryColor;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.communityJoin:
      case NotificationType.communityMemberJoin:
      case NotificationType.communityCreated:
        return Colors.teal;
      case NotificationType.postPendingApproval:
        return Colors.orange;
      case NotificationType.postApproved:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _getColorForType(theme);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.scaffoldBackgroundColor
              : theme.primaryColor.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 1.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Stack(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (notification.senderPhotoUrl != null)
                      ? CachedNetworkImageProvider(notification.senderPhotoUrl!)
                      : null,
                  child: (notification.senderPhotoUrl == null)
                      ? Icon(
                          Icons.person,
                          size: 24.sp,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardColor, width: 2.w),
                    ),
                    child: Icon(
                      _getIconForType(),
                      size: 12.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 16.w),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge,
                      children: [
                        if (notification.senderName != null)
                          TextSpan(
                            text: '${notification.senderName} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        TextSpan(
                          text: notification.message,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            // Read Indicator
            if (!notification.isRead)
              Container(
                width: 10.r,
                height: 10.r,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
