import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:math/services/logger_service.dart';

class ZenModeService extends ChangeNotifier {
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  int _focusMinutes = 25;
  int get focusMinutes => _focusMinutes;

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  Timer? _timer;
  bool _isPaused = false;
  bool get isPaused => _isPaused;

  void toggleZenMode() {
    _isEnabled = !_isEnabled;
    if (!_isEnabled) {
      stopSession();
    }
    notifyListeners();
    logger.i('Zen Mode: ${_isEnabled ? "Enabled" : "Disabled"}');
  }

  void startSession(int minutes) {
    _focusMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _isPaused = false;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          stopSession();
          logger.i('Zen Mode Session Completed');
        }
      }
    });
    notifyListeners();
  }

  void pauseSession() {
    _isPaused = true;
    notifyListeners();
  }

  void resumeSession() {
    _isPaused = false;
    notifyListeners();
  }

  void stopSession() {
    _timer?.cancel();
    _timer = null;
    _remainingSeconds = 0;
    _isPaused = false;
    notifyListeners();
  }

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
