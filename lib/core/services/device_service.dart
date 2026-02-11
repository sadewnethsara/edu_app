import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math/core/services/logger_service.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Gets a map of basic, non-sensitive device info
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    Map<String, dynamic> deviceData = {};
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceData = {
          'os': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'isPhysical': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceData = {
          'os': iosInfo.systemName,
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'isPhysical': iosInfo.isPhysicalDevice,
        };
      }
    } catch (e, s) {
      logger.e('Failed to get device info', error: e, stackTrace: s);
    }
    return deviceData;
  }

  /// Saves the device info to the user's Firestore document
  Future<void> saveDeviceInfo(User user) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      if (deviceInfo.isEmpty) return; // Failed to get info

      // We will update the 'users' document with info
      // about the last device that logged in.
      final userDocRef = _firestore.collection('users').doc(user.uid);

      await userDocRef.update({
        'lastDevice': deviceInfo, // This saves the map
        'lastLogin': FieldValue.serverTimestamp(), // Good to update this too
      });

      logger.i('Saved device info for ${user.uid}');
    } catch (e, s) {
      // Don't crash the app if this fails, just log it.
      logger.e(
        'Failed to save device info to Firestore',
        error: e,
        stackTrace: s,
      );
    }
  }
}
