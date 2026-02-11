import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/data/models/content_model.dart';

/// Card for content items (videos, notes, pdfs, resources)
class ContentItemCard extends StatelessWidget {
  final ContentItem item;
  final IconData icon;
  final Color color;
  final String type;
  final VoidCallback onTap;

  const ContentItemCard({
    super.key,
    required this.item,
    required this.icon,
    required this.color,
    required this.type,
    required this.onTap,
  });

  String? _getThumbnail() {
    if (item.thumbnail != null && item.thumbnail!.isNotEmpty) {
      return item.thumbnail;
    }
    final youtubeRegex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = youtubeRegex.firstMatch(item.url);
    if (match != null) {
      final videoId = match.group(1);
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final thumbnailUrl = _getThumbnail();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Thumbnail / Icon Box
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: thumbnailUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: CachedNetworkImage(
                                imageUrl: thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: color.withValues(alpha: 0.1),
                                ),
                                errorWidget: (context, url, error) =>
                                    Icon(icon, color: color),
                              ),
                            )
                          : Icon(icon, color: color, size: 28.sp),
                    ),
                    if (thumbnailUrl != null)
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16.w),
                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Type Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
