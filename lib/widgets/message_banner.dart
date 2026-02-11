import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum MessageType { success, error, info, warning }

class MessageBanner extends StatefulWidget {
  final String message;
  final MessageType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const MessageBanner({
    super.key,
    required this.message,
    this.type = MessageType.info,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
  });

  @override
  State<MessageBanner> createState() => _MessageBannerState();

  // Static method to show banner
  static void show(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10.h,
        left: 16.w,
        right: 16.w,
        child: MessageBanner(
          message: message,
          type: type,
          duration: duration,
          onDismiss: () => overlayEntry.remove(),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after duration
    Timer(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _MessageBannerState extends State<MessageBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto-dismiss
    Timer(widget.duration - const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.type) {
      case MessageType.success:
        return Colors.green.shade700;
      case MessageType.error:
        return Colors.red.shade700;
      case MessageType.warning:
        return Colors.orange.shade700;
      case MessageType.info:
        return Colors.blue.shade700;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_rounded;
      case MessageType.error:
        return Icons.error_rounded;
      case MessageType.warning:
        return Icons.warning_rounded;
      case MessageType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _getColor(),
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
                Icon(_getIcon(), color: Colors.white, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _controller.reverse().then((_) {
                      widget.onDismiss?.call();
                    });
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
