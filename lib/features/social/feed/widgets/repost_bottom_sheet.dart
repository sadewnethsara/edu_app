import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/features/social/feed/models/post_model.dart';
import 'package:math/widgets/standard_bottom_sheet.dart';

class RepostBottomSheet extends StatefulWidget {
  final PostModel post;
  final Function(String?) onRepost;

  const RepostBottomSheet({
    super.key,
    required this.post,
    required this.onRepost,
  });

  @override
  State<RepostBottomSheet> createState() => _RepostBottomSheetState();
}

class _RepostBottomSheetState extends State<RepostBottomSheet> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StandardBottomSheet(
      title: "Repost",
      icon: Icons.repeat_rounded,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote Input
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a comment (optional)...',
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),

          SizedBox(height: 12.h),

          // Post Preview
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12.r,
                      backgroundImage: widget.post.authorPhotoUrl != null
                          ? CachedNetworkImageProvider(
                              widget.post.authorPhotoUrl!,
                            )
                          : null,
                      child: widget.post.authorPhotoUrl == null
                          ? Icon(Icons.person, size: 14.sp)
                          : null,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      widget.post.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  widget.post.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Action Row
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onRepost(
                      _textController.text.isEmpty
                          ? null
                          : _textController.text,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Repost',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}
