import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MediaQuality { standard, high }

class SettingsService with ChangeNotifier {
  static const String _mediaUploadQualityKey = 'media_upload_quality';
  static const String _mediaDownloadQualityKey = 'media_download_quality';

  late SharedPreferences _prefs;

  MediaQuality _uploadQuality = MediaQuality.standard;
  MediaQuality _downloadQuality = MediaQuality.standard;

  MediaQuality get uploadQuality => _uploadQuality;
  MediaQuality get downloadQuality => _downloadQuality;

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    final uploadIndex =
        _prefs.getInt(_mediaUploadQualityKey) ?? 0; // Default Standard
    final downloadIndex = _prefs.getInt(_mediaDownloadQualityKey) ?? 0;

    _uploadQuality = MediaQuality.values[uploadIndex];
    _downloadQuality = MediaQuality.values[downloadIndex];
    notifyListeners();
  }

  Future<void> setUploadQuality(MediaQuality quality) async {
    _uploadQuality = quality;
    await _prefs.setInt(_mediaUploadQualityKey, quality.index);
    notifyListeners();
  }

  Future<void> setDownloadQuality(MediaQuality quality) async {
    _downloadQuality = quality;
    await _prefs.setInt(_mediaDownloadQualityKey, quality.index);
    notifyListeners();
  }
}
