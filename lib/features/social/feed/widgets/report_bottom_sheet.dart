import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/widgets/standard_bottom_sheet.dart';

class ReportBottomSheet extends StatefulWidget {
  final String postId;
  final Function(String, String) onReportSubmitted;

  const ReportBottomSheet({
    super.key,
    required this.postId,
    required this.onReportSubmitted,
  });

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final List<String> _reasons = [
    'Spam',
    'Inappropriate Content',
    'Harassment',
    'False Information',
    'Copyright Violation',
    'Other',
  ];

  String? _selectedReason;
  late TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StandardBottomSheet(
      title: "Report Post",
      icon: Icons.report_problem_outlined,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a reason for reporting',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 12.h),
          ..._reasons.map((reason) => _buildReasonTile(reason, colorScheme)),
          SizedBox(height: 20.h),
          Text(
            'Additional details (optional)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Provide more information...',
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReason == null
                  ? null
                  : () {
                      widget.onReportSubmitted(
                        _selectedReason!,
                        _detailsController.text,
                      );
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
                disabledBackgroundColor: theme.primaryColor.withValues(
                  alpha: 0.3,
                ),
              ),
              child: Text(
                'Submit Report',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String reason, ColorScheme colorScheme) {
    final isSelected = _selectedReason == reason;
    return InkWell(
      onTap: () => setState(() => _selectedReason = reason),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? colorScheme.primary : Colors.grey,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              reason,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
