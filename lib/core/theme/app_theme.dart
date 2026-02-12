import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  static const Color _primaryYellow = Color(0xFFFFD300); // Logo Yellow
  static const Color _secondaryBlue = Color(
    0xFF0B1C2C,
  ); // Deep Navy (Legacy/Light Accents)
  static const Color _white = Colors.white;

  static const Color _lightPrimaryTeal = Color(0xFF06B6D4); // Cyan/Teal
  static const Color _lightSecondaryPurple = Color(0xFF8B5CF6); // Soft Purple
  static const Color _lightSurface = Color(0xFFF8FAFC); // Soft White/Gray
  static const Color _lightTextPrimary = Color(0xFF0F172A); // Slate 900

  static const Color _black = Color(0xFF000000); // Pure Black
  static const Color _darkDivider = Color(0xFF2F3336); // Subtle separator
  static const Color _darkTextPrimary = Color(
    0xFFE7E9EA,
  ); // High emphasis white
  static const Color _darkTextSecondary = Color(0xFF71767B); // Muted grey

  static const String _defaultFont = 'Poppins';

  static const String _sinhalaFont = 'IskoolaPota';

  static const SystemUiOverlayStyle _lightSystemUI = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Top bar background is transparent
    statusBarIconBrightness: Brightness.dark, // Icons (time, battery) are dark
    systemNavigationBarColor: Colors.white, // Bottom Nav bar is white
    systemNavigationBarIconBrightness: Brightness.dark, // Bottom icons are dark
  );

  static const SystemUiOverlayStyle _darkSystemUI = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _black, // Bottom Nav bar is black
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static TextTheme _buildTextTheme(Color color, {Color? secondaryColor}) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w900,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w800,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      titleSmall: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      bodyLarge: TextStyle(fontSize: 16.sp, color: color, height: 1.5),
      bodyMedium: TextStyle(
        fontSize: 14.sp,
        color: secondaryColor ?? color.withValues(alpha: 0.7),
      ),
      bodySmall: TextStyle(
        fontSize: 12.sp,
        color: secondaryColor ?? color.withValues(alpha: 0.5),
      ),
      labelLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  static final _buttonStyle = FilledButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 16.h),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    elevation: 0, // Flat for modern look
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: _lightPrimaryTeal,
      scaffoldBackgroundColor: _lightSurface,

      fontFamily: _defaultFont, // 3. Set default font
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightPrimaryTeal,
        brightness: Brightness.light,
        primary: _lightPrimaryTeal,
        onPrimary: Colors.white,
        secondary: _lightSecondaryPurple,
        surface: Colors.white,
      ),

      dividerColor: Colors.grey.shade200,

      textTheme: _buildTextTheme(_lightTextPrimary).apply(
        fontFamilyFallback: [_sinhalaFont], // 4. Apply fallback
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: _lightSurface,
        foregroundColor: _lightTextPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _lightPrimaryTeal.withValues(alpha: 0.3),
            width: 1.5, // Slightly thicker for visibility
          ),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: _lightPrimaryTeal, width: 1),
          ),
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
      iconTheme: IconThemeData(color: _lightPrimaryTeal),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _primaryYellow,
      scaffoldBackgroundColor: _black,

      fontFamily: _defaultFont, // 3. Set default font
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryYellow,
        brightness: Brightness.dark,
        primary: _primaryYellow,
        onPrimary: _black,
        secondary: _white,
        surface: _black, // Pure black surface
        surfaceContainer: _black,
        onSurface: _darkTextPrimary,
      ),

      dividerTheme: DividerThemeData(color: _darkDivider, thickness: 0.5),
      dividerColor: _darkDivider,

      textTheme:
          _buildTextTheme(
            _darkTextPrimary,
            secondaryColor: _darkTextSecondary,
          ).apply(
            fontFamilyFallback: [_sinhalaFont], // 4. Apply fallback
          ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _black,
        foregroundColor: _darkTextPrimary,
        surfaceTintColor: Colors.transparent,
      ),

      iconTheme: IconThemeData(color: _darkTextPrimary),

      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkTextPrimary,
          side: BorderSide(color: _darkDivider, width: 1),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _white, // High contrast white button in dark mode
          foregroundColor: _black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: _black,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _black,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: _black,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _black,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: _black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _darkDivider, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static SystemUiOverlayStyle getSystemUIStyle(ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      return _darkSystemUI;
    }
    return _lightSystemUI;
  }
}
