import 'dart:async';
import 'package:flutter/material.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AppUsageService extends ChangeNotifier {
  late SharedPreferences _prefs;
  Timer? _timer;

  int _todayUsageSeconds = 0;
  int _yesterdayUsageSeconds = 0;
  Map<String, int> _weeklyUsage = {}; // { 'YYYY-MM-DD': seconds }

  int get todayUsageSeconds => _todayUsageSeconds;
  int get yesterdayUsageSeconds => _yesterdayUsageSeconds;
  Map<String, int> get weeklyUsage => _weeklyUsage;

  // Formatter for the UI
  String get todayUsageFormatted {
    final duration = Duration(seconds: _todayUsageSeconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  // Getter for comparison
  double get usageComparison {
    if (_yesterdayUsageSeconds == 0) {
      return 1.0; // Assume 100% increase if no data
    }
    return _todayUsageSeconds / _yesterdayUsageSeconds;
  }

  // Call this once on app start
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUsageData();
    _startUsageTimer();
    notifyListeners();
  }

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _loadUsageData() async {
    final todayStr = _getTodayDateString();
    final lastVisitDate = _prefs.getString('lastVisitDate');

    // Load weekly data
    _weeklyUsage = {};
    final keys = _prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('usage_')) {
        final dateStr = key.substring(6); // Remove 'usage_' prefix
        _weeklyUsage[dateStr] = _prefs.getInt(key) ?? 0;
      }
    }

    if (lastVisitDate == todayStr) {
      // Same day
      _todayUsageSeconds = _prefs.getInt('usage_$todayStr') ?? 0;
      final yesterdayStr = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(const Duration(days: 1)));
      _yesterdayUsageSeconds = _prefs.getInt('usage_$yesterdayStr') ?? 0;
    } else {
      // New day
      logger.i('New day detected. Rolling over usage stats.');
      final yesterdayStr = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(const Duration(days: 1)));

      // Yesterday's usage is whatever was last saved as "today"
      _yesterdayUsageSeconds = _prefs.getInt('usage_$lastVisitDate') ?? 0;

      _todayUsageSeconds = 0; // Reset today's usage

      // Save the rollover
      await _prefs.setInt('usage_$yesterdayStr', _yesterdayUsageSeconds);
      await _prefs.setInt('usage_$todayStr', 0);
      await _prefs.setString('lastVisitDate', todayStr);

      // Prune old data (older than 7 days)
      _pruneOldUsageData();
    }
  }

  void _pruneOldUsageData() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    List<String> keysToRemove = [];

    _weeklyUsage.forEach((dateStr, seconds) {
      try {
        final date = DateTime.parse(dateStr);
        if (date.isBefore(sevenDaysAgo)) {
          keysToRemove.add('usage_$dateStr');
        }
      } catch (e) {
        keysToRemove.add('usage_$dateStr'); // Remove invalid keys
      }
    });

    for (String key in keysToRemove) {
      _prefs.remove(key);
      _weeklyUsage.remove(key.substring(6));
    }
  }

  double get usagePercentageChange {
    if (yesterdayUsageSeconds == 0) {
      // If yesterday was 0, any usage today is a 100% increase
      // (or 0% if today is also 0)
      return todayUsageSeconds > 0 ? 100.0 : 0.0;
    }
    if (todayUsageSeconds == 0) {
      // If today is 0 and yesterday was > 0, it's a -100% decrease
      return -100.0;
    }

    // Standard percentage change formula
    double change =
        (todayUsageSeconds - yesterdayUsageSeconds) / yesterdayUsageSeconds;
    return change * 100;
  }

  void _startUsageTimer() {
    // Update usage every 30 seconds
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      incrementUsage(30);
    });
  }

  Future<void> incrementUsage(int seconds) async {
    // Check if it's a new day
    await _loadUsageData();

    _todayUsageSeconds += seconds;
    await _prefs.setInt('usage_${_getTodayDateString()}', _todayUsageSeconds);

    // Update in-memory map as well
    _weeklyUsage[_getTodayDateString()] = _todayUsageSeconds;

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
