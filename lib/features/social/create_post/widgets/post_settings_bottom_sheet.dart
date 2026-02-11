import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/widgets/standard_bottom_sheet.dart';

class PostSettingsBottomSheet extends StatefulWidget {
  final bool commentsDisabled;
  final bool sharingDisabled;
  final bool resharingDisabled;
  final Function(bool, bool, bool) onSettingsChanged;

  const PostSettingsBottomSheet({
    super.key,
    required this.commentsDisabled,
    required this.sharingDisabled,
    required this.resharingDisabled,
    required this.onSettingsChanged,
  });

  @override
  State<PostSettingsBottomSheet> createState() =>
      _PostSettingsBottomSheetState();
}

class _PostSettingsBottomSheetState extends State<PostSettingsBottomSheet> {
  late bool _commentsDisabled;
  late bool _sharingDisabled;
  late bool _resharingDisabled;

  @override
  void initState() {
    super.initState();
    _commentsDisabled = widget.commentsDisabled;
    _sharingDisabled = widget.sharingDisabled;
    _resharingDisabled = widget.resharingDisabled;
  }

  void _notifyChanges() {
    widget.onSettingsChanged(
      _commentsDisabled,
      _sharingDisabled,
      _resharingDisabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StandardBottomSheet(
      title: "Post Settings",
      icon: Iconsax.setting_2_outline,
      isContentScrollable: false, // Small enough to not need scrolling
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          children: [
            _buildSettingTile(
              title: 'Disable Comments',
              subtitle: 'Prevent others from replying to this post',
              icon: Iconsax.messages_3_outline,
              value: _commentsDisabled,
              onChanged: (val) {
                setState(() => _commentsDisabled = val);
                _notifyChanges();
              },
            ),
            _buildSettingTile(
              title: 'Disable Sharing',
              subtitle: 'Prevent others from sharing this post externally',
              icon: Iconsax.export_3_outline,
              value: _sharingDisabled,
              onChanged: (val) {
                setState(() => _sharingDisabled = val);
                _notifyChanges();
              },
            ),
            _buildSettingTile(
              title: 'Disable Resharing',
              subtitle: 'Prevent others from resharing to their profile',
              icon: Iconsax.repeat_outline,
              value: _resharingDisabled,
              onChanged: (val) {
                setState(() => _resharingDisabled = val);
                _notifyChanges();
              },
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.sp),
          decoration: BoxDecoration(
            color: value
                ? theme.primaryColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: value
                ? theme.primaryColor
                : Colors.grey.withValues(alpha: 0.8),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: theme.primaryColor,
          activeTrackColor: theme.primaryColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
