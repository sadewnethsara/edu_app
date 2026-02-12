import 'package:cloud_firestore/cloud_firestore.dart';

enum ReplyPermission { everyone, following, mentioned }

enum PostStatus { approved, pending, rejected, draft }

enum PostCategory { question, discussion, resource, achievement, general }

class PollData {
  final List<String> options;
  final List<int> voteCounts;
  final int totalVotes;
  final int lengthDays;
  final Timestamp endsAt;
  final bool allowMultipleVotes;

  PollData({
    required this.options,
    this.voteCounts = const [],
    this.totalVotes = 0,
    required this.lengthDays,
    required this.endsAt,
    this.allowMultipleVotes = false,
  });

  Map<String, dynamic> toJson() => {
    'options': options,
    'voteCounts': voteCounts,
    'totalVotes': totalVotes,
    'lengthDays': lengthDays,
    'endsAt': endsAt,
    'allowMultipleVotes': allowMultipleVotes,
  };

  factory PollData.fromJson(Map<String, dynamic> json) {
    return PollData(
      options: List<String>.from(json['options'] ?? []),
      voteCounts: List<int>.from(json['voteCounts'] ?? []),
      totalVotes: json['totalVotes'] as int? ?? 0,
      lengthDays: json['lengthDays'] as int? ?? 1,
      endsAt: json['endsAt'] as Timestamp? ?? Timestamp.now(),
      allowMultipleVotes: json['allowMultipleVotes'] as bool? ?? false,
    );
  }
}

class PostModel {
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final String? imageUrl;
  final List<String> imageUrls;
  final Timestamp createdAt;
  final int likeCount;
  final int replyCount;
  final int reShareCount;
  final int viewCount;
  final int shareCount;
  final ReplyPermission replyPermission;
  final PollData? pollData;
  final Timestamp? expiresAt;
  final bool commentsDisabled;
  final bool sharingDisabled;
  final bool resharingDisabled;
  final String? videoUrl;
  final String? linkUrl;
  final List<String> mentions;
  final List<String> mentionedNames;

  final String? originalPostId;
  final PostModel? originalPost;

  final String? gradeId;
  final String? medium;

  final String? subjectId;
  final String? subjectName;
  final List<String> tags;
  final PostCategory category;
  final int helpfulAnswerCount;
  final String? helpfulAnswerId;

  final String? communityId;
  final String? communityName;
  final String? communityIcon;
  final PostStatus status;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    this.imageUrl,
    this.imageUrls = const [],
    required this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.reShareCount = 0,
    this.viewCount = 0,
    this.shareCount = 0,
    this.replyPermission = ReplyPermission.everyone,
    this.pollData,
    this.expiresAt,
    this.gradeId,
    this.medium,
    this.originalPostId,
    this.originalPost,
    this.subjectId,
    this.subjectName,
    this.tags = const [],
    this.category = PostCategory.general,
    this.helpfulAnswerCount = 0,
    this.helpfulAnswerId,
    this.commentsDisabled = false,
    this.sharingDisabled = false,
    this.resharingDisabled = false,
    this.communityId,
    this.communityName,
    this.communityIcon,
    this.status = PostStatus.approved,
    this.videoUrl,
    this.linkUrl,
    this.mentions = const [],
    this.mentionedNames = const [],
  });

  static ReplyPermission _replyPermissionFromString(String? value) {
    switch (value) {
      case 'following':
        return ReplyPermission.following;
      case 'mentioned':
        return ReplyPermission.mentioned;
      default:
        return ReplyPermission.everyone;
    }
  }

  String _replyPermissionToString() {
    return replyPermission.name;
  }

  static PostCategory _categoryFromString(String? value) {
    switch (value) {
      case 'question':
        return PostCategory.question;
      case 'discussion':
        return PostCategory.discussion;
      case 'resource':
        return PostCategory.resource;
      case 'achievement':
        return PostCategory.achievement;
      default:
        return PostCategory.general;
    }
  }

  String _categoryToString() {
    return category.name;
  }

  bool get isReShare => originalPostId != null;

  PostModel copyWith({
    String? postId,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? text,
    String? imageUrl,
    List<String>? imageUrls,
    Timestamp? createdAt,
    int? likeCount,
    int? replyCount,
    int? reShareCount,
    int? viewCount,
    int? shareCount,
    ReplyPermission? replyPermission,
    PollData? pollData,
    Timestamp? expiresAt,
    bool? commentsDisabled,
    bool? sharingDisabled,
    bool? resharingDisabled,
    String? originalPostId,
    PostModel? originalPost,
    String? gradeId,
    String? medium,
    String? subjectId,
    String? subjectName,
    List<String>? tags,
    PostCategory? category,
    int? helpfulAnswerCount,
    String? helpfulAnswerId,
    String? communityId,
    String? communityName,
    String? communityIcon,
    PostStatus? status,
    String? videoUrl,
    String? linkUrl,
    List<String>? mentions,
    List<String>? mentionedNames,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      reShareCount: reShareCount ?? this.reShareCount,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
      replyPermission: replyPermission ?? this.replyPermission,
      pollData: pollData ?? this.pollData,
      expiresAt: expiresAt ?? this.expiresAt,
      commentsDisabled: commentsDisabled ?? this.commentsDisabled,
      sharingDisabled: sharingDisabled ?? this.sharingDisabled,
      resharingDisabled: resharingDisabled ?? this.resharingDisabled,
      originalPostId: originalPostId ?? this.originalPostId,
      originalPost: originalPost ?? this.originalPost,
      gradeId: gradeId ?? this.gradeId,
      medium: medium ?? this.medium,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      helpfulAnswerCount: helpfulAnswerCount ?? this.helpfulAnswerCount,
      helpfulAnswerId: helpfulAnswerId ?? this.helpfulAnswerId,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      communityIcon: communityIcon ?? this.communityIcon,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      mentions: mentions ?? this.mentions,
      mentionedNames: mentionedNames ?? this.mentionedNames,
    );
  }

  factory PostModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<String> images = [];
    if (data['imageUrls'] != null) {
      images = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null) {
      images = [data['imageUrl']];
    }

    return PostModel(
      postId: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown User',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      imageUrls: images,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      likeCount: data['likeCount'] as int? ?? 0,
      replyCount: data['replyCount'] as int? ?? 0,
      reShareCount: data['reShareCount'] as int? ?? 0,
      viewCount: data['viewCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      replyPermission: _replyPermissionFromString(
        data['replyPermission'] as String?,
      ),
      pollData: data['pollData'] != null
          ? PollData.fromJson(data['pollData'] as Map<String, dynamic>)
          : null,
      expiresAt: data['expiresAt'] as Timestamp?,
      gradeId: data['gradeId'] as String?,
      medium: data['medium'] as String?,
      originalPostId: data['originalPostId'] as String?,
      originalPost: data['originalPost'] != null
          ? PostModel.fromJson(data['originalPost'] as Map<String, dynamic>)
          : null,
      subjectId: data['subjectId'] as String?,
      subjectName: data['subjectName'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      category: _categoryFromString(data['category'] as String?),
      helpfulAnswerCount: data['helpfulAnswerCount'] as int? ?? 0,
      helpfulAnswerId: data['helpfulAnswerId'] as String?,
      commentsDisabled: data['commentsDisabled'] as bool? ?? false,
      sharingDisabled: data['sharingDisabled'] as bool? ?? false,
      resharingDisabled: data['resharingDisabled'] as bool? ?? false,
      communityId: data['communityId'] as String?,
      communityName: data['communityName'] as String?,
      communityIcon: data['communityIcon'] as String?,
      status: _statusFromString(data['status'] as String?),
      videoUrl: data['videoUrl'] as String?,
      linkUrl: data['linkUrl'] as String?,
      mentions: List<String>.from(data['mentions'] ?? []),
      mentionedNames: List<String>.from(data['mentionedNames'] ?? []),
    );
  }

  static PostStatus _statusFromString(String? value) {
    switch (value) {
      case 'pending':
        return PostStatus.pending;
      case 'rejected':
        return PostStatus.rejected;
      case 'draft':
        return PostStatus.draft;
      default:
        return PostStatus.approved;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'likeCount': likeCount,
      'replyCount': replyCount,
      'reShareCount': reShareCount,
      'viewCount': viewCount,
      'shareCount': shareCount,
      'replyPermission': _replyPermissionToString(),
      'pollData': pollData?.toJson(),
      'expiresAt': expiresAt,
      'gradeId': gradeId,
      'medium': medium,
      'originalPostId': originalPostId,
      'originalPost': originalPost?.toJson(),
      'subjectId': subjectId,
      'subjectName': subjectName,
      'tags': tags,
      'category': _categoryToString(),
      'helpfulAnswerCount': helpfulAnswerCount,
      'helpfulAnswerId': helpfulAnswerId,
      'commentsDisabled': commentsDisabled,
      'sharingDisabled': sharingDisabled,
      'resharingDisabled': resharingDisabled,
      'communityId': communityId,
      'communityName': communityName,
      'communityIcon': communityIcon,
      'status': status.name,
      'videoUrl': videoUrl,
      'linkUrl': linkUrl,
      'mentions': mentions,
      'mentionedNames': mentionedNames,
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['imageUrls'] != null) {
      images = List<String>.from(json['imageUrls']);
    } else if (json['imageUrl'] != null) {
      images = [json['imageUrl']];
    }

    return PostModel(
      postId: json['postId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown User',
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      text: json['text'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      imageUrls: images,
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      likeCount: json['likeCount'] as int? ?? 0,
      replyCount: json['replyCount'] as int? ?? 0,
      reShareCount: json['reShareCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      replyPermission: _replyPermissionFromString(
        json['replyPermission'] as String?,
      ),
      pollData: json['pollData'] != null
          ? PollData.fromJson(json['pollData'] as Map<String, dynamic>)
          : null,
      expiresAt: json['expiresAt'] as Timestamp?,
      gradeId: json['gradeId'] as String?,
      medium: json['medium'] as String?,
      originalPostId: json['originalPostId'] as String?,
      originalPost: json['originalPost'] != null
          ? PostModel.fromJson(json['originalPost'] as Map<String, dynamic>)
          : null,
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      category: _categoryFromString(json['category'] as String?),
      helpfulAnswerCount: json['helpfulAnswerCount'] as int? ?? 0,
      helpfulAnswerId: json['helpfulAnswerId'] as String?,
      commentsDisabled: json['commentsDisabled'] as bool? ?? false,
      sharingDisabled: json['sharingDisabled'] as bool? ?? false,
      resharingDisabled: json['resharingDisabled'] as bool? ?? false,
      communityId: json['communityId'] as String?,
      communityName: json['communityName'] as String?,
      communityIcon: json['communityIcon'] as String?,
      status: _statusFromString(json['status'] as String?),
      videoUrl: json['videoUrl'] as String?,
      linkUrl: json['linkUrl'] as String?,
      mentions: List<String>.from(json['mentions'] ?? []),
      mentionedNames: List<String>.from(json['mentionedNames'] ?? []),
    );
  }
}
