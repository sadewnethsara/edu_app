import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:math/features/social/community/models/community_model.dart';
import 'package:math/features/social/community/models/community_member_model.dart';
import 'package:math/features/social/community/models/community_resource_model.dart';
import 'package:math/features/social/feed/models/post_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/services/logger_service.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  /// Create a new community
  Future<String?> createCommunity({
    required String name,
    required String description,
    required List<String> rules,
    required String creatorId,
    File? iconFile,
    File? bannerFile,
    bool isPrivate = false,
  }) async {
    try {
      final docRef = _firestore.collection('communities').doc();
      final String communityId = docRef.id;

      String? iconUrl;
      String? bannerUrl;

      // Upload images if exists
      if (iconFile != null) {
        iconUrl = await _uploadCommunityImage(iconFile, communityId, 'icon');
      }
      if (bannerFile != null) {
        bannerUrl = await _uploadCommunityImage(
          bannerFile,
          communityId,
          'banner',
        );
      }

      final community = CommunityModel(
        id: communityId,
        name: name,
        description: description,
        rules: rules,
        iconUrl: iconUrl,
        bannerUrl: bannerUrl,
        creatorId: creatorId,
        memberCount: 1, // Creator is first member
        activeCount: 0,
        createdAt: Timestamp.now(),
        isPrivate: isPrivate,
      );

      await docRef.set(community.toJson());

      // Add creator as Admin member (skip internal join notification here)
      await joinCommunity(
        communityId,
        creatorId,
        role: CommunityRole.admin,
        skipNotification: true,
      );

      // Send "Community Created" notification to creator
      await SocialService().sendNotification(
        toUserId: creatorId,
        title: 'Community Created!',
        message: 'Your community "$name" has been created successfully.',
        type: 'community_created',
        targetContentId: communityId,
      );

      return communityId;
    } catch (e) {
      logger.e('Error creating community', error: e);
      return null;
    }
  }

  /// Upload community image (icon/banner)
  Future<String?> _uploadCommunityImage(
    File file,
    String communityId,
    String type,
  ) async {
    try {
      final ref = _storage
          .ref()
          .child('communities')
          .child(communityId)
          .child('$type.jpg');

      final snapshot = await ref.putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      logger.e('Error uploading community $type', error: e);
      return null;
    }
  }

  /// Join a community
  Future<void> joinCommunity(
    String communityId,
    String userId, {
    CommunityRole role = CommunityRole.member,
    bool skipNotification = false,
  }) async {
    try {
      final memberRef = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId);

      final existingDoc = await memberRef.get();
      if (existingDoc.exists) return; // Already joined/pending

      final community = await getCommunity(communityId);
      final bool requiresApproval = community?.requiresJoinApproval ?? false;

      final member = CommunityMemberModel(
        userId: userId,
        communityId: communityId,
        role: role,
        joinedAt: Timestamp.now(),
        status: (requiresApproval && role == CommunityRole.member)
            ? MemberStatus.pending
            : MemberStatus.approved,
      );

      await _firestore.runTransaction((transaction) async {
        transaction.set(memberRef, member.toJson());

        if (member.status == MemberStatus.approved) {
          // Increment member count only if approved
          final communityRef = _firestore
              .collection('communities')
              .doc(communityId);
          transaction.update(communityRef, {
            'memberCount': FieldValue.increment(1),
          });
        }
      });

      // --- Send Notifications ---
      if (!skipNotification && community != null) {
        if (member.status == MemberStatus.pending) {
          // Notify the User that request is sent
          await SocialService().sendNotification(
            toUserId: userId,
            title: 'Request Sent',
            message:
                'Your request to join "${community.name}" is pending approval.',
            type: 'community_request_pending',
            targetContentId: communityId,
          );

          // Notify the Community Owner about request
          await SocialService().sendNotification(
            toUserId: community.creatorId,
            title: 'New Join Request',
            message:
                'Someone wants to join your community "${community.name}".',
            type: 'community_request',
            senderId: userId,
            targetContentId: communityId,
          );
        } else {
          // 1. Notify the User who joined
          await SocialService().sendNotification(
            toUserId: userId,
            title: 'Welcome!',
            message: 'You have joined the community "${community.name}".',
            type: 'community_join',
            targetContentId: communityId,
          );

          // 2. Notify the Community Owner
          if (community.creatorId != userId) {
            final joinerDoc = await _firestore
                .collection('users')
                .doc(userId)
                .get();
            final joinerName = joinerDoc.data()?['name'] ?? 'A user';

            await SocialService().sendNotification(
              toUserId: community.creatorId,
              title: 'New Member!',
              message: '$joinerName joined your community "${community.name}".',
              type: 'community_member_join',
              senderId: userId,
              senderName: joinerName,
              senderPhotoUrl: joinerDoc.data()?['photoUrl'],
              targetContentId: communityId,
            );
          }
        }
      }
    } catch (e) {
      logger.e('Error joining community', error: e);
      rethrow;
    }
  }

  /// Leave a community
  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      final memberRef = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(memberRef);
        if (!doc.exists) return;

        transaction.delete(memberRef);

        // Decrement member count
        final communityRef = _firestore
            .collection('communities')
            .doc(communityId);
        transaction.update(communityRef, {
          'memberCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      logger.e('Error leaving community', error: e);
      rethrow;
    }
  }

  /// Check if user is a member (approved)
  Future<bool> isMember(String communityId, String userId) async {
    final member = await getMember(communityId, userId);
    return member != null && member.status == MemberStatus.approved;
  }

  /// Get Member info
  Future<CommunityMemberModel?> getMember(
    String communityId,
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return CommunityMemberModel.fromSnapshot(doc);
    } catch (e) {
      return null;
    }
  }

  /// Update Member Status (Approve/Reject)
  Future<void> updateMemberStatus(
    String communityId,
    String userId,
    MemberStatus newStatus,
  ) async {
    try {
      final memberRef = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(memberRef);
        if (!doc.exists) return;

        final oldMember = CommunityMemberModel.fromSnapshot(doc);
        if (oldMember.status == newStatus) return;

        transaction.update(memberRef, {'status': newStatus.name});

        // If becoming approved from pending
        if (oldMember.status == MemberStatus.pending &&
            newStatus == MemberStatus.approved) {
          final communityRef = _firestore
              .collection('communities')
              .doc(communityId);
          transaction.update(communityRef, {
            'memberCount': FieldValue.increment(1),
          });
        }
        // If becoming rejected/pending from approved
        else if (oldMember.status == MemberStatus.approved &&
            newStatus != MemberStatus.approved) {
          final communityRef = _firestore
              .collection('communities')
              .doc(communityId);
          transaction.update(communityRef, {
            'memberCount': FieldValue.increment(-1),
          });
        }
      });
    } catch (e) {
      logger.e('Error updating member status', error: e);
    }
  }

  /// Get Community Details
  Future<CommunityModel?> getCommunity(String communityId) async {
    try {
      final doc = await _firestore
          .collection('communities')
          .doc(communityId)
          .get();
      if (!doc.exists) return null;
      return CommunityModel.fromSnapshot(doc);
    } catch (e) {
      logger.e('Error getting community', error: e);
      return null;
    }
  }

  /// Get User's Communities
  /// NOTE: This depends on how we structure the queries.
  /// Since "members" is a subcollection, querying "all communities I'm in" requires a Collection Group query
  /// OR keeping a denormalized list of communities in the User document.
  /// Ideally, for scalability, we should use a separate top-level 'community_members' collection
  /// or list in user profile.
  /// For this implementation, I will assume we fetch the communities the user has joined
  /// by querying a separate collection or we can just fetch all and filter client side (bad for scale)
  /// OR, better: Add a 'joinedCommunities' subcollection to the USER.
  ///
  /// Let's update `joinCommunity` to also add to `users/{uid}/communities/{communityId}` for easy lookup.
  Future<List<CommunityModel>> getUserCommunities(String userId) async {
    try {
      // Fetch IDs from user's subcollection (we need to implement this in join/leave first)
      // For now, let's assume we implement the dual-write in joinCommunity.
      // Wait, I should update joinCommunity to write to user's collection too.
      // But let's check `joinCommunity`.

      // Since I haven't modified the User model to hold a list, I'll do a Collection Group query
      // if 'members' is a subcollection of 'communities'.
      // Code:
      // return _firestore.collectionGroup('members').where('userId', isEqualTo: userId).get()...
      // But 'userId' is the doc ID in existing implementation? No, I added userId as a field in `CommunityMemberModel`.
      // Yes: `userId: doc.id` in fromSnapshot, but also passed in constructor.

      // Let's rely on collectionGroup for now, or better:
      // Let's keep it simple and clean: Use a denormalized map/list if possible, but
      // Collection Group 'members' where userId == myId is valid.

      final querySnapshot = await _firestore
          .collectionGroup('members')
          .where('userId', isEqualTo: userId)
          .get();

      List<String> communityIds = [];
      for (var doc in querySnapshot.docs) {
        // The parent of 'members' collection is the community doc
        // path: communities/{communityId}/members/{userId}
        // doc.reference.parent.parent?.id
        if (doc.reference.parent.parent != null) {
          communityIds.add(doc.reference.parent.parent!.id);
        }
      }

      if (communityIds.isEmpty) return [];

      // Fetch actual community docs (in chunks of 10)
      List<CommunityModel> communities = [];
      for (var i = 0; i < communityIds.length; i += 10) {
        final chunk = communityIds.sublist(
          i,
          (i + 10) > communityIds.length ? communityIds.length : i + 10,
        );
        final snap = await _firestore
            .collection('communities')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        communities.addAll(
          snap.docs.map((d) => CommunityModel.fromSnapshot(d)),
        );
      }
      return communities;
    } catch (e) {
      logger.e('Error getting user communities', error: e);
      return [];
    }
  }

  /// Get Trending/Recommended Communities
  Future<List<CommunityModel>> getRecommendedCommunities({
    int limit = 10,
  }) async {
    try {
      final snap = await _firestore
          .collection('communities')
          .orderBy('memberCount', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((d) => CommunityModel.fromSnapshot(d)).toList();
    } catch (e) {
      logger.e('Error getting recommended communities', error: e);
      return [];
    }
  }

  /// Search Communities
  Future<List<CommunityModel>> searchCommunities(String query) async {
    try {
      if (query.isEmpty) return [];

      // Note: Firestore doesn't support full-text search.
      // We implement a simple startAt/endAt search for name.
      final snap = await _firestore
          .collection('communities')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snap.docs.map((d) => CommunityModel.fromSnapshot(d)).toList();
    } catch (e) {
      logger.e('Error searching communities', error: e);
      return [];
    }
  }

  /// Update Community Details
  Future<void> updateCommunity(
    String communityId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error updating community', error: e);
      rethrow;
    }
  }

  /// Get pending posts for a community
  Future<List<PostModel>> getPendingPosts(String communityId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: PostStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => PostModel.fromSnapshot(doc)).toList();
    } catch (e) {
      logger.e('Error fetching pending posts', error: e);
      return [];
    }
  }

  /// Approve a pending post
  Future<void> approvePost(String postId, String approverId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final doc = await postRef.get();
      if (!doc.exists) return;

      final post = PostModel.fromSnapshot(doc);

      await postRef.update({
        'status': PostStatus.approved.name,
        'approvedBy': approverId,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Notify the author
      await SocialService().sendNotification(
        toUserId: post.authorId,
        title: 'Post Approved',
        message: 'Your post in "${post.communityName}" has been approved.',
        type: 'post_approved',
        targetContentId: post.postId,
      );
    } catch (e) {
      logger.e('Error approving post', error: e);
      rethrow;
    }
  }

  /// Reject a pending post
  Future<void> rejectPost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'status': PostStatus.rejected.name,
      });
    } catch (e) {
      logger.e('Error rejecting post', error: e);
      rethrow;
    }
  }

  /// Get all members of a community
  Stream<List<CommunityMemberModel>> getCommunityMembers(String communityId) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommunityMemberModel.fromSnapshot(doc))
              .toList(),
        );
  }

  // --- Community Resources ---

  /// Upload a resource file (video/document)
  Future<String?> uploadResourceFile({
    required String communityId,
    required String resourceId,
    required File file,
    required String type, // 'video' or 'document'
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('communities')
          .child(communityId)
          .child('resources')
          .child(resourceId)
          .child('${DateTime.now().millisecondsSinceEpoch}_$type');

      final snapshot = await ref.putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      logger.e('Error uploading resource $type', error: e);
      return null;
    }
  }

  /// Upload community profile/banner photo
  Future<String?> uploadCommunityPhoto({
    required String communityId,
    required File file,
    required bool isBanner,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('communities')
          .child(communityId)
          .child(isBanner ? 'banner' : 'profile');

      final snapshot = await ref.putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      logger.e('Error uploading community photo', error: e);
      return null;
    }
  }

  /// Add a resource to a community
  Future<void> addResource({
    required String communityId,
    required String title,
    required String description,
    required ResourceType type,
    required String url,
    required String userId,
    String? thumbnailUrl,
    bool isAutoApproved = false,
  }) async {
    try {
      final docRef = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('resources')
          .doc();

      final resource = CommunityResourceModel(
        id: docRef.id,
        communityId: communityId,
        title: title,
        description: description,
        type: type,
        url: url,
        thumbnailUrl: thumbnailUrl,
        addedBy: userId,
        addedAt: Timestamp.now(),
        isApproved: isAutoApproved,
      );

      await docRef.set(resource.toJson());

      // Notify admin if not auto-approved
      if (!isAutoApproved) {
        final community = await getCommunity(communityId);
        if (community != null) {
          await SocialService().sendNotification(
            toUserId: community.creatorId,
            title: 'New Resource Pending',
            message: 'A new resource "$title" needs review in your community.',
            type: 'resource_pending',
            targetContentId: communityId,
          );
        }
      }
    } catch (e) {
      logger.e('Error adding resource', error: e);
      rethrow;
    }
  }

  /// Get approved resources for a community
  Stream<List<CommunityResourceModel>> getApprovedResources(
    String communityId,
  ) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('resources')
        .where('isApproved', isEqualTo: true)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CommunityResourceModel.fromSnapshot(d))
              .toList(),
        );
  }

  /// Get pending resources (for admins)
  Future<List<CommunityResourceModel>> getPendingResources(
    String communityId,
  ) async {
    try {
      final snap = await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('resources')
          .where('isApproved', isEqualTo: false)
          .orderBy('addedAt', descending: true)
          .get();

      return snap.docs
          .map((d) => CommunityResourceModel.fromSnapshot(d))
          .toList();
    } catch (e) {
      logger.e('Error getting pending resources', error: e);
      return [];
    }
  }

  /// Approve a resource
  Future<void> approveResource(
    String communityId,
    String resourceId,
    String adminId,
  ) async {
    try {
      final ref = _firestore
          .collection('communities')
          .doc(communityId)
          .collection('resources')
          .doc(resourceId);

      final doc = await ref.get();
      if (!doc.exists) return;

      final resource = CommunityResourceModel.fromSnapshot(doc);

      await ref.update({
        'isApproved': true,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Notify contributor
      await SocialService().sendNotification(
        toUserId: resource.addedBy,
        title: 'Resource Approved!',
        message: 'Your resource "${resource.title}" is now live.',
        type: 'resource_approved',
        targetContentId: communityId,
      );
    } catch (e) {
      logger.e('Error approving resource', error: e);
      rethrow;
    }
  }

  /// Reject/Delete a resource
  Future<void> rejectResource(String communityId, String resourceId) async {
    try {
      await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('resources')
          .doc(resourceId)
          .delete();
    } catch (e) {
      logger.e('Error rejecting resource', error: e);
      rethrow;
    }
  }
}
