import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'dart:async';

class ProfessionalNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ProfessionalNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<ProfessionalNavBar> createState() => _ProfessionalNavBarState();
}

class _ProfessionalNavBarState extends State<ProfessionalNavBar>
    with SingleTickerProviderStateMixin {
  int _notificationCount = 0;
  bool _showCount = true;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  StreamSubscription<int>? _unreadSubscription;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationStream();
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showCount = false);
      }
    });
  }

  void _setupNotificationStream() {
    final authService = context.read<AuthService>();
    final userId = authService.user?.uid;

    if (userId != null) {
      _unreadSubscription = SocialService()
          .unreadNotificationsCountStream(userId)
          .listen((count) {
            if (mounted) {
              setState(() {
                _notificationCount = count;
                if (count > 0) _showCount = true;
              });
            }
          });
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _unreadSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_NavItem> navItems = [
      _NavItem(
        icon: Iconsax.home_2_outline,
        activeIcon: Iconsax.home_2_bold,
        label: "Home",
      ),
      _NavItem(
        icon: Iconsax.book_outline,
        activeIcon: Iconsax.book_bold,
        label: "Courses",
      ),
      _NavItem(
        icon: Iconsax.home_hashtag_outline,
        activeIcon: Iconsax.home_hashtag_bold,
        label: "Community",
      ),
      _NavItem(
        icon: Iconsax.notification_outline,
        activeIcon: Iconsax.notification_bold,
        label: "Notify",
      ),
      _NavItem(
        icon: Iconsax.user_outline,
        activeIcon: Iconsax.user_bold,
        label: "Profile",
      ),
    ];

    final Color navBarColor = Theme.of(context).scaffoldBackgroundColor;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double barHeight = 55.0 + bottomPadding;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = screenWidth / navItems.length;

    return Container(
      height: barHeight,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: navBarColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < navItems.length; i++)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (i == 3) {
                  final authService = context.read<AuthService>();
                  if (authService.user != null) {
                    SocialService().markAllAsRead(authService.user!.uid);
                  }
                }
                widget.onTap(i);
              },
              behavior: HitTestBehavior.opaque,
              child: _buildIconBtn(i, itemWidth, navItems),
            ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(int i, double itemWidth, List<_NavItem> navItems) {
    bool isActive = widget.currentIndex == i;
    bool isNotification = i == 3;

    return Container(
      width: itemWidth,
      height: 50,
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isActive ? navItems[i].activeIcon : navItems[i].icon,
              key: ValueKey<bool>(isActive),
              size: 26,
            ),
          ),
          if (isActive)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD300),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (isNotification && _notificationCount > 0)
            Positioned(
              bottom: -4,
              right: -4,
              child: _pulseAnimation != null
                  ? AnimatedBuilder(
                      animation: _pulseAnimation!,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation!.value,
                          child: _showCount
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_notificationCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                        );
                      },
                    )
                  : _showCount
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
