import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

// Enum to make the status easy to read
enum NetworkStatus { online, offline }

class NetworkService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  NetworkStatus _status = NetworkStatus.online;
  NetworkStatus get status => _status;

  bool _justCameOnline = false;
  bool get justCameOnline => _justCameOnline;

  /// Call this once when the app starts
  Future<void> initialize() async {
    // Get initial status
    final initialResult = await _connectivity.checkConnectivity();
    _updateStatus(initialResult);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Check if the list contains 'none'
    final newStatus = (results.contains(ConnectivityResult.none))
        ? NetworkStatus.offline
        : NetworkStatus.online;

    if (_status == NetworkStatus.offline && newStatus == NetworkStatus.online) {
      // We just came back online
      _justCameOnline = true;
    }

    _status = newStatus;
    notifyListeners();

    // If we just came online, reset the flag after a short delay
    if (_justCameOnline) {
      Future.delayed(const Duration(seconds: 4), () {
        _justCameOnline = false;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
