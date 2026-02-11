/// Content item model (videos, notes, PDFs, resources)
class ContentItem {
  final String id;
  final String name;
  final String url;
  final String type; // 'upload' or 'url'
  final String? fileName;
  final String? thumbnail;
  final String language;
  final String uploadedAt;
  final String? description;
  final List<String>? tags;

  ContentItem({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.fileName,
    this.thumbnail,
    required this.language,
    required this.uploadedAt,
    this.description,
    this.tags,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      // ✅ UPDATED: Safe parsing with default values
      id: json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['fileName']?.toString() ??
          'Untitled', // Fallback
      url: json['url']?.toString() ?? '',
      type: json['type']?.toString() ?? 'url', // Default to 'url'
      fileName: json['fileName'] as String?,
      thumbnail: json['thumbnail'] as String?,
      language: json['language']?.toString() ?? 'en', // Default to 'en'
      uploadedAt:
          json['uploadedAt']?.toString() ??
          DateTime.now().toIso8601String(), // Fallback
      description: json['description'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      if (fileName != null) 'fileName': fileName,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'language': language,
      'uploadedAt': uploadedAt,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
    };
  }
}

/// Content collection for lessons/subtopics
class ContentCollection {
  final List<ContentItem> videos;
  final List<ContentItem> notes;
  final List<ContentItem> contentPdfs;
  final List<ContentItem> resources;

  ContentCollection({
    required this.videos,
    required this.notes,
    required this.contentPdfs,
    required this.resources,
  });

  factory ContentCollection.fromJson(Map<String, dynamic> json) {
    return ContentCollection(
      // This logic was already correct and safe
      videos: json['videos'] != null
          ? (json['videos'] as List)
                .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      notes: json['notes'] != null
          ? (json['notes'] as List)
                .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      contentPdfs: json['contentPdfs'] != null
          ? (json['contentPdfs'] as List)
                .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      resources: json['resources'] != null
          ? (json['resources'] as List)
                .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  int get totalCount =>
      videos.length + notes.length + contentPdfs.length + resources.length;

  // 🚀 ADDED: Helper for the scroll error fix
  int get allItemCount {
    int count = 0;
    if (videos.isNotEmpty) count++;
    if (notes.isNotEmpty) count++;
    if (contentPdfs.isNotEmpty) count++;
    if (resources.isNotEmpty) count++;
    return count;
  }

  factory ContentCollection.empty() =>
      ContentCollection(videos: [], notes: [], contentPdfs: [], resources: []);

  Map<String, dynamic> toJson() {
    return {
      'videos': videos.map((e) => e.toJson()).toList(),
      'notes': notes.map((e) => e.toJson()).toList(),
      'contentPdfs': contentPdfs.map((e) => e.toJson()).toList(),
      'resources': resources.map((e) => e.toJson()).toList(),
    };
  }
}
