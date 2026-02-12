import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newFollower,
  postLike,
  postReply,
  achievement,
  adminMessage,
  system,
  grade,
  communityJoin,
  communityMemberJoin,
  communityCreated,
  postPendingApproval,
  postApproved,
  unknown,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;

  final String? senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final String? targetContentId; // postId, commentId, etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.type = NotificationType.system,
    this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.targetContentId,
  });

  factory NotificationModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      type: _parseType(data['type'] ?? 'system'),
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderPhotoUrl: data['senderPhotoUrl'],
      targetContentId: data['targetContentId'],
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'newFollower':
        return NotificationType.newFollower;
      case 'postLike':
        return NotificationType.postLike;
      case 'postReply':
        return NotificationType.postReply;
      case 'achievement':
        return NotificationType.achievement;
      case 'adminMessage':
        return NotificationType.adminMessage;
      case 'grade':
        return NotificationType.grade;
      case 'system':
        return NotificationType.system;
      case 'community_join':
        return NotificationType.communityJoin;
      case 'community_member_join':
        return NotificationType.communityMemberJoin;
      case 'community_created':
        return NotificationType.communityCreated;
      case 'post_pending_approval':
        return NotificationType.postPendingApproval;
      case 'post_approved':
        return NotificationType.postApproved;
      default:
        return NotificationType.unknown;
    }
  }
}

final List<NotificationModel> kDummyNotifications = [
  NotificationModel(
    id: '1',
    title: 'Welcome to Math App!',
    message: 'Start your learning journey today by exploring lessons.',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    type: NotificationType.system,
  ),
  NotificationModel(
    id: '2',
    title: 'Grade Selection Updated',
    message: 'You have successfully updated your grade to Grade 10.',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    type: NotificationType.grade,
  ),
  NotificationModel(
    id: '3',
    title: 'New Lesson Available',
    message: 'Check out the new Geometry lesson added for your grade.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    type: NotificationType.system,
  ),
  NotificationModel(
    id: '4',
    title: 'New Reply',
    message: 'Alice replied: "That is a great solution!"',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    type: NotificationType.postReply,
    senderName: 'Alice Johnson',
    targetContentId: 'post_123',
  ),
  NotificationModel(
    id: '5',
    title: 'New Like',
    message: 'Bob liked your post about Algebra.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    type: NotificationType.postLike,
    senderName: 'Bob Smith',
    targetContentId: 'post_456',
  ),
  NotificationModel(
    id: '6',
    title: 'New Follower',
    message: 'Charlie started following you.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    type: NotificationType.newFollower,
    senderName: 'Charlie Brown',
  ),
];
