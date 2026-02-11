import 'package:flutter/material.dart';

/// Utility class for generating WhatsApp-style pastel avatar colors
class AvatarColorGenerator {
  // WhatsApp-style pastel colors
  static final List<Color> _pastelColors = [
    const Color(0xFFBBDEFB), // Blue 100
    const Color(0xFFE1BEE7), // Purple 100
    const Color(0xFFFFCC80), // Orange 200
    const Color(0xFFA5D6A7), // Green 200
    const Color(0xFFEF9A9A), // Red 200
    const Color(0xFFFFF59D), // Yellow 200
    const Color(0xFFB39DDB), // Deep Purple 200
    const Color(0xFF80CBC4), // Teal 200
    const Color(0xFFFFAB91), // Deep Orange 200
    const Color(0xFFB0BEC5), // Blue Grey 200
    const Color(0xFFF48FB1), // Pink 200
    const Color(0xFFC5E1A5), // Light Green 200
    const Color(0xFFFFE082), // Amber 200
    const Color(0xFF81D4FA), // Light Blue 200
    const Color(0xFFE6EE9C), // Lime 200
  ];

  /// Generate a consistent color based on a string (like user ID or name)
  static Color getColorForUser(String identifier) {
    if (identifier.isEmpty) {
      return _pastelColors[0];
    }

    // Generate a hash from the identifier
    int hash = 0;
    for (int i = 0; i < identifier.length; i++) {
      hash = identifier.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Use absolute value and modulo to get index
    final index = hash.abs() % _pastelColors.length;
    return _pastelColors[index];
  }

  /// Get text color that contrasts well with the background
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();

    // Return dark text for light backgrounds, light text for dark backgrounds
    return luminance > 0.5 ? const Color(0xFF424242) : Colors.white;
  }

  /// Get all available pastel colors
  static List<Color> getAllColors() => List.unmodifiable(_pastelColors);
}
