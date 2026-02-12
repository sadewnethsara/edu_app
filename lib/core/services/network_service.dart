import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

enum NetworkStatus { online, offline }

class NetworkService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  NetworkStatus _status = NetworkStatus.online;
  NetworkStatus get status => _status;

  bool _justCameOnline = false;
  bool get justCameOnline => _justCameOnline;

  Future<void> initialize() async {
    final initialResult = await _connectivity.checkConnectivity();
    _updateStatus(initialResult);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final newStatus = (results.contains(ConnectivityResult.none))
        ? NetworkStatus.offline
        : NetworkStatus.online;

    if (_status == NetworkStatus.offline && newStatus == NetworkStatus.online) {
      _justCameOnline = true;
    }

    _status = newStatus;
    notifyListeners();

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
