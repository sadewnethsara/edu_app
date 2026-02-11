import 'package:cloud_firestore/cloud_firestore.dart';

enum ResourceType { video, document, link }

class CommunityResourceModel {
  final String id;
  final String communityId;
  final String title;
  final String description;
  final ResourceType type;
  final String url;
  final String? thumbnailUrl;
  final String addedBy;
  final Timestamp addedAt;
  final bool isApproved;
  final String? approvedBy;
  final Timestamp? approvedAt;

  CommunityResourceModel({
    required this.id,
    required this.communityId,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    required this.addedBy,
    required this.addedAt,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
  });

  factory CommunityResourceModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityResourceModel(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ResourceType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'link'),
        orElse: () => ResourceType.link,
      ),
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      addedBy: data['addedBy'] ?? '',
      addedAt: data['addedAt'] ?? Timestamp.now(),
      isApproved: data['isApproved'] ?? false,
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'title': title,
      'description': description,
      'type': type.name,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'addedBy': addedBy,
      'addedAt': addedAt,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
    };
  }

  CommunityResourceModel copyWith({
    bool? isApproved,
    String? approvedBy,
    Timestamp? approvedAt,
  }) {
    return CommunityResourceModel(
      id: id,
      communityId: communityId,
      title: title,
      description: description,
      type: type,
      url: url,
      thumbnailUrl: thumbnailUrl,
      addedBy: addedBy,
      addedAt: addedAt,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
