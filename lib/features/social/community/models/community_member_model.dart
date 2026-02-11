import 'package:cloud_firestore/cloud_firestore.dart';

enum CommunityRole { member, moderator, admin }

enum MemberStatus { pending, approved, rejected }

class CommunityMemberModel {
  final String userId;
  final String communityId;
  final CommunityRole role;
  final Timestamp joinedAt;
  final MemberStatus status;

  CommunityMemberModel({
    required this.userId,
    required this.communityId,
    this.role = CommunityRole.member,
    required this.joinedAt,
    this.status = MemberStatus.approved,
  });

  factory CommunityMemberModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityMemberModel(
      userId: doc.id,
      communityId: data['communityId'] as String? ?? '',
      role: _roleFromString(data['role'] as String?),
      joinedAt: data['joinedAt'] as Timestamp? ?? Timestamp.now(),
      status: _statusFromString(data['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'role': role.name,
      'joinedAt': joinedAt,
      'status': status.name,
    };
  }

  static MemberStatus _statusFromString(String? status) {
    switch (status) {
      case 'pending':
        return MemberStatus.pending;
      case 'rejected':
        return MemberStatus.rejected;
      default:
        return MemberStatus.approved;
    }
  }

  static CommunityRole _roleFromString(String? role) {
    switch (role) {
      case 'admin':
        return CommunityRole.admin;
      case 'moderator':
        return CommunityRole.moderator;
      default:
        return CommunityRole.member;
    }
  }
}
