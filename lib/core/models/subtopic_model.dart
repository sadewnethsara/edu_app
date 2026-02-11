import 'package:math/core/models/lesson_model.dart';

/// Subtopic model within a lesson
class SubtopicModel {
  final String id;
  final String lessonId;
  final String subjectId;
  final String gradeId;
  final int order;
  final String name;
  final String description;
  final ContentCounts? contentCounts;
  final String language; // <-- ADDED
  final bool isActive;

  SubtopicModel({
    required this.id,
    required this.lessonId,
    required this.subjectId,
    required this.gradeId,
    required this.order,
    required this.name,
    required this.description,
    this.contentCounts,
    required this.language, // <-- ADDED
    required this.isActive,
  });

  factory SubtopicModel.fromJson(Map<String, dynamic> json) {
    return SubtopicModel(
      // ✅ UPDATED: Safe parsing, prevents crashes from null data
      id: json['id']?.toString() ?? '',
      lessonId: json['lessonId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      gradeId: json['gradeId']?.toString() ?? '',
      order: json['order'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Untitled Subtopic',
      description: json['description']?.toString() ?? '',
      contentCounts: json['contentCounts'] != null
          ? ContentCounts.fromJson(
              json['contentCounts'] as Map<String, dynamic>,
            )
          : null,
      // ✅ ADDED: Assumes 'en' as default if not specified
      language: json['language']?.toString() ?? 'en',
      // ✅ FIXED: Handle both bool and bool? from Firestore
      isActive: (json['isActive'] == true || json['isActive'] == null)
          ? true
          : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'subjectId': subjectId,
      'gradeId': gradeId,
      'order': order,
      'name': name,
      'description': description,
      // ✅ UPDATED: Simpler and correct, assumes ContentCounts has toJson()
      if (contentCounts != null) 'contentCounts': contentCounts!.toJson(),
      'language': language, // <-- ADDED
      'isActive': isActive,
    };
  }
}
