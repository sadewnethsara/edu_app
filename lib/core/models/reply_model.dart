import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyModel {
  final String replyId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? linkUrl;
  final bool isAnswer;
  final Timestamp createdAt;
  final int likeCount;
  final int helpfulCount;
  final bool isMarkedHelpful;
  final String? parentId;
  final String? replyToUserId;
  final String? replyToUserName;

  ReplyModel({
    required this.replyId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    this.imageUrl,
    this.imageUrls = const [],
    this.videoUrl,
    this.linkUrl,
    this.isAnswer = false,
    required this.createdAt,
    this.likeCount = 0,
    this.helpfulCount = 0,
    this.isMarkedHelpful = false,
    this.parentId,
    this.replyToUserId,
    this.replyToUserName,
  });

  factory ReplyModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<String> images = [];
    if (data['imageUrls'] != null) {
      images = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null) {
      images = [data['imageUrl']];
    }

    return ReplyModel(
      replyId: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown User',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      imageUrls: images,
      videoUrl: data['videoUrl'] as String?,
      linkUrl: data['linkUrl'] as String?,
      isAnswer: data['isAnswer'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      likeCount: data['likeCount'] as int? ?? 0,
      helpfulCount: data['helpfulCount'] as int? ?? 0,
      isMarkedHelpful: data['isMarkedHelpful'] as bool? ?? false,
      parentId: data['parentId'] as String?,
      replyToUserId: data['replyToUserId'] as String?,
      replyToUserName: data['replyToUserName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'linkUrl': linkUrl,
      'isAnswer': isAnswer,
      'createdAt': createdAt,
      'likeCount': likeCount,
      'helpfulCount': helpfulCount,
      'isMarkedHelpful': isMarkedHelpful,
      'parentId': parentId,
      'replyToUserId': replyToUserId,
      'replyToUserName': replyToUserName,
    };
  }
}
