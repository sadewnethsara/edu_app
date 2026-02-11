import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/constants/lk_locations.dart'; // 👈 Make sure this path is correct

class LocationPage extends StatefulWidget {
  final ValueChanged<String?> onProvinceSelected;
  final ValueChanged<String?> onDistrictSelected;
  final ValueChanged<String?> onCitySelected;
  final bool showError;

  // 🚀 --- ADDED INITIAL VALUES --- 🚀
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialCity;
  // 🚀 --- END OF ADDED VALUES --- 🚀

  const LocationPage({
    super.key,
    required this.onProvinceSelected,
    required this.onDistrictSelected,
    required this.onCitySelected,
    required this.showError,
    // 🚀 ADDED TO CONSTRUCTOR
    this.initialProvince,
    this.initialDistrict,
    this.initialCity,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final data = SriLankaLocationData();

  String? _province;
  String? _district;
  String? _city;

  List<String> _districts = [];
  List<String> _cities = [];

  // 🚀 --- UPDATED INITSTATE --- 🚀
  @override
  void initState() {
    super.initState();
    // Pre-fill the form if initial data is provided
    if (widget.initialProvince != null) {
      _province = widget.initialProvince;
      _districts = data.getDistricts(_province!);

      if (widget.initialDistrict != null &&
          _districts.contains(widget.initialDistrict)) {
        _district = widget.initialDistrict;
        _cities = data.getCities(_province!, _district!);

        if (widget.initialCity != null &&
            _cities.contains(widget.initialCity)) {
          _city = widget.initialCity;
        }
      }
    }
  }
  // 🚀 --- END OF UPDATE --- 🚀

  // Resets all location selections
  void _resetSelection() {
    setState(() {
      _province = null;
      _district = null;
      _city = null;
      _districts = [];
      _cities = [];
    });
    // Notify parent widget (AppOnboardingScreen) that values are reset to null
    widget.onProvinceSelected(null);
    widget.onDistrictSelected(null);
    widget.onCitySelected(null);
  }

  // Helper to determine the currently active list
  List<String> _getActiveList(String step) {
    switch (step) {
      case 'Province':
        return data.getProvinces();
      case 'District':
        return _districts;
      case 'City':
        return _cities;
      default:
        return [];
    }
  }

  // Common handler for selection changes
  void _handleSelection(String step, String? value) {
    if (step == 'Province') {
      setState(() {
        _province = value;
        _districts = value != null ? data.getDistricts(value) : [];
        _district = null;
        _city = null;
        _cities = [];
      });
      widget.onProvinceSelected(value);
      widget.onDistrictSelected(null);
      widget.onCitySelected(null);
    } else if (step == 'District') {
      setState(() {
        _district = value;
        _cities = (_province != null && value != null)
            ? data.getCities(_province!, value)
            : [];
        _city = null;
      });
      widget.onDistrictSelected(value);
      widget.onCitySelected(null);
    } else if (step == 'City') {
      setState(() => _city = value);
      widget.onCitySelected(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bool isAnySelectionMade = _province != null;
    final bool isError = widget.showError && _city == null;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Icon and Heading
          Center(
            child: AnimatedEmoji(
              AnimatedEmojis.camping,
              size: 100.sp,
              repeat: false,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "Let's pinpoint your location.",
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),

          // --- Description and Reset Button Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  "We'll find the best curriculum match based on your area.",
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isAnySelectionMade) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  height: 36.h,
                  child: TextButton(
                    onPressed: _resetSelection,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text("RESET"),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 30.h),

          // --- Sequential Location Steps ---
          _buildLocationSelector(
            context,
            'Province',
            _province,
            _getActiveList('Province'),
            (value) => _handleSelection('Province', value),
            isActive: _province == null,
            isError: isError && _province == null,
          ),
          if (_province != null) ...[
            SizedBox(height: 16.h),
            _buildLocationSelector(
              context,
              'District',
              _district,
              _getActiveList('District'),
              (value) => _handleSelection('District', value),
              isActive: _province != null && _district == null,
              isError: isError && _district == null,
            ),
          ],
          if (_district != null) ...[
            SizedBox(height: 16.h),
            _buildLocationSelector(
              context,
              'City',
              _city,
              _getActiveList('City'),
              (value) => _handleSelection('City', value),
              isActive: _district != null && _city == null,
              isError: isError && _city == null,
            ),
          ],

          // 4. Error Message
          if (isError)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Text(
                "Please select your city to continue.",
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // --- 🎨 UPDATED: Location Selector Widget (Handles Active/Completed State) ---
  Widget _buildLocationSelector(
    BuildContext context,
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    required bool isActive,
    required bool isError,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isCompleted = value != null;

    // 1. Completed State (Match App Language Card Style)
    if (isCompleted) {
      Color tileBorderColor = colorScheme.primary;
      double borderWidth = 3.w;
      List<BoxShadow> tileShadow = [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.3),
          blurRadius: 6.r,
          offset: Offset(0, 3.h),
        ),
      ];

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          border: Border.all(color: tileBorderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: tileShadow,
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 30.sp,
                key: const ValueKey('checked'),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Active Selection State (Chips/Tiles)
    if (isActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select $label:",
            style: textTheme.titleLarge?.copyWith(
              color: isError ? colorScheme.error : colorScheme.onSurface,
              fontWeight: isError ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            children: items.map((e) {
              return _buildLocationChip(
                label: e,
                onSelect: () => onChanged(e),
                isError: isError,
              );
            }).toList(),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // --- Chip Builder Method ---
  Widget _buildLocationChip({
    required String label,
    required VoidCallback onSelect,
    required bool isError,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(25.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: isError
                ? colorScheme.error
                : colorScheme.outline.withValues(alpha: 0.5),
            width: isError ? 3.w : 2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isError
                  ? colorScheme.error.withValues(alpha: 0.2)
                  : colorScheme.shadow.withValues(alpha: 0.1),
              offset: Offset(0, 2.h),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: textTheme.bodyLarge?.copyWith(
            color: isError ? colorScheme.error : colorScheme.onSurface,
            fontWeight: isError ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
