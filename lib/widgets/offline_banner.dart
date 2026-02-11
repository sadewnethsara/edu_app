import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfflineBanner extends StatefulWidget {
  final bool isOnline;
  final bool justCameOnline;

  const OfflineBanner({
    super.key,
    required this.isOnline,
    required this.justCameOnline,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _showOnlineBanner = false;
  bool _showOfflineBanner = false;
  Timer? _offlineTimer;

  @override
  void didUpdateWidget(covariant OfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle offline -> online transition
    if (widget.justCameOnline && !oldWidget.justCameOnline) {
      _offlineTimer?.cancel();
      setState(() {
        _showOfflineBanner = false;
        _showOnlineBanner = true;
      });
      // Hide green banner after 4 seconds
      Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showOnlineBanner = false;
          });
        }
      });
    }
    // Handle online -> offline transition
    else if (!widget.isOnline && oldWidget.isOnline) {
      setState(() {
        _showOfflineBanner = true;
        _showOnlineBanner = false;
      });
      // Auto-hide red banner after 5 seconds
      _offlineTimer?.cancel();
      _offlineTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showOfflineBanner = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _offlineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget will be one of three things:
    // 1. A red "Offline" banner (if offline and just went offline)
    // 2. A green "Back Online" banner (if just came online)
    // 3. Nothing (if online or if offline timer expired)

    Widget banner;
    bool show = false;

    if (_showOfflineBanner) {
      banner = _buildBanner(
        context,
        "You're currently offline",
        "Some features may not work.",
        Colors.red,
        Icons.wifi_off_rounded,
      );
      show = true;
    } else if (_showOnlineBanner) {
      banner = _buildBanner(
        context,
        "Back Online!",
        "Your connection is restored.",
        Colors.green,
        Icons.wifi_rounded,
      );
      show = true;
    } else {
      banner = const SizedBox.shrink();
      show = false;
    }

    // This positions the banner at the top, just below the status bar
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      // Animate from -100.h (off-screen) to the top padding (status bar) + 10.h
      top: show ? MediaQuery.of(context).padding.top + 10.h : -100.h,
      left: 16.w,
      right: 16.w,
      child: banner,
    );
  }

  Widget _buildBanner(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
