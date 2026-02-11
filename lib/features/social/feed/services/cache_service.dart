import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/services/logger_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String boxName = 'post_cache';
  static const String settingsBox = 'cache_settings';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
    await Hive.openBox(settingsBox);
  }

  Future<void> setKeepDuration(int days) async {
    final box = Hive.box(settingsBox);
    await box.put('keepDuration', days);
  }

  int getKeepDuration() {
    if (!Hive.isBoxOpen(settingsBox)) return 3;
    return Hive.box(settingsBox).get('keepDuration', defaultValue: 3);
  }

  Future<void> cachePost(PostModel post, List<String> localPaths) async {
    final box = Hive.box(boxName);
    await box.put(post.postId, {
      'data': post.toJson(),
      'localPaths': localPaths,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic>? getCachedPost(String postId) {
    if (!Hive.isBoxOpen(boxName)) return null;
    final data = Hive.box(boxName).get(postId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> clearOldCache() async {
    if (!Hive.isBoxOpen(boxName)) return;
    final box = Hive.box(boxName);
    final now = DateTime.now();
    final keysToDelete = [];
    final keepDays = getKeepDuration();

    // 0 means keep forever
    if (keepDays == 0) return;

    for (var key in box.keys) {
      final entry = Map<String, dynamic>.from(box.get(key));
      final cachedAt = DateTime.parse(entry['cachedAt']);
      if (now.difference(cachedAt).inDays >= keepDays) {
        // Delete files
        final localPaths = List<String>.from(entry['localPaths']);
        for (var path in localPaths) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        keysToDelete.add(key);
      }
    }

    for (var key in keysToDelete) {
      await box.delete(key);
    }
  }

  Future<void> clearAllCache() async {
    if (!Hive.isBoxOpen(boxName)) return;
    final box = Hive.box(boxName);
    for (var key in box.keys) {
      final entry = Map<String, dynamic>.from(box.get(key));
      final localPaths = List<String>.from(entry['localPaths']);
      for (var path in localPaths) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await box.clear();
  }

  Future<double> getCacheSize() async {
    final dir = await getApplicationDocumentssocialCacheDirectory();
    final socialDir = Directory(dir);
    if (!await socialDir.exists()) return 0;

    int totalSize = 0;
    try {
      await for (var entity in socialDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      logger.e('Error calculating cache size', error: e);
    }
    return totalSize / (1024 * 1024); // MB
  }

  Future<String> getApplicationDocumentssocialCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final path = '${appDir.path}/social_cache';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }
}
