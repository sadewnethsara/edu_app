/// Content counts for a lesson
class ContentCounts {
  final int videos;
  final int notes;
  final int contentPdfs;
  final int resources;

  ContentCounts({
    required this.videos,
    required this.notes,
    required this.contentPdfs,
    required this.resources,
  });

  factory ContentCounts.fromJson(Map<String, dynamic> json) {
    return ContentCounts(
      videos: json['videos'] as int? ?? 0,
      notes: json['notes'] as int? ?? 0,
      contentPdfs: json['contentPdfs'] as int? ?? 0,
      resources: json['resources'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videos': videos,
      'notes': notes,
      'contentPdfs': contentPdfs,
      'resources': resources,
    };
  }

  int get total => videos + notes + contentPdfs + resources;
}

/// Lesson model within a subject
class LessonModel {
  final String id;
  final String subjectId;
  final String gradeId;
  final int order;
  final String name;
  final String description;
  final ContentCounts? contentCounts;
  final String? language;
  final bool isActive;

  LessonModel({
    required this.id,
    required this.subjectId,
    required this.gradeId,
    required this.order,
    required this.name,
    required this.description,
    this.contentCounts,
    this.language,
    required this.isActive,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      gradeId: json['gradeId'] as String,
      order: json['order'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      contentCounts: json['contentCounts'] != null
          ? ContentCounts.fromJson(
              json['contentCounts'] as Map<String, dynamic>,
            )
          : null,
      language: json['language'] as String?,
      // ✅ FIXED: Handle both bool and bool? from Firestore
      isActive: (json['isActive'] == true || json['isActive'] == null)
          ? true
          : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'gradeId': gradeId,
      'order': order,
      'name': name,
      'description': description,
      if (contentCounts != null)
        'contentCounts': {
          'videos': contentCounts!.videos,
          'notes': contentCounts!.notes,
          'contentPdfs': contentCounts!.contentPdfs,
          'resources': contentCounts!.resources,
        },
      if (language != null) 'language': language,
      'isActive': isActive,
    };
  }
}
