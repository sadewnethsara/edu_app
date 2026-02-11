import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:math/core/models/content_model.dart'; // Make sure this is imported
import 'package:shared_preferences/shared_preferences.dart';

/// A data class to hold all info needed to resume
class ContinueLearningData {
  final String gradeId;
  final String subjectId;
  final String lessonId;
  final String? subtopicId;
  final ContentItem item;
  final List<ContentItem> contextList;
  final String contentType;
  final String parentName; // e.g., "Lesson 1: Algebra"
  final String routePath; // e.g., "/video-player"
  final int startIndex;

  ContinueLearningData({
    required this.gradeId,
    required this.subjectId,
    required this.lessonId,
    this.subtopicId,
    required this.item,
    required this.contextList,
    required this.contentType,
    required this.parentName,
    required this.routePath,
    required this.startIndex,
  });

  Map<String, dynamic> toJson() => {
    'gradeId': gradeId,
    'subjectId': subjectId,
    'lessonId': lessonId,
    'subtopicId': subtopicId,
    'item': item.toJson(), // Assumes ContentItem has toJson
    'contextList': contextList.map((i) => i.toJson()).toList(),
    'contentType': contentType,
    'parentName': parentName,
    'routePath': routePath,
    'startIndex': startIndex,
  };

  factory ContinueLearningData.fromJson(Map<String, dynamic> json) {
    var items = (json['contextList'] as List)
        .map((i) => ContentItem.fromJson(i as Map<String, dynamic>))
        .toList();

    return ContinueLearningData(
      gradeId: json['gradeId'],
      subjectId: json['subjectId'],
      lessonId: json['lessonId'],
      subtopicId: json['subtopicId'],
      item: ContentItem.fromJson(json['item'] as Map<String, dynamic>),
      contextList: items,
      contentType: json['contentType'],
      parentName: json['parentName'] ?? 'Continue learning',
      routePath: json['routePath'],
      startIndex: json['startIndex'],
    );
  }
}

class ContinueLearningService extends ChangeNotifier {
  static const _key = 'lastViewedContent';
  ContinueLearningData? _lastViewedData;

  ContinueLearningData? get lastViewedData => _lastViewedData;

  // Call this in main.dart
  Future<void> initialize() async {
    await _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      try {
        _lastViewedData = ContinueLearningData.fromJson(
          json.decode(jsonString),
        );
      } catch (e) {
        // Data format might be old/corrupt, clear it
        await prefs.remove(_key);
        _lastViewedData = null;
      }
    } else {
      _lastViewedData = null;
    }
    notifyListeners();
  }

  Future<void> setLastViewedItem(ContinueLearningData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(data.toJson());
    await prefs.setString(_key, jsonString);
    _lastViewedData = data;
    notifyListeners();
  }

  Future<void> clearLastViewedItem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _lastViewedData = null;
    notifyListeners();
  }
}
