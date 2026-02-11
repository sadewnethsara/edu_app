import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType { feedback, bug, question, other }

class FeedbackModel {
  final String? id;
  final String userId;
  final String? userEmail;
  final String message;
  final FeedbackType type;
  final Timestamp createdAt;
  final String? deviceInfo;
  final String appVersion;

  FeedbackModel({
    this.id,
    required this.userId,
    this.userEmail,
    required this.message,
    required this.type,
    required this.createdAt,
    this.deviceInfo,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'message': message,
      'type': type.name,
      'createdAt': createdAt,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }

  factory FeedbackModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return FeedbackModel(
      id: id,
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'],
      message: json['message'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedbackType.other,
      ),
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      deviceInfo: json['deviceInfo'],
      appVersion: json['appVersion'] ?? 'Unknown',
    );
  }
}
