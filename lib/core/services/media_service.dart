import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:math/core/services/settings_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  SettingsService get _settings => SettingsService();

  Future<File> compressImage(File file) async {
    try {
      final quality = _settings.uploadQuality;
      final originalSize = await file.length();

      final targetSize = quality == MediaQuality.standard ? 512000 : 1258291;

      if (originalSize <= targetSize) {
        return file; // No compression needed if already small
      }

      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );

      int compressQuality = 90;
      if (originalSize > targetSize * 4) compressQuality = 70;
      if (originalSize > targetSize * 8) compressQuality = 50;

      if (quality == MediaQuality.standard) {
        compressQuality = (compressQuality * 0.8).round();
      }

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: compressQuality.clamp(10, 95),
      );

      if (result == null) return file;
      File compressedFile = File(result.path);

      if (await compressedFile.length() > targetSize &&
          quality == MediaQuality.standard) {
        var result2 = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath, // Overwrite
          quality: (compressQuality * 0.6).round().clamp(10, 90),
          minWidth: 1024, // Resize if too big
          minHeight: 1024,
        );
        if (result2 != null) compressedFile = File(result2.path);
      }

      logger.i(
        'Compressed image: ${originalSize ~/ 1024}KB -> ${await compressedFile.length() ~/ 1024}KB',
      );
      return compressedFile;
    } catch (e) {
      logger.e('Error compressing image', error: e);
      return file; // Return original on failure
    }
  }

  Future<File> compressVideo(File file) async {
    try {
      await VideoCompress.deleteAllCache();

      final quality = _settings.uploadQuality;
      VideoQuality videoQuality = quality == MediaQuality.standard
          ? VideoQuality
                .MediumQuality // 720p usually, or lower specifically?
          : VideoQuality.DefaultQuality; // High/Default

      if (quality == MediaQuality.standard) {
        videoQuality = VideoQuality.MediumQuality;
      } else {
        videoQuality = VideoQuality.Res1920x1080Quality; // High
      }

      logger.i('Compressing video with quality: $videoQuality');

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: videoQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        logger.i('Compressed video: ${info.filesize} bytes');
        return info.file!;
      }

      return file;
    } catch (e) {
      logger.e('Error compressing video', error: e);
      return file;
    }
  }
}
