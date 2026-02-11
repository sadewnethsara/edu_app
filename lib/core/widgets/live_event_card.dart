import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:math/core/models/live_event_model.dart';

class LiveEventCard extends StatefulWidget {
  final LiveEvent event;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onJoin;

  const LiveEventCard({
    super.key,
    required this.event,
    required this.isDark,
    required this.theme,
    required this.onJoin,
  });

  @override
  State<LiveEventCard> createState() => _LiveEventCardState();
}

class _LiveEventCardState extends State<LiveEventCard> {
  late Timer _timer;
  Duration _timeLeftToStart = Duration.zero;
  Duration _timeLeftToLink = Duration.zero;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _isLive = widget.event.isLive;
    _calculateTimeLeft();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateTimeLeft(),
    );
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();

    // Check if event is forcibly live by admin
    if (widget.event.isLive) {
      if (mounted) setState(() => _isLive = true);
      return;
    }

    // Calculate time until event start
    if (now.isAfter(widget.event.startTime)) {
      _timeLeftToStart = Duration.zero;
    } else {
      _timeLeftToStart = widget.event.startTime.difference(now);
    }

    // Calculate time until link enable
    final linkEnableTime =
        widget.event.linkEnableTime ?? widget.event.startTime;
    if (now.isAfter(linkEnableTime)) {
      _timeLeftToLink = Duration.zero;
    } else {
      _timeLeftToLink = linkEnableTime.difference(now);
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h';
    }
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Button is enabled if:
    // 1. Event is marked isLive OR
    // 2. Link enable time has passed (timeLeftToLink <= 0)
    bool isLinkEnabled = _isLive || _timeLeftToLink.inSeconds <= 0;

    // Display different text based on state
    String buttonText;
    if (isLinkEnabled) {
      buttonText = "Join Meeting";
    } else {
      // If we have a separate linkEnableTime, we might want to show that countdown
      // But typically user cares about when event starts.
      // If link enables BEFORE start, we show "Link active in X"
      // If link enables AT start, we show "Starts in X"

      if (widget.event.linkEnableTime != null &&
          widget.event.linkEnableTime!.isBefore(widget.event.startTime)) {
        buttonText = "Link active in ${_formatDuration(_timeLeftToLink)}";
      } else {
        buttonText = "Starts in ${_formatDuration(_timeLeftToStart)}";
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.blue.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _isLive
              ? Colors.red.withOpacity(0.5)
              : theme.dividerColor.withOpacity(0.1),
          width: _isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _isLive
                      ? Colors.red.withOpacity(0.1)
                      : theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  _isLive ? Iconsax.video_circle_bold : Iconsax.calendar_1_bold,
                  color: _isLive ? Colors.red : theme.primaryColor,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isLive)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            margin: EdgeInsets.only(right: 8.w),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              "LIVE NOW",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.event.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.disabledColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      DateFormat(
                        'MMM d, y • h:mm a',
                      ).format(widget.event.startTime),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLinkEnabled ? widget.onJoin : null,
              icon: Icon(
                isLinkEnabled ? Iconsax.link_2_outline : Iconsax.clock_outline,
                size: 18,
              ),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLinkEnabled
                    ? (_isLive ? Colors.red : theme.primaryColor)
                    : theme.disabledColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                disabledBackgroundColor: theme.disabledColor.withOpacity(0.3),
                disabledForegroundColor: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
