import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show debugPrint, ChangeNotifier;
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:math/services/auth_service.dart';
import 'package:math/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 UPDATED: Enum names for clarity
enum StreakUpdateStatus {
  noChange, // User already opened the app today
  streakKept, // Streak is the same (visited within 7-day grace period)
  streakIncreased, // Streak went up by 1 (visited on a new day)
  streakLost, // Streak was lost (gap > 7 days) and reset to 1
}

class StreakService with ChangeNotifier {
  // --- NATIVE HOME WIDGET KEYS ---
  static const String _widgetGroupId = 'group.com.nethsara.math';
  static const String _widgetStreakKey = 'streak_count';
  static const String _androidWidgetName = 'StreakWidgetProvider';
  static const String _iosWidgetName = 'StreakWidget';

  // --- LOCAL STORAGE KEY ---
  static const String _streakKey = 'streak_count';

  // --- FIREBASE and AUTH ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService? _authService;
  String? get _userID => _authService?.user?.uid;
  bool _isSyncedFromFirebase = false;

  // --- STATE ---
  int _currentStreak = 0;
  List<DateTime> _streakHistory =
      []; // Stores sorted visit dates (newest first)
  bool _streakWasLost = false;
  int _previousStreak = 0; // Stores the old streak if it was lost

  int get currentStreak => _currentStreak;
  List<DateTime> get streakHistory => _streakHistory; // For the graph screen
  bool get streakWasLost => _streakWasLost;
  bool get isSynced => _isSyncedFromFirebase;
  int get previousStreak => _previousStreak;

  /// Called by the ProxyProvider in main.dart to link services
  void updateAuth(AuthService auth) {
    _authService = auth;
    if (auth.status == AuthStatus.authenticated) {
      syncFromFirebase(); // Sync when user is confirmed logged in
    } else {
      // User logged out, clear local state
      _currentStreak = 0;
      _previousStreak = 0;
      _streakHistory = [];
      _isSyncedFromFirebase = false;
      notifyListeners();
    }
  }

  // --- 🚀 HELPER FUNCTIONS (NEW) ---
  String _getDateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  DateTime _parseDateString(String dateStr) => DateTime.parse(dateStr);
  DateTime _getTodayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // --- 🚀 HELPER: SAVE TO LOCAL (WIDGET) ---
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    // Only save the count, as that's all the widget needs
    await prefs.setInt(_streakKey, _currentStreak);
    debugPrint("Streak: Saved to local (for widget).");
  }

  // --- 🚀 HELPER: SAVE TO FIREBASE (MASTER SOURCE) ---
  Future<void> _saveToFirebase() async {
    if (_userID == null) {
      return;
    } // Not logged in

    // Prune history to last 100 visits for performance
    if (_streakHistory.length > 100) {
      _streakHistory = _streakHistory.sublist(0, 100);
    }

    // Save dates as strings
    final stringHistory = _streakHistory
        .map((date) => _getDateString(date))
        .toList();

    final dataToSave = {
      'streak': _currentStreak, // Save the calculated streak
      'streakHistory': stringHistory,
    };

    try {
      await _firestore.collection('users').doc(_userID).set({
        'streakData': dataToSave,
      }, SetOptions(merge: true));
      debugPrint("Streak: Synced to Firebase.");
    } catch (e) {
      debugPrint("Streak: Firebase sync FAILED: $e");
    }
  }

  // --- 🚀 HELPER: LOAD FROM LOCAL (FALLBACK) ---
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt(_streakKey) ?? 0;
    // Note: We don't load history from local, only the count for the widget.
    // The history is only managed by Firebase.
    debugPrint("Streak: Loaded from local (fallback).");
  }

  // --- 🚀 UPDATED: SYNC FROM FIREBASE ---
  /// Loads data from Firebase (if possible) into the service.
  Future<void> syncFromFirebase() async {
    if (_userID == null) {
      debugPrint("Streak: Skipping Firebase sync (no user).");
      return;
    }
    if (_isSyncedFromFirebase) {
      debugPrint("Streak: Skipping Firebase sync (already synced).");
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(_userID).get();
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('streakData')) {
        final data = doc.data()!['streakData'];

        // Load data from Firebase
        _streakHistory = (data['streakHistory'] as List<dynamic>? ?? [])
            .map((dateStr) => _parseDateString(dateStr as String))
            .toList();
        // Sort newest first, just in case
        _streakHistory.sort((a, b) => b.compareTo(a));

        _recalculateStreakFromHistory(); // Calculate streak from this history
        _previousStreak = data['streak'] ?? 0; // Store the last saved streak

        await _saveToLocal(); // Save cloud data to local prefs
        debugPrint("Streak: Synced from Firebase.");
      } else {
        // No data in Firebase, just load from local
        await _loadFromLocal();
      }
    } catch (e) {
      debugPrint("Streak: Firebase read FAILED, loading from local. $e");
      await _loadFromLocal();
    }

    _isSyncedFromFirebase = true;
    notifyListeners();
  }

  // --- 🚀 NEW: RECALCULATE STREAK ---
  /// Calculates the current streak based on the 7-DAY GRACE PERIOD
  void _recalculateStreakFromHistory() {
    if (_streakHistory.isEmpty) {
      _currentStreak = 0;
      return;
    }

    final today = _getTodayDate();

    // Check if the most recent visit was too long ago
    final lastVisit = _streakHistory[0];
    final daysSinceLastVisit = today.difference(lastVisit).inDays;

    if (daysSinceLastVisit > 7) {
      // 🚀 7-DAY RULE: Streak is lost
      _currentStreak = 0;
      return;
    }

    // Calculate streak
    int streak = 1;
    for (int i = 0; i < _streakHistory.length - 1; i++) {
      DateTime currentVisit = _streakHistory[i];
      DateTime previousVisit = _streakHistory[i + 1];

      final diff = currentVisit.difference(previousVisit).inDays;

      if (diff <= 7) {
        // 🚀 7-DAY RULE: Visit is within the grace period, streak continues
        streak++;
      } else {
        // Gap is > 7 days, streak breaks
        break;
      }
    }
    _currentStreak = streak;
  }

  // --- 🚀 UPDATED: APP OPEN LOGIC ---
  /// Checks and updates the streak. Called after syncFromFirebase().
  Future<StreakUpdateStatus> updateStreakOnAppOpen() async {
    // Make sure data is loaded first
    if (!_isSyncedFromFirebase) {
      debugPrint("Streak: Waiting for Firebase sync...");
      await syncFromFirebase();
    }

    final today = _getTodayDate();
    _streakWasLost = false;
    StreakUpdateStatus status = StreakUpdateStatus.noChange;

    // Check if user already opened the app today
    if (_streakHistory.isNotEmpty &&
        _streakHistory[0].isAtSameMomentAs(today)) {
      debugPrint("Streak: User already opened app today.");
      await _updateHomeWidget(); // Still update widget
      return StreakUpdateStatus.noChange;
    }

    // --- This is a new visit for today ---
    int oldStreak = _currentStreak;

    // Check for streak loss before adding today's visit
    if (_streakHistory.isNotEmpty) {
      final lastVisit = _streakHistory[0];
      final daysDifference = today.difference(lastVisit).inDays;

      if (daysDifference > 7) {
        // 🚀 7-DAY RULE: Streak is broken
        logger.i('Streak lost. Last visit was $daysDifference days ago.');
        _previousStreak = oldStreak;
        _streakHistory = [today]; // Reset history to just today
        _currentStreak = 1;
        _streakWasLost = _previousStreak > 0;
        status = StreakUpdateStatus.streakLost;
      } else {
        // Streak is not broken, just add today
        _streakHistory.insert(0, today);
        _recalculateStreakFromHistory(); // Recalculate

        if (_currentStreak > oldStreak) {
          status = StreakUpdateStatus.streakIncreased;
        } else {
          // Visited within grace period, but not consecutive
          status = StreakUpdateStatus.streakKept;
        }
      }
    } else {
      // First time user - start fresh with streak of 1
      _streakHistory = [today];
      _currentStreak = 1;
      _previousStreak = 0;
      _streakWasLost = false; // Don't show "lost" message on first open
      status = StreakUpdateStatus.streakIncreased;
    }

    // --- Save and Update ---
    await _saveToFirebase();
    await _saveToLocal();
    await _updateHomeWidget();

    debugPrint("Streak: Updated. New streak: $_currentStreak");
    notifyListeners();
    return status;
  }

  /// Sends the current streak data to the native home screen widget
  Future<void> _updateHomeWidget() async {
    try {
      await HomeWidget.setAppGroupId(_widgetGroupId);
      await HomeWidget.saveWidgetData<int>(_widgetStreakKey, _currentStreak);
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  // ❌ REMOVED: _getStartOfWeek (no longer needed)
  // ❌ REMOVED: _weekLoginDays logic (replaced by _streakHistory)
  // ❌ REMOVED: _lastLoginKey (replaced by _streakHistory)
}
