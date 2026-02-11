import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:math/services/logger_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();

  Future<String?> downloadFile(
    String url,
    String fileName, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dirPath = '${appDir.path}/social_cache';
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filePath = '$dirPath/$fileName';

      await _dio.download(url, filePath, onReceiveProgress: onProgress);

      return filePath;
    } catch (e) {
      logger.e('Error downloading file', error: e);
      return null;
    }
  }
}
