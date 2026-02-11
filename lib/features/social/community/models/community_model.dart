import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final List<String> rules;
  final String? iconUrl;
  final String? bannerUrl;
  final String creatorId;
  final int memberCount;
  final int activeCount; // e.g. members online or active recently
  final Timestamp createdAt;
  final bool isPrivate;
  final bool requiresJoinApproval;
  final bool requiresPostApproval;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    this.rules = const [],
    this.iconUrl,
    this.bannerUrl,
    required this.creatorId,
    this.memberCount = 0,
    this.activeCount = 0,
    required this.createdAt,
    this.isPrivate = false,
    this.requiresJoinApproval = false,
    this.requiresPostApproval = false,
  });

  factory CommunityModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      rules: List<String>.from(data['rules'] ?? []),
      iconUrl: data['iconUrl'] as String?,
      bannerUrl: data['bannerUrl'] as String?,
      creatorId: data['creatorId'] as String? ?? '',
      memberCount: data['memberCount'] as int? ?? 0,
      activeCount: data['activeCount'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      isPrivate: data['isPrivate'] as bool? ?? false,
      requiresJoinApproval: data['requiresJoinApproval'] as bool? ?? false,
      requiresPostApproval: data['requiresPostApproval'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'rules': rules,
      'iconUrl': iconUrl,
      'bannerUrl': bannerUrl,
      'creatorId': creatorId,
      'memberCount': memberCount,
      'activeCount': activeCount,
      'createdAt': createdAt,
      'isPrivate': isPrivate,
      'requiresJoinApproval': requiresJoinApproval,
      'requiresPostApproval': requiresPostApproval,
    };
  }

  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? rules,
    String? iconUrl,
    String? bannerUrl,
    String? creatorId,
    int? memberCount,
    int? activeCount,
    Timestamp? createdAt,
    bool? isPrivate,
    bool? requiresJoinApproval,
    bool? requiresPostApproval,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      iconUrl: iconUrl ?? this.iconUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      creatorId: creatorId ?? this.creatorId,
      memberCount: memberCount ?? this.memberCount,
      activeCount: activeCount ?? this.activeCount,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      requiresJoinApproval: requiresJoinApproval ?? this.requiresJoinApproval,
      requiresPostApproval: requiresPostApproval ?? this.requiresPostApproval,
    );
  }
}
