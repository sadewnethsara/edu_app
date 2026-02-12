import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:math/core/models/user_model.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/services/logger_service.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static final SocialService _instance = SocialService._internal();
  factory SocialService() => _instance;
  SocialService._internal();

  Future<void> updateUserSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(settings);
    } catch (e) {
      logger.e('Error updating user settings', error: e);
      rethrow;
    }
  }

  Future<void> muteUser(String myUid, String targetUid) async {
    try {
      await _firestore
          .collection('users')
          .doc(myUid)
          .collection('muted')
          .doc(targetUid)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await _firestore.collection('users').doc(myUid).update({
        'mutedUsers': FieldValue.arrayUnion([targetUid]),
      });
    } catch (e) {
      logger.e('Error muting user', error: e);
      rethrow;
    }
  }

  Future<void> unmuteUser(String myUid, String targetUid) async {
    try {
      await _firestore
          .collection('users')
          .doc(myUid)
          .collection('muted')
          .doc(targetUid)
          .delete();
      await _firestore.collection('users').doc(myUid).update({
        'mutedUsers': FieldValue.arrayRemove([targetUid]),
      });
    } catch (e) {
      logger.e('Error unmuting user', error: e);
      rethrow;
    }
  }

  Future<void> blockUser(String myUid, String targetUid) async {
    try {
      await _firestore
          .collection('users')
          .doc(myUid)
          .collection('blocked')
          .doc(targetUid)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await _firestore.collection('users').doc(myUid).update({
        'blockedUsers': FieldValue.arrayUnion([targetUid]),
      });
      await unfollowUser(myUid, targetUid);
      await unfollowUser(targetUid, myUid);
    } catch (e) {
      logger.e('Error blocking user', error: e);
      rethrow;
    }
  }

  Future<void> unblockUser(String myUid, String targetUid) async {
    try {
      await _firestore
          .collection('users')
          .doc(myUid)
          .collection('blocked')
          .doc(targetUid)
          .delete();
      await _firestore.collection('users').doc(myUid).update({
        'blockedUsers': FieldValue.arrayRemove([targetUid]),
      });
    } catch (e) {
      logger.e('Error unblocking user', error: e);
      rethrow;
    }
  }

  Future<bool> isMuted(String myUid, String targetUid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(myUid)
          .collection('muted')
          .doc(targetUid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBlocked(String myUid, String targetUid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(myUid)
          .collection('blocked')
          .doc(targetUid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkIsFollowing(String myUid, String targetUid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(myUid)
          .collection('following')
          .doc(targetUid)
          .get();
      return doc.exists;
    } catch (e) {
      logger.e('Error checking follow status', error: e);
      return false;
    }
  }

  Future<void> followUser(String myUid, String targetUid) async {
    try {
      final myRef = _firestore.collection('users').doc(myUid);
      final targetRef = _firestore.collection('users').doc(targetUid);

      final myFollowingRef = myRef.collection('following').doc(targetUid);
      final targetFollowersRef = targetRef.collection('followers').doc(myUid);

      await _firestore.runTransaction((transaction) async {
        final followingDoc = await transaction.get(myFollowingRef);
        if (followingDoc.exists) return; // Already following

        transaction.set(myFollowingRef, {
          'timestamp': FieldValue.serverTimestamp(),
        });

        transaction.set(targetFollowersRef, {
          'timestamp': FieldValue.serverTimestamp(),
        });

        transaction.update(myRef, {'followingCount': FieldValue.increment(1)});

        transaction.update(targetRef, {
          'followersCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      logger.e('Error following user', error: e);
      rethrow;
    }
  }

  Future<void> unfollowUser(String myUid, String targetUid) async {
    try {
      final myRef = _firestore.collection('users').doc(myUid);
      final targetRef = _firestore.collection('users').doc(targetUid);

      final myFollowingRef = myRef.collection('following').doc(targetUid);
      final targetFollowersRef = targetRef.collection('followers').doc(myUid);

      await _firestore.runTransaction((transaction) async {
        final followingDoc = await transaction.get(myFollowingRef);
        if (!followingDoc.exists) return; // Not following

        transaction.delete(myFollowingRef);

        transaction.delete(targetFollowersRef);

        transaction.update(myRef, {'followingCount': FieldValue.increment(-1)});

        transaction.update(targetRef, {
          'followersCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      logger.e('Error unfollowing user', error: e);
      rethrow;
    }
  }

  Stream<QuerySnapshot> getFollowersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getFollowingStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      logger.e('Error fetching user profile', error: e);
      return null;
    }
  }

  Future<List<UserModel>> getUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      List<UserModel> users = [];
      for (var i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.sublist(
          i,
          (i + 10) > userIds.length ? userIds.length : i + 10,
        );
        final snapshot = await _firestore
            .collection('users')
            .where('uid', whereIn: chunk)
            .get();
        users.addAll(
          snapshot.docs.map((doc) => UserModel.fromJson(doc.data())),
        );
      }
      return users;
    } catch (e) {
      logger.e('Error fetching multiple users', error: e);
      return [];
    }
  }

  Future<List<PostModel>> getPosts(List<String> postIds) async {
    if (postIds.isEmpty) return [];
    try {
      List<PostModel> posts = [];
      for (var i = 0; i < postIds.length; i += 10) {
        final chunk = postIds.sublist(
          i,
          (i + 10) > postIds.length ? postIds.length : i + 10,
        );
        final snapshot = await _firestore
            .collection('posts')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        final fetchedPosts = snapshot.docs
            .map((doc) => PostModel.fromSnapshot(doc))
            .toList();
        for (var id in chunk) {
          try {
            final post = fetchedPosts.firstWhere((p) => p.postId == id);
            posts.add(post);
          } catch (_) {}
        }
      }
      return posts;
    } catch (e) {
      logger.e('Error fetching multiple posts', error: e);
      return [];
    }
  }

  Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String message,
    required String type,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? targetContentId,
  }) async {
    if (toUserId == senderId) return; // Don't notify self

    try {
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'type': type,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'senderId': senderId,
            'senderName': senderName,
            'senderPhotoUrl': senderPhotoUrl,
            'targetContentId': targetContentId,
          });
    } catch (e) {
      logger.e('Failed to send notification', error: e);
    }
  }

  Stream<int> unreadNotificationsCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      logger.e('Failed to mark all as read', error: e);
    }
  }

  Future<String?> uploadReplyImage(File imageFile, String userId) async {
    try {
      logger.i('Uploading reply image for user: $userId');
      final ref = _storage
          .ref()
          .child('reply_images')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final snapshot = await ref.putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      logger.e('Failed to upload reply image', error: e);
      return null;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      logger.e('Error deleting post', error: e);
      rethrow;
    }
  }

  Future<void> hidePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('hidden_posts')
          .doc(postId)
          .set({'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      logger.e('Error hiding post', error: e);
      rethrow;
    }
  }

  Future<void> reportPost(
    String postId,
    String reason,
    String details,
    String reportedByUserId,
  ) async {
    try {
      await _firestore.collection('reports').add({
        'targetId': postId,
        'type': 'post',
        'reason': reason,
        'details': details,
        'reportedBy': reportedByUserId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error reporting post', error: e);
      rethrow;
    }
  }

  Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {}
  }

  Future<void> incrementShareCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'shareCount': FieldValue.increment(1),
      });
    } catch (e) {
      logger.e('Error incrementing share count', error: e);
    }
  }

  Future<void> reSharePost({
    required String postId,
    required String userId,
    String? userName,
    String? userPhotoUrl,
    PostModel? originalPost,
    String? text,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final userDoc = await firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final bool isBanned = userData?['isBanned'] as bool? ?? false;

      if (isBanned) {
        final Timestamp? banExpiresAt = userData?['banExpiresAt'] as Timestamp?;
        if (banExpiresAt == null ||
            banExpiresAt.toDate().isAfter(DateTime.now())) {
          throw Exception("You are banned from posting.");
        }
      }

      PostModel sourcePost;

      if (originalPost != null) {
        sourcePost = originalPost;
      } else {
        final doc = await firestore.collection('posts').doc(postId).get();
        if (!doc.exists) throw Exception("Original post not found");
        sourcePost = PostModel.fromSnapshot(doc);
      }

      String targetPostId = sourcePost.postId;
      PostModel targetPost = sourcePost;

      if (sourcePost.originalPostId != null &&
          sourcePost.originalPost != null) {
        targetPostId = sourcePost.originalPostId!;
        targetPost = sourcePost.originalPost!;
      }

      if (sourcePost.originalPostId != null &&
          sourcePost.originalPost != null) {
        targetPostId = sourcePost.originalPostId!;
        targetPost = sourcePost.originalPost!;
      }

      String authorName = userName ?? 'Unknown';
      String? authorPhoto = userPhotoUrl;

      if (userName == null) {
        final userDoc = await firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        authorName = userData?['name'] ?? 'Unknown';
        authorPhoto = userData?['photoUrl'];
      }

      final newPostRef = firestore.collection('posts').doc();
      final finalPost = PostModel(
        postId: newPostRef.id,
        authorId: userId,
        authorName: authorName,
        authorPhotoUrl: authorPhoto,
        text: text ?? '',
        createdAt: Timestamp.now(),
        originalPostId: targetPostId,
        originalPost: targetPost,
      );

      await firestore.runTransaction((transaction) async {
        final originalRef = firestore.collection('posts').doc(targetPostId);
        transaction.update(originalRef, {
          'reShareCount': FieldValue.increment(1),
        });

        transaction.set(newPostRef, finalPost.toJson());
      });

      await sendNotification(
        toUserId: targetPost.authorId,
        title: 'New Repost',
        message: '$authorName reposted your post.',
        type:
            'postReply', // reusing postReply type or add 'repost' if enum allows. safe to use postReply for now.
        senderId: userId,
        senderName: authorName,
        senderPhotoUrl: authorPhoto,
        targetContentId: targetPostId,
      );
    } catch (e) {
      logger.e('Error re-sharing post', error: e);
      rethrow;
    }
  }

  Stream<QuerySnapshot> getPostsByTag(String tag) {
    return _firestore
        .collection('posts')
        .where('tags', arrayContains: tag.toLowerCase())
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPostsByCategory(PostCategory category) {
    return _firestore
        .collection('posts')
        .where('category', isEqualTo: category.name)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPostsBySubject(String subject) {
    return _firestore
        .collection('posts')
        .where('subjectName', isEqualTo: subject)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> searchTags(String query) async {
    if (query.isEmpty) return getPopularTags();

    final searchTerm = query.toLowerCase();
    final snapshot = await _firestore
        .collection('tags')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: searchTerm)
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => {'tag': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getPopularTags() async {
    final snapshot = await _firestore
        .collection('tags')
        .orderBy('useCount', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => {'tag': doc.id, ...doc.data()}).toList();
  }

  Future<void> updateTagCount(String tag, int increment) async {
    final tagRef = _firestore.collection('tags').doc(tag.toLowerCase());
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(tagRef);
      if (!doc.exists) {
        if (increment > 0) {
          transaction.set(tagRef, {
            'useCount': increment,
            'lastUsed': FieldValue.serverTimestamp(),
          });
        }
      } else {
        transaction.update(tagRef, {
          'useCount': FieldValue.increment(increment),
          'lastUsed': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> toggleFavorite(String userId, String postId) async {
    try {
      final favRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(postId);

      final doc = await favRef.get();
      if (doc.exists) {
        await favRef.delete();
      } else {
        await favRef.set({
          'postId': postId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      logger.e('Error toggling favorite', error: e);
      rethrow;
    }
  }

  Future<bool> isFavorited(String userId, String postId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(postId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Stream<List<String>> getFavoritePostIdsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
