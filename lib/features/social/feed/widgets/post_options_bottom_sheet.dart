import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/widgets/standard_bottom_sheet.dart';

class PostOptionsBottomSheet extends StatelessWidget {
  final bool isAuthor;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onHide;
  final VoidCallback onShare;
  final VoidCallback onCopyLink;
  final VoidCallback? onFollow;
  final bool isFavorited;
  final VoidCallback onFavorite;
  final VoidCallback? onDownload;
  final bool hasMedia;

  const PostOptionsBottomSheet({
    super.key,
    required this.isAuthor,
    required this.onDelete,
    required this.onReport,
    required this.onHide,
    required this.onShare,
    required this.onCopyLink,
    this.onFollow,
    required this.isFavorited,
    required this.onFavorite,
    this.onDownload,
    this.hasMedia = false,
    this.onEdit,
  });

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StandardBottomSheet(
      title: 'Post Options',
      icon: Icons.more_horiz_rounded,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          _buildOption(
            context: context,
            title: 'Share Post',
            subtitle: 'Share this post with others',
            icon: Iconsax.export_3_outline,
            color: theme.primaryColor,
            onTap: onShare,
          ),
          _buildOption(
            context: context,
            title: 'Copy Link',
            subtitle: 'Copy post link to clipboard',
            icon: Iconsax.link_outline,
            color: Colors.blue,
            onTap: onCopyLink,
          ),
          _buildOption(
            context: context,
            title: isFavorited ? 'Remove from Favourite' : 'Add to Favourite',
            subtitle: isFavorited
                ? 'Remove this post from your list'
                : 'Save this post for later',
            icon: isFavorited
                ? Iconsax.archive_minus_outline
                : Iconsax.archive_add_outline,
            color: Colors.amber,
            onTap: onFavorite,
          ),
          if (hasMedia && onDownload != null)
            _buildOption(
              context: context,
              title: 'Download Post',
              subtitle: 'Save photos & videos to device',
              icon: Iconsax.document_download_outline,
              color: Colors.purple,
              onTap: onDownload!,
            ),
          if (onFollow != null)
            _buildOption(
              context: context,
              title: 'Follow Author',
              subtitle: 'See more posts from this user',
              icon: Iconsax.user_add_outline,
              color: Colors.teal,
              onTap: onFollow!,
            ),
          if (isAuthor) ...[
            if (onEdit != null)
              _buildOption(
                context: context,
                title: 'Edit Post',
                subtitle: 'Update content or correct mistakes',
                icon: Iconsax.edit_outline,
                color: theme.primaryColor,
                onTap: onEdit!,
              ),

            _buildOption(
              context: context,
              title: 'Pin to Profile',
              subtitle: 'Keep this post at the top',
              icon: Iconsax.info_circle_outline,
              color: Colors.indigo,
              onTap: () {}, // Implementation pending
            ),
            _buildOption(
              context: context,
              title: 'Delete Post',
              subtitle: 'Permanently remove this post',
              icon: Iconsax.trash_outline,
              color: Colors.red,
              onTap: onDelete,
            ),
          ] else ...[
            _buildOption(
              context: context,
              title: 'Report Post',
              subtitle: 'Flag inappropriate content',
              icon: Iconsax.flag_outline,
              color: Colors.orange,
              onTap: onReport,
            ),
            _buildOption(
              context: context,
              title: 'Hide Post',
              subtitle: 'See fewer posts like this',
              icon: Iconsax.eye_slash_outline,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              onTap: onHide,
            ),
          ],
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
