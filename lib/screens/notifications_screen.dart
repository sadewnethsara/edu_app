import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:math/data/models/notification_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/screens/notification_settings_screen.dart';
import 'package:animations/animations.dart';
import 'package:math/features/social/feed/screens/post_detail_screen.dart'; // Assuming this exists based on previous verification
import 'package:math/features/social/community/screens/community_posts_review_screen.dart';
import 'package:math/widgets/message_banner.dart';
import 'package:math/services/api_service.dart';
import 'package:math/services/auth_service.dart';
import 'package:math/widgets/standard_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum NotificationFilterType { all, unread, mentions, system }

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Local state to simulate data management for UI demo
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<NotificationModel> _notifications =
      []; // List.from(kDummyNotifications);
  NotificationFilterType _currentFilter = NotificationFilterType.all;
  DateTime? _selectedDate; // NEW: Date Filter State
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }

      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      } else {
        _isSelectionMode = true;
      }
    });
  }

  void _enterSelectionMode(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final myUid = authService.user?.uid;

      if (myUid != null) {
        final notifications = await _apiService.getNotifications(myUid);
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageBanner.show(
          context,
          message: 'Failed to load notifications',
          type: MessageType.error,
        );
      }
    }
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(_notifications.map((e) => e.id));
    });
  }

  void _markAllRead() {
    final authService = context.read<AuthService>();
    if (authService.user != null) {
      SocialService().markAllAsRead(authService.user!.uid);
    }

    setState(() {
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          createdAt: n.createdAt,
          isRead: true,
          type: n.type,
          senderId: n.senderId,
          senderName: n.senderName,
          senderPhotoUrl: n.senderPhotoUrl,
          targetContentId: n.targetContentId,
        );
      }).toList();
    });

    MessageBanner.show(
      context,
      message: "All notifications marked as read",
      type: MessageType.success,
    );
  }

  void _deleteSelected() {
    setState(() {
      _notifications.removeWhere((n) => _selectedIds.contains(n.id));
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    MessageBanner.show(
      context,
      message: "Selected notifications deleted",
      type: MessageType.success,
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _markAsRead(String id) {
    final authService = context.read<AuthService>();
    if (authService.user != null) {
      _apiService.markNotificationAsRead(authService.user!.uid, id);
    }

    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      setState(() {
        final n = _notifications[index];
        _notifications[index] = NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          createdAt: n.createdAt,
          isRead: true,
          type: n.type,
          senderId: n.senderId,
          senderName: n.senderName,
          senderPhotoUrl: n.senderPhotoUrl,
          targetContentId: n.targetContentId,
        );
      });
    }
  }

  List<NotificationModel> get _filteredNotifications {
    // 1. First filter by Type
    List<NotificationModel> listByType;
    switch (_currentFilter) {
      case NotificationFilterType.unread:
        listByType = _notifications.where((n) => !n.isRead).toList();
        break;
      case NotificationFilterType.mentions:
        listByType = _notifications
            .where(
              (n) => [
                NotificationType.postReply,
                NotificationType.newFollower,
                NotificationType.postLike,
              ].contains(n.type),
            )
            .toList();
        break;
      case NotificationFilterType.system:
        listByType = _notifications
            .where(
              (n) => [
                NotificationType.system,
                NotificationType.grade,
                NotificationType.achievement,
                NotificationType.communityJoin,
                NotificationType.communityMemberJoin,
                NotificationType.communityCreated,
              ].contains(n.type),
            )
            .toList();
        break;
      case NotificationFilterType.all:
        listByType = _notifications;
        break;
    }

    // 2. Then filter by Date if selected
    if (_selectedDate != null) {
      return listByType.where((n) {
        return n.createdAt.year == _selectedDate!.year &&
            n.createdAt.month == _selectedDate!.month &&
            n.createdAt.day == _selectedDate!.day;
      }).toList();
    }

    return listByType;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Theme.of(context).primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      // Keep sheet open so user can see the filter applied
      // Navigator.pop(context);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StandardBottomSheet(
          title: "Filter Notifications",
          icon: EvaIcons.bell_outline,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(
                context,
                title: "All Notifications",
                type: NotificationFilterType.all,
                icon: EvaIcons.bell_outline,
              ),
              _buildFilterOption(
                context,
                title: "Unread",
                type: NotificationFilterType.unread,
                icon: EvaIcons.email_outline,
              ),
              _buildFilterOption(
                context,
                title: "Mentions & Social",
                type: NotificationFilterType.mentions,
                icon: EvaIcons.at_outline,
              ),
              _buildFilterOption(
                context,
                title: "System & Updates",
                type: NotificationFilterType.system,
                icon: EvaIcons.settings_2_outline,
              ),

              Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
              ),

              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _selectedDate != null
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    EvaIcons.calendar_outline,
                    color: _selectedDate != null
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).iconTheme.color,
                    size: 24.sp,
                  ),
                ),
                title: Text(
                  _selectedDate == null
                      ? "Filter by Date"
                      : "Date: ${DateFormat('MMM d, y').format(_selectedDate!)}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _selectedDate != null
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                ),
                trailing: _selectedDate != null
                    ? IconButton(
                        icon: const Icon(
                          EvaIcons.close_circle,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _selectedDate = null);
                          Navigator.pop(context);
                        },
                      )
                    : Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16.sp,
                        color: Theme.of(context).disabledColor,
                      ),
                onTap: _pickDate,
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required String title,
    required NotificationFilterType type,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = _currentFilter == type;
    final color = isSelected ? theme.primaryColor : theme.iconTheme.color;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? theme.primaryColor
              : theme.textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Icon(EvaIcons.checkmark_circle_2, color: theme.primaryColor)
          : null,
      onTap: () {
        setState(() => _currentFilter = type);
        Navigator.pop(context); // Close sheet on selection for smooth feel
      },
    );
  }

  Widget _getDestinationScreen(NotificationModel notification) {
    if (notification.type == NotificationType.postPendingApproval &&
        notification.targetContentId != null) {
      return CommunityPostsReviewScreen(
        communityId: notification.targetContentId!,
      );
    }

    if (notification.type == NotificationType.postApproved &&
        notification.targetContentId != null) {
      return PostDetailScreen(postId: notification.targetContentId!);
    }

    if (notification.targetContentId != null &&
        (notification.type == NotificationType.postLike ||
            notification.type == NotificationType.postReply ||
            notification.type == NotificationType.newFollower)) {
      // For newFollower, sticking to post if ID exists for now.
      if (notification.type != NotificationType.newFollower) {
        return PostDetailScreen(postId: notification.targetContentId!);
      }
    }
    return _GenericNotificationDetail(notification: notification);
  }

  Widget _buildShimmerList(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade900 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar placeholder
                  CircleAvatar(radius: 20.r, backgroundColor: Colors.white),
                  SizedBox(width: 12.w),
                  // Content placeholder
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          height: 10.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 10.h,
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
          );
        },
        childCount: 8, // Show 8 shimmer placeholders
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: theme.primaryColor,
        child: CustomScrollView(
          slivers: [
            // Dynamic App Bar
            SliverAppBar(
              expandedHeight: 120.h,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? Colors.black : const Color(0xFF0B1C2C),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "Notifications",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF0F172A), // Slate 900
                              const Color(0xFF000000), // Pure Black
                            ]
                          : [
                              const Color(0xFF0B1C2C),
                              const Color(0xFF0B1C2C).withValues(alpha: 0.8),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -30,
                        top: -30,
                        child: Icon(
                          EvaIcons.bell_outline,
                          size: 160.sp,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (_isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(
                      EvaIcons.checkmark_outline,
                      color: Colors.white,
                    ),
                    tooltip: "Select All",
                    onPressed: _selectAll,
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.trash_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: "Delete Selected",
                    onPressed: _deleteSelected,
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(
                      EvaIcons.checkmark_circle_2_outline,
                      color: Colors.white,
                    ),
                    tooltip: "Mark all as read",
                    onPressed: _markAllRead,
                  ),
                  IconButton(
                    icon: Icon(
                      _currentFilter == NotificationFilterType.all
                          ? Iconsax.filter_outline
                          : EvaIcons.funnel,
                      color: _currentFilter == NotificationFilterType.all
                          ? Colors.white
                          : Colors.amber,
                    ),
                    tooltip: "Filter",
                    onPressed: _showFilterBottomSheet,
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.setting_outline,
                      color: Colors.white,
                    ),
                    tooltip: "Settings",
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
              // Update Leading to handle selection mode close button color
              leading: _isSelectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedIds.clear();
                          _isSelectionMode = false;
                        });
                      },
                    )
                  : null,
            ),

            // Content
            if (_isLoading && _notifications.isEmpty)
              _buildShimmerList(theme)
            else if (_filteredNotifications.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        EvaIcons.bell_off_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "No notifications yet",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final notification = _filteredNotifications[index];
                  final isSelected = _selectedIds.contains(notification.id);

                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      color: Colors.blueAccent,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: const Icon(
                        EvaIcons.checkmark_circle_2,
                        color: Colors.white,
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: const Icon(EvaIcons.trash_2, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        _deleteNotification(notification.id);
                        return true;
                      } else {
                        _markAsRead(notification.id);
                        return false;
                      }
                    },
                    child: OpenContainer(
                      tappable: false,
                      closedElevation: 0,
                      openElevation: 0,
                      closedColor: Colors.transparent,
                      openColor: theme.scaffoldBackgroundColor,
                      transitionType: ContainerTransitionType.fadeThrough,
                      transitionDuration: const Duration(milliseconds: 500),
                      openBuilder: (context, action) {
                        return _getDestinationScreen(notification);
                      },
                      closedBuilder: (context, openContainer) {
                        return InkWell(
                          onLongPress: () =>
                              _enterSelectionMode(notification.id),
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(notification.id);
                            } else {
                              _markAsRead(notification.id);
                              openContainer();
                            }
                          },
                          child: Container(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : (notification.isRead
                                      ? Colors.transparent
                                      : theme.colorScheme.primary.withValues(
                                          alpha: 0.05,
                                        )),
                            child: _NotificationTile(
                              notification: notification,
                              isSelected: isSelected,
                              selectionMode: _isSelectionMode,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }, childCount: _filteredNotifications.length),
              ),

            SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isSelected;
  final bool selectionMode;

  const _NotificationTile({
    required this.notification,
    required this.isSelected,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Checkbox or Icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectionMode
                ? Container(
                    margin: EdgeInsets.only(right: 12.w, top: 4.h),
                    child: Icon(
                      isSelected
                          ? EvaIcons.checkmark_circle_2
                          : EvaIcons.radio_button_off,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                      size: 24.sp,
                    ),
                  )
                : _buildAvatar(context),
          ),

          if (!selectionMode) SizedBox(width: 12.w),

          // 2. Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Sender Name
                    if (notification.senderName != null) ...[
                      Text(
                        notification.senderName!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _getActionText(notification.type),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            // Use unread style if needed
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Time and Unread Dot
                    const Spacer(),
                    Text(
                      _formatTime(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.disabledColor,
                        fontSize: 11.sp,
                      ),
                    ),
                    if (!notification.isRead) ...[
                      SizedBox(width: 8.w),
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                // Message Body
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Optional: Action Buttons or Content Preview below can be added here
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (notification.senderPhotoUrl != null) {
      return CircleAvatar(
        radius: 20.r,
        backgroundImage: NetworkImage(notification.senderPhotoUrl!),
      );
    }

    // Icon based avatar
    Color iconColor;
    IconData icon;

    switch (notification.type) {
      case NotificationType.grade:
        icon = EvaIcons.book_open_outline;
        iconColor = Colors.blue;
        break;
      case NotificationType.achievement:
        icon = EvaIcons.award_outline;
        iconColor = Colors.amber;
        break;
      case NotificationType.newFollower:
        icon = EvaIcons.person_add_outline;
        iconColor = Colors.cyan;
        break;
      case NotificationType.postLike:
        icon = EvaIcons.heart_outline;
        iconColor = Colors.pinkAccent;
        break;
      case NotificationType.postReply:
        icon = EvaIcons.message_circle_outline;
        iconColor = Colors.green;
        break;
      case NotificationType.communityJoin:
        icon = EvaIcons.people_outline;
        iconColor = Colors.orange;
        break;
      case NotificationType.communityMemberJoin:
        icon = EvaIcons.person_done_outline;
        iconColor = Colors.indigo;
        break;
      case NotificationType.communityCreated:
        icon = EvaIcons.plus_square_outline;
        iconColor = Colors.teal;
        break;
      case NotificationType.postApproved:
        icon = EvaIcons.checkmark_circle_2_outline;
        iconColor = Colors.green;
        break;
      case NotificationType.postPendingApproval:
        icon = EvaIcons.clock_outline;
        iconColor = Colors.amber;
        break;
      default:
        icon = EvaIcons.bell_outline;
        iconColor = Colors.purple;
    }

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 20.sp),
    );
  }

  String _getActionText(NotificationType type) {
    switch (type) {
      case NotificationType.newFollower:
        return "followed you";
      case NotificationType.postLike:
        return "liked your post";
      case NotificationType.postReply:
        return "replied to you";
      case NotificationType.communityJoin:
        return "joined";
      case NotificationType.communityMemberJoin:
        return "joined your community";
      case NotificationType.communityCreated:
        return "successfully created";
      case NotificationType.postPendingApproval:
        return "posted a new post requiring review";
      case NotificationType.postApproved:
        return "approved your post";
      default:
        return "";
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}

class _GenericNotificationDetail extends StatelessWidget {
  final NotificationModel notification;

  const _GenericNotificationDetail({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40.r,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                backgroundImage: notification.senderPhotoUrl != null
                    ? NetworkImage(notification.senderPhotoUrl!)
                    : null,
                child: Icon(
                  EvaIcons.bell_outline,
                  size: 40.sp,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                notification.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                notification.message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              if (notification.type == NotificationType.grade)
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Opening Lesson...")),
                    );
                  },
                  icon: const Icon(EvaIcons.book_open_outline),
                  label: const Text("View Lesson"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
