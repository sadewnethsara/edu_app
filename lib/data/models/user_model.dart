import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final int points;
  final List<String> grades;
  final String? province;
  final String? district;
  final String? city;
  final String? gender;
  final double completionPercent;
  final Timestamp? createdAt;
  final Map<String, int> achievements;
  final int followersCount;
  final int followingCount;
  final int postCount;

  // Privacy & Settings
  final bool isPrivateAccount;
  final List<String> mutedUsers;
  final List<String> blockedUsers;
  final String replyPreference; // Everyone, Followers
  final bool allowTagging;
  final bool autoplayVideos;
  final String? bio;
  // 🚀 --- END OF ADDED FIELDS --- 🚀

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.points = 0,
    this.grades = const [],
    this.province,
    this.district,
    this.city,
    this.gender,
    this.completionPercent = 0.0,
    this.createdAt,
    this.achievements = const {},
    // 🚀 ADDED TO CONSTRUCTOR
    this.followersCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.isPrivateAccount = false,
    this.mutedUsers = const [],
    this.blockedUsers = const [],
    this.replyPreference = 'Everyone',
    this.allowTagging = true,
    this.autoplayVideos = true,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> achievementsMap = {};
    if (json['achievements'] is Map) {
      (json['achievements'] as Map).forEach((key, value) {
        if (value is int) {
          achievementsMap[key.toString()] = value;
        }
      });
    }

    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'No Name',
      photoURL: json['photoURL'] as String?,
      points: json['points'] as int? ?? 0,
      grades: List<String>.from(json['grades'] ?? []),
      province: json['province'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
      gender: json['gender'] as String?,
      completionPercent: (json['completionPercent'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] as Timestamp?,
      achievements: achievementsMap,

      // 🚀 ADDED TO FROMJSON
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? 0,
      isPrivateAccount: json['isPrivateAccount'] as bool? ?? false,
      mutedUsers: List<String>.from(json['mutedUsers'] ?? []),
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      replyPreference: json['replyPreference'] as String? ?? 'Everyone',
      allowTagging: json['allowTagging'] as bool? ?? true,
      autoplayVideos: json['autoplayVideos'] as bool? ?? true,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'points': points,
      'grades': grades,
      'province': province,
      'district': district,
      'city': city,
      'gender': gender,
      'completionPercent': completionPercent,
      'createdAt': createdAt,
      'achievements': achievements,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'isPrivateAccount': isPrivateAccount,
      'mutedUsers': mutedUsers,
      'blockedUsers': blockedUsers,
      'replyPreference': replyPreference,
      'allowTagging': allowTagging,
      'autoplayVideos': autoplayVideos,
      'bio': bio,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    int? points,
    List<String>? grades,
    String? province,
    String? district,
    String? city,
    String? gender,
    double? completionPercent,
    Timestamp? createdAt,
    Map<String, int>? achievements,
    int? followersCount,
    int? followingCount,
    int? postCount,
    bool? isPrivateAccount,
    List<String>? mutedUsers,
    List<String>? blockedUsers,
    String? replyPreference,
    bool? allowTagging,
    bool? autoplayVideos,
    String? bio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      points: points ?? this.points,
      grades: grades ?? this.grades,
      province: province ?? this.province,
      district: district ?? this.district,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      completionPercent: completionPercent ?? this.completionPercent,
      createdAt: createdAt ?? this.createdAt,
      achievements: achievements ?? this.achievements,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      isPrivateAccount: isPrivateAccount ?? this.isPrivateAccount,
      mutedUsers: mutedUsers ?? this.mutedUsers,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      replyPreference: replyPreference ?? this.replyPreference,
      allowTagging: allowTagging ?? this.allowTagging,
      autoplayVideos: autoplayVideos ?? this.autoplayVideos,
      bio: bio ?? this.bio,
    );
  }
}
