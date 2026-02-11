import 'package:flutter/material.dart';

/// Defines a single achievement level
class Achievement {
  final String name;
  final String description;
  final int level;
  final int threshold; // The goal to reach this level (e.g., 500 points)
  final IconData icon;

  Achievement({
    required this.name,
    required this.description,
    required this.level,
    required this.threshold,
    required this.icon,
  });
}

/// Static helper class to hold all achievement data.
/// The [key] (e.g., 'points') MUST match the key in the user's Firestore document.
class AchievementsData {
  static final Map<String, List<Achievement>> allAchievements = {
    'points': [
      Achievement(
        level: 1,
        name: 'Novice',
        description: 'Earn 100 points',
        threshold: 100,
        icon: Icons.star_border_rounded,
      ),
      Achievement(
        level: 2,
        name: 'Apprentice',
        description: 'Earn 500 points',
        threshold: 500,
        icon: Icons.star_half_rounded,
      ),
      Achievement(
        level: 3,
        name: 'Scholar',
        description: 'Earn 2,000 points',
        threshold: 2000,
        icon: Icons.star_rounded,
      ),
      Achievement(
        level: 4,
        name: 'Guru',
        description: 'Earn 10,000 points',
        threshold: 10000,
        icon: Icons.stars_rounded,
      ),
    ],
    'streak': [
      Achievement(
        level: 1,
        name: 'Warm Up',
        description: 'Hold a 3-day streak',
        threshold: 3,
        icon: Icons.whatshot_outlined,
      ),
      Achievement(
        level: 2,
        name: 'On Fire',
        description: 'Hold a 7-day streak',
        threshold: 7,
        icon: Icons.local_fire_department_rounded,
      ),
      Achievement(
        level: 3,
        name: 'Inferno',
        description: 'Hold a 30-day streak',
        threshold: 30,
        icon: Icons.compost_rounded,
      ),
    ],
    'lessons': [
      Achievement(
        level: 1,
        name: 'Bookworm',
        description: 'Complete 10 lessons',
        threshold: 10,
        icon: Icons.auto_stories_outlined,
      ),
      Achievement(
        level: 2,
        name: 'Scholar',
        description: 'Complete 50 lessons',
        threshold: 50,
        icon: Icons.auto_stories_rounded,
      ),
    ],
  };

  /// Helper to get the achievement data for a specific level
  static Achievement? getAchievement(String type, int level) {
    if (level <= 0) return null;
    final levels = allAchievements[type];
    if (levels == null || level > levels.length) return null;
    return levels[level - 1]; // level 1 is at index 0
  }

  /// Helper to get the NEXT achievement level
  static Achievement? getNextAchievement(String type, int level) {
    final levels = allAchievements[type];
    if (levels == null || level >= levels.length) return null; // No next level
    return levels[level]; // level 1's next level is at index 1
  }
}
