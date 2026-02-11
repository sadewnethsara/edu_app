/// Past paper model for exams
class PastPaperModel {
  final String id;
  final String gradeId;
  final String subjectId;
  final String year;
  final String? term;
  final String title;
  final String description;
  final String fileUrl; // Main paper URL (replaces paperUrl)
  final String? answerUrl;
  final int? fileSize; // <-- This is an int?
  final String language;
  final String uploadedAt;
  final bool isActive;
  final List<String>? tags;

  PastPaperModel({
    required this.id,
    required this.gradeId,
    required this.subjectId,
    required this.year,
    this.term,
    required this.title,
    required this.description,
    required this.fileUrl,
    this.answerUrl,
    this.fileSize,
    required this.language,
    required this.uploadedAt,
    required this.isActive,
    this.tags,
  });

  factory PastPaperModel.fromJson(Map<String, dynamic> json) {
    // Handle year as both int and string
    final yearValue = json['year'];
    final yearString = yearValue is int
        ? yearValue.toString()
        : (yearValue?.toString() ?? '');

    return PastPaperModel(
      id: json['id']?.toString() ?? '',
      gradeId: json['gradeId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      year: yearString,
      term: json['term']?.toString(),
      title: json['title']?.toString() ?? 'Unknown',
      description: json['description']?.toString() ?? '',
      // Support both fileUrl (new) and paperUrl (legacy)
      fileUrl: (json['fileUrl'] ?? json['paperUrl'])?.toString() ?? '',
      answerUrl: json['answerUrl']?.toString(),

      // ✅ CORRECTED: Use .toInt() to match the int? type
      fileSize: (json['fileSize'] is num
          ? (json['fileSize'] as num).toInt()
          : null),

      language: json['language']?.toString() ?? 'english',
      uploadedAt: json['uploadedAt']?.toString() ?? '',
      // ✅ FIXED: Handle both bool and bool? from Firestore
      isActive: (json['isActive'] == true || json['isActive'] == null)
          ? true
          : false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gradeId': gradeId,
      'subjectId': subjectId,
      'year': year,
      if (term != null) 'term': term,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      if (answerUrl != null) 'answerUrl': answerUrl,
      if (fileSize != null) 'fileSize': fileSize,
      'language': language,
      'uploadedAt': uploadedAt,
      'isActive': isActive,
      if (tags != null) 'tags': tags,
    };
  }

  // Helper getter for backward compatibility
  String get paperUrl => fileUrl;
}
