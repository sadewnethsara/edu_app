import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math/data/models/content_model.dart';
import 'package:math/data/models/grade_model.dart';
import 'package:math/data/models/language_model.dart';
import 'package:math/data/models/lesson_model.dart';
import 'package:math/data/models/notification_model.dart'; // 🚀 ADDED
import 'package:math/features/social/feed/models/post_model.dart';
import 'package:math/data/models/past_paper_model.dart';
import 'package:math/data/models/subject_model.dart';
import 'package:math/data/models/subtopic_model.dart';
import 'package:math/data/models/user_model.dart';
import 'package:math/services/logger_service.dart';

class ApiService {
  final FirebaseFirestore _firestore;

  ApiService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // --- Memory Cache ---
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5); // 5 minute TTL

  // --- Helper: Cache Management ---
  T? _getFromCache<T>(String key) {
    if (_memoryCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        logger.i('📦 Returning cached data for: $key');
        return _memoryCache[key] as T;
      } else {
        logger.d('⌛ Cache expired for: $key');
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
    return null;
  }

  void _saveToCache(String key, dynamic data) {
    if (data != null) {
      _memoryCache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
      logger.d('💾 Saved to cache: $key');
    }
  }

  void clearCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    logger.i('🧹 Memory cache cleared');
  }

  // --- Helper: Language Matcher ---
  bool _matchesLanguage(String? itemLanguage, String targetLanguage) {
    if (itemLanguage == null || itemLanguage.isEmpty) {
      return true;
    }

    final itemLang = itemLanguage.toLowerCase();
    final targetLang = targetLanguage.toLowerCase();

    return itemLang == targetLang ||
        (itemLang == 'english' && targetLang == 'en') ||
        (itemLang == 'sinhala' && targetLang == 'si') ||
        (itemLang == 'en' && targetLang == 'english') ||
        (itemLang == 'si' && targetLang == 'sinhala');
  }

  // --- Content Item Parser Helper (Uses Language Filter) ---
  List<ContentItem> _parseAndFilterContentItems(
    List<dynamic>? items,
    String languageCode,
  ) {
    if (items == null) return [];

    return items
        .map((e) => e as Map<String, dynamic>)
        .where(
          (item) => _matchesLanguage(item['language'] as String?, languageCode),
        )
        .map((item) => ContentItem.fromJson(item))
        .toList();
  }

  // -----------------------------------------------------------
  // 1. CURRICULUM & CONTENT APIs
  // -----------------------------------------------------------
  Future<List<LanguageModel>> getLanguages() async {
    try {
      final snapshot = await _firestore
          .collection('languages')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => LanguageModel.fromJson({...doc.data(), 'code': doc.id}))
          .toList();
    } catch (e, s) {
      logger.e('Error fetching languages', error: e, stackTrace: s);
      return [];
    }
  }

  // --- Grade APIs ---
  Future<List<GradeModel>> getGrades(String languageCode) async {
    try {
      final snapshot = await _firestore
          .collection('curricula')
          .doc(languageCode)
          .collection('grades')
          .orderBy('order')
          .get();

      final grades = snapshot.docs.map((doc) {
        final data = doc.data();
        return GradeModel.fromJson({
          'id': doc.id,
          'order': data['order'] ?? 0,
          'name': data['name'] ?? 'Unknown',
          'description': data['description'] ?? '',
          'isActive': data['isActive'] ?? true,
          'language': languageCode,
          'imageUrl': data['imageUrl'],
        });
      }).toList();

      grades.sort((a, b) => a.order.compareTo(b.order));
      return grades;
    } catch (e, s) {
      logger.e('Error fetching grades', error: e, stackTrace: s);
      return [];
    }
  }

  // --- Subject APIs ---
  Future<List<SubjectModel>> getSubjects(
    String gradeId,
    String languageCode, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'subjects_${gradeId}_$languageCode';
    if (!forceRefresh) {
      final cachedData = _getFromCache<List<SubjectModel>>(cacheKey);
      if (cachedData != null) return cachedData;
    }

    try {
      // ✅ Primary: curricula/{languageCode}/grades/{gradeId}/subjects/
      var snapshot = await _firestore
          .collection('curricula')
          .doc(languageCode)
          .collection('grades')
          .doc(gradeId)
          .collection('subjects')
          .orderBy('order')
          .get();

      // 🔁 Fallback: grades/{gradeId}/subjects/
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('grades')
            .doc(gradeId)
            .collection('subjects')
            .orderBy('order')
            .get();
      }

      final subjects = snapshot.docs.map((doc) {
        final data = doc.data();
        return SubjectModel.fromJson({
          'id': doc.id,
          'gradeId': gradeId,
          'order': data['order'] ?? 0,
          'name': data['name'] ?? 'Unknown',
          'description': data['description'] ?? '',
          'language': languageCode,
          'imageUrl': data['imageUrl'],
          'isActive': data['isActive'] ?? true,
        });
      }).toList();

      subjects.sort((a, b) => a.order.compareTo(b.order));
      _saveToCache(cacheKey, subjects);
      return subjects;
    } catch (e, s) {
      logger.e('Error fetching subjects', error: e, stackTrace: s);
      return [];
    }
  }

  // --- Lesson APIs ---
  Future<List<LessonModel>> getLessons(
    String gradeId,
    String subjectId,
    String languageCode, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'lessons_${gradeId}_${subjectId}_$languageCode';
    if (!forceRefresh) {
      final cachedData = _getFromCache<List<LessonModel>>(cacheKey);
      if (cachedData != null) return cachedData;
    }

    try {
      logger.i(
        '📚 Fetching lessons for grade: $gradeId, subject: $subjectId, language: $languageCode',
      );

      // ✅ PRIMARY: Fetch from grades path (where admin API creates lessons)
      var snapshot = await _firestore
          .collection('grades')
          .doc(gradeId)
          .collection('subjects')
          .doc(subjectId)
          .collection('lessons')
          .where('language', isEqualTo: languageCode)
          .get();

      logger.i(
        'Found ${snapshot.docs.length} lessons in grades/$gradeId/subjects/$subjectId/lessons (filtered by language: $languageCode)',
      );

      // 🔁 FALLBACK: Try without language filter if no lessons found
      if (snapshot.docs.isEmpty) {
        logger.w(
          '⚠️ No lessons with language filter, trying without language filter...',
        );
        snapshot = await _firestore
            .collection('grades')
            .doc(gradeId)
            .collection('subjects')
            .doc(subjectId)
            .collection('lessons')
            .get();

        logger.i(
          'Found ${snapshot.docs.length} lessons without language filter',
        );
      }

      // 🔁 FALLBACK 2: Try curricula path if still empty
      if (snapshot.docs.isEmpty) {
        logger.w(
          '⚠️ No lessons in grades path, trying curricula path fallback...',
        );
        snapshot = await _firestore
            .collection('curricula')
            .doc(languageCode)
            .collection('grades')
            .doc(gradeId)
            .collection('subjects')
            .doc(subjectId)
            .collection('lessons')
            .get();

        logger.i('Found ${snapshot.docs.length} lessons in curricula path');
      }

      if (snapshot.docs.isEmpty) {
        logger.w('No lessons found in any path');
        return [];
      }

      final lessons = <LessonModel>[];

      int countFilteredItems(Map<String, dynamic>? content, String key) {
        final items = content?[key] as List<dynamic>?;
        if (items == null) return 0;

        return items
            .map((e) => e as Map<String, dynamic>)
            .where(
              (item) =>
                  _matchesLanguage(item['language'] as String?, languageCode),
            )
            .length;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final content = data['content'] as Map<String, dynamic>?;

        ContentCounts? contentCounts;
        if (content != null) {
          contentCounts = ContentCounts(
            videos: countFilteredItems(content, 'videos'),
            notes: countFilteredItems(content, 'notes'),
            contentPdfs: countFilteredItems(content, 'contentPdfs'),
            resources: countFilteredItems(content, 'resources'),
          );
        }

        lessons.add(
          LessonModel.fromJson({
            'id': doc.id,
            'subjectId': subjectId,
            'gradeId': gradeId,
            'order': data['order'] ?? 0,
            'name': data['name'] ?? 'Unknown',
            'description': data['description'] ?? '',
            'contentCounts': contentCounts?.toJson(),
            'language': languageCode,
            'imageUrl': data['imageUrl'],
            'isActive': data['isActive'] ?? true,
          }),
        );
      }

      // Sort by order if available, otherwise by name
      lessons.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.name.compareTo(b.name);
      });

      logger.i('✅ Successfully fetched ${lessons.length} lessons');
      _saveToCache(cacheKey, lessons);
      return lessons;
    } catch (e, s) {
      logger.e(
        'Error fetching lessons for grade: $gradeId, subject: $subjectId',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  // 🚀 NEW: searchLessons
  Future<List<LessonModel>> searchLessons(
    String query,
    String languageCode,
  ) async {
    if (query.isEmpty) return [];
    try {
      // Search across all lessons using Collection Group Query
      final snapshot = await _firestore
          .collectionGroup('lessons')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(50)
          .get();

      final results = snapshot.docs
          .map(
            (doc) => LessonModel.fromJson({
              ...doc.data(),
              'id': doc.id, // Ensure ID is captured
            }),
          )
          .where((lesson) => _matchesLanguage(lesson.language, languageCode))
          .toList();

      return results;
    } catch (e, s) {
      logger.e('Error searching lessons', error: e, stackTrace: s);
      return [];
    }
  }

  // --- Subtopic APIs ---
  Future<List<SubtopicModel>> getSubtopics(
    String gradeId,
    String subjectId,
    String lessonId,
    String languageCode, {
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'subtopics_${gradeId}_${subjectId}_${lessonId}_$languageCode';
    if (!forceRefresh) {
      final cachedData = _getFromCache<List<SubtopicModel>>(cacheKey);
      if (cachedData != null) return cachedData;
    }

    try {
      logger.i(
        '📚 Fetching subtopics for lesson: $lessonId, language: $languageCode',
      );

      // ✅ PRIMARY: Fetch from grades path (where admin API creates subtopics)
      var snapshot = await _firestore
          .collection('grades')
          .doc(gradeId)
          .collection('subjects')
          .doc(subjectId)
          .collection('lessons')
          .doc(lessonId)
          .collection('subtopics')
          .where('language', isEqualTo: languageCode)
          .get();

      logger.i(
        'Found ${snapshot.docs.length} subtopics in grades path (filtered by language: $languageCode)',
      );

      // 🔁 FALLBACK: Try without language filter if no subtopics found
      if (snapshot.docs.isEmpty) {
        logger.w(
          '⚠️ No subtopics with language filter, trying without language filter...',
        );
        snapshot = await _firestore
            .collection('grades')
            .doc(gradeId)
            .collection('subjects')
            .doc(subjectId)
            .collection('lessons')
            .doc(lessonId)
            .collection('subtopics')
            .get();

        logger.i(
          'Found ${snapshot.docs.length} subtopics without language filter',
        );
      }

      // 🔁 FALLBACK 2: Try curricula path if still empty
      if (snapshot.docs.isEmpty) {
        logger.w(
          '⚠️ No subtopics in grades path, trying curricula path fallback...',
        );
        snapshot = await _firestore
            .collection('curricula')
            .doc(languageCode)
            .collection('grades')
            .doc(gradeId)
            .collection('subjects')
            .doc(subjectId)
            .collection('lessons')
            .doc(lessonId)
            .collection('subtopics')
            .get();

        logger.i('Found ${snapshot.docs.length} subtopics in curricula path');
      }

      if (snapshot.docs.isEmpty) {
        logger.w('No subtopics found in any path');
        return [];
      }

      final subtopics = <SubtopicModel>[];

      int countFilteredItems(Map<String, dynamic>? content, String key) {
        final items = content?[key] as List<dynamic>?;
        if (items == null) return 0;

        return items
            .map((e) => e as Map<String, dynamic>)
            .where(
              (item) =>
                  _matchesLanguage(item['language'] as String?, languageCode),
            )
            .length;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final content = data['content'] as Map<String, dynamic>?;

        ContentCounts? contentCounts;
        if (content != null) {
          contentCounts = ContentCounts(
            videos: countFilteredItems(content, 'videos'),
            notes: countFilteredItems(content, 'notes'),
            contentPdfs: countFilteredItems(content, 'contentPdfs'),
            resources: countFilteredItems(content, 'resources'),
          );
        }

        subtopics.add(
          SubtopicModel.fromJson({
            'id': doc.id,
            'lessonId': lessonId,
            'subjectId': subjectId,
            'gradeId': gradeId,
            'order': data['order'] ?? 0,
            'name': data['name'] ?? 'Unknown',
            'description': data['description'] ?? '',
            'contentCounts': contentCounts?.toJson(),
            'language': languageCode,
            'imageUrl': data['imageUrl'],
            'isActive': data['isActive'] ?? true,
          }),
        );
      }

      // Sort by order if available, otherwise by name
      subtopics.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return a.name.compareTo(b.name);
      });

      logger.i('✅ Successfully fetched ${subtopics.length} subtopics');
      _saveToCache(cacheKey, subtopics);
      return subtopics;
    } catch (e, s) {
      logger.e(
        'Error fetching subtopics for lesson: $lessonId',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  // --- Lesson Content APIs ---

  /// Fetch lesson content (videos, notes, PDFs, resources) for a specific lesson
  Future<ContentCollection?> getLessonContent(
    String gradeId,
    String subjectId,
    String lessonId,
    String languageCode, {
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'content_${gradeId}_${subjectId}_${lessonId}_$languageCode';
    if (!forceRefresh) {
      final cachedData = _getFromCache<ContentCollection>(cacheKey);
      if (cachedData != null) return cachedData;
    }

    try {
      logger.i(
        'Fetching lesson content for lesson: $lessonId, language: $languageCode',
      );

      final lessonDoc = await _firestore
          .collection('grades')
          .doc(gradeId)
          .collection('subjects')
          .doc(subjectId)
          .collection('lessons')
          .doc(lessonId)
          .get();

      if (!lessonDoc.exists) {
        logger.w('Lesson document not found: $lessonId');
        return ContentCollection.empty();
      }

      final rawContent = lessonDoc.data()?['content'] as Map<String, dynamic>?;
      if (rawContent == null) return ContentCollection.empty();

      final result = ContentCollection(
        videos: _parseAndFilterContentItems(
          rawContent['videos'] as List?,
          languageCode,
        ),
        notes: _parseAndFilterContentItems(
          rawContent['notes'] as List?,
          languageCode,
        ),
        contentPdfs: _parseAndFilterContentItems(
          rawContent['contentPdfs'] as List?,
          languageCode,
        ),
        resources: _parseAndFilterContentItems(
          rawContent['resources'] as List?,
          languageCode,
        ),
      );

      _saveToCache(cacheKey, result);
      return result;
    } catch (e, s) {
      logger.e(
        'Error fetching lesson content for lesson: $lessonId',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Fetch subtopic content (videos, notes, PDFs, resources) for a specific subtopic
  Future<ContentCollection?> getSubtopicContent(
    String gradeId,
    String subjectId,
    String lessonId,
    String subtopicId,
    String languageCode, {
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'content_${gradeId}_${subjectId}_${lessonId}_${subtopicId}_$languageCode';
    if (!forceRefresh) {
      final cachedData = _getFromCache<ContentCollection>(cacheKey);
      if (cachedData != null) return cachedData;
    }

    try {
      logger.i(
        'Fetching subtopic content for subtopic: $subtopicId, language: $languageCode',
      );

      final subtopicDoc = await _firestore
          .collection('grades')
          .doc(gradeId)
          .collection('subjects')
          .doc(subjectId)
          .collection('lessons')
          .doc(lessonId)
          .collection('subtopics')
          .doc(subtopicId)
          .get();

      if (!subtopicDoc.exists) {
        logger.w('Subtopic document not found: $subtopicId');
        return ContentCollection.empty();
      }

      final rawContent =
          subtopicDoc.data()?['content'] as Map<String, dynamic>?;
      if (rawContent == null) return ContentCollection.empty();

      final result = ContentCollection(
        videos: _parseAndFilterContentItems(
          rawContent['videos'] as List?,
          languageCode,
        ),
        notes: _parseAndFilterContentItems(
          rawContent['notes'] as List?,
          languageCode,
        ),
        contentPdfs: _parseAndFilterContentItems(
          rawContent['contentPdfs'] as List?,
          languageCode,
        ),
        resources: _parseAndFilterContentItems(
          rawContent['resources'] as List?,
          languageCode,
        ),
      );

      _saveToCache(cacheKey, result);
      return result;
    } catch (e, s) {
      logger.e(
        'Error fetching subtopic content for subtopic: $subtopicId',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  // -----------------------------------------------------------
  // 2. PAST PAPER APIs
  // -----------------------------------------------------------

  Future<List<PastPaperModel>> getPastPapers(
    String gradeId,
    String languageCode,
  ) async {
    try {
      final subjects = await getSubjects(gradeId, languageCode);
      final List<PastPaperModel> allPapers = [];

      for (final subject in subjects) {
        final filteredPapers = await getPastPapersBySubject(
          subject.id,
          languageCode,
        );
        allPapers.addAll(filteredPapers);
      }

      allPapers.sort((a, b) => b.year.compareTo(a.year));
      return allPapers;
    } catch (e, s) {
      logger.e('Error fetching past papers', error: e, stackTrace: s);
      return [];
    }
  }

  Future<List<PastPaperModel>> getPastPapersBySubject(
    String subjectId,
    String languageCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('pastPapers')
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('year', descending: true)
          .orderBy('uploadedAt', descending: true)
          .get();

      final papers = snapshot.docs.map((doc) {
        final data = doc.data();
        return PastPaperModel.fromJson({
          'id': doc.id,
          'gradeId': data['gradeId'],
          'subjectId': data['subjectId'] ?? subjectId,
          'year': data['year'] ?? '',
          'term': data['term'],
          'title': data['title'] ?? 'Unknown',
          'description': data['description'] ?? '',
          'fileUrl': data['fileUrl'] ?? '',
          'fileSize': (data['fileSize'] is num
              ? (data['fileSize'] as num).toInt()
              : null),
          'language': data['language'] ?? languageCode,
          'uploadedAt': data['uploadedAt'] ?? '',
          'isActive': data['isActive'] ?? true,
          'tags': data['tags'] ?? [],
        });
      }).toList();

      final filteredPapers = papers.where((paper) {
        return _matchesLanguage(paper.language, languageCode);
      }).toList();

      return filteredPapers;
    } catch (e, s) {
      logger.e(
        'Error fetching past papers by subject',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  // -----------------------------------------------------------
  // 4. COMMUNITY APIs
  // -----------------------------------------------------------

  Future<List<PostModel>> getCommunityPosts(
    String communityId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection('posts')
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: PostStatus.approved.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => PostModel.fromSnapshot(doc)).toList();
    } catch (e, s) {
      logger.e('Error fetching community posts', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get a real-time stream of community posts
  Stream<List<PostModel>> getCommunityPostsStream(String communityId) {
    return _firestore
        .collection('posts')
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: PostStatus.approved.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromSnapshot(doc))
              .toList();
        });
  }

  Future<void> debugPastPapersCollection() async {
    // This is utility code and remains as a debug helper
  }

  // -----------------------------------------------------------
  // 3. SOCIAL & LEADERBOARD APIs
  // -----------------------------------------------------------

  Future<List<UserModel>> getLeaderboard() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      logger.e('Error getting leaderboard', error: e);
      return [];
    }
  }

  Future<int> getUserRank(int userPoints) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('points', isGreaterThan: userPoints)
          .count()
          .get();

      return (snapshot.count ?? 0) + 1;
    } catch (e) {
      logger.e('Error getting user rank', error: e);
      return 0;
    }
  }

  Future<List<String>> _getUserListIds(String userId, String collection) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      logger.e('Error getting user list IDs for $collection', error: e);
      return [];
    }
  }

  Future<List<UserModel>> getUsersFromIdList(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }

    try {
      List<UserModel> userList = [];
      for (var i = 0; i < userIds.length; i += 30) {
        final sublist = userIds.sublist(
          i,
          i + 30 > userIds.length ? userIds.length : i + 30,
        );

        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();

        userList.addAll(
          snapshot.docs.map((doc) => UserModel.fromJson(doc.data())),
        );
      }

      return userList;
    } catch (e) {
      logger.e('Error getting users from ID list', error: e);
      return [];
    }
  }

  // 🚀 FIX 1: getFollowingList
  Future<List<UserModel>> getFollowingList(String userId) async {
    final userIds = await _getUserListIds(userId, 'following');
    return await getUsersFromIdList(userIds);
  }

  // 🚀 FIX 2: getFollowersList
  Future<List<UserModel>> getFollowersList(String userId) async {
    final userIds = await _getUserListIds(userId, 'followers');
    return await getUsersFromIdList(userIds);
  }

  // 🚀 NEW: getNotifications
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromSnapshot(doc))
          .toList();
    } catch (e, s) {
      logger.e('Error getting notifications', error: e, stackTrace: s);
      return [];
    }
  }

  // 🚀 NEW: markNotificationAsRead
  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      logger.e('Failed to mark notification as read', error: e);
    }
  }

  // 🚀 NEW: searchUsers
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      logger.e('Error searching users', error: e);
      return [];
    }
  }

  // 🚀 NEW: getFeedPosts (Filtered Global Feed)
  Future<List<PostModel>> getFeedPosts({
    String? gradeId,
    String? medium,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('status', isEqualTo: PostStatus.approved.name);

      // Apply Filters if provided
      if (gradeId != null) {
        query = query.where('gradeId', isEqualTo: gradeId);
      }
      if (medium != null) {
        query = query.where('medium', isEqualTo: medium);
      }

      // Order by creation time
      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => PostModel.fromSnapshot(doc)).toList();
    } catch (e, s) {
      logger.e('Error fetching feed posts', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get a real-time stream of feed posts
  Stream<List<PostModel>> getFeedPostsStream({
    String? gradeId,
    String? medium,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('posts')
        .where('status', isEqualTo: PostStatus.approved.name);

    if (gradeId != null) {
      query = query.where('gradeId', isEqualTo: gradeId);
    }
    if (medium != null) {
      query = query.where('medium', isEqualTo: medium);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromSnapshot(doc))
              .toList();
        });
  }

  // 🚀 NEW: followUser
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      // Add to following
      batch.set(currentUserRef.collection('following').doc(targetUserId), {
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add to followers
      batch.set(targetUserRef.collection('followers').doc(currentUserId), {
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update counts (optional, but good for performance)
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
      batch.update(targetUserRef, {'followersCount': FieldValue.increment(1)});

      await batch.commit();

      // Send notification
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
            'type': 'follow',
            'title': 'New Follower',
            'body': 'started following you',
            'fromUserId': currentUserId,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (e) {
      logger.e('Error following user', error: e);
      rethrow;
    }
  }

  // 🚀 NEW: unfollowUser
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      // Remove from following
      batch.delete(currentUserRef.collection('following').doc(targetUserId));

      // Remove from followers
      batch.delete(targetUserRef.collection('followers').doc(currentUserId));

      // Update counts
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
      });
      batch.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});

      await batch.commit();
    } catch (e) {
      logger.e('Error unfollowing user', error: e);
      rethrow;
    }
  }

  // 🚀 NEW: Search Posts
  Future<List<PostModel>> searchPosts({
    required String query,
    String? gradeId,
    String? medium,
    String? subjectId,
    List<String>? tags,
    String? contentType, // 'text', 'images', 'videos', 'polls'
    String? sortBy, // 'newest', 'popular', 'helpful'
    int limit = 50,
  }) async {
    try {
      Query queryRef = _firestore.collection('posts');

      // Apply primary filters
      if (gradeId != null) {
        queryRef = queryRef.where('gradeId', isEqualTo: gradeId);
      }
      if (medium != null) {
        queryRef = queryRef.where('medium', isEqualTo: medium);
      }
      if (subjectId != null) {
        queryRef = queryRef.where('subjectId', isEqualTo: subjectId);
      }

      // Sort logic (Firestore requires indexes for these)
      if (sortBy == 'popular') {
        queryRef = queryRef.orderBy('likeCount', descending: true);
      } else if (sortBy == 'helpful') {
        queryRef = queryRef.orderBy('helpfulAnswerCount', descending: true);
      } else {
        queryRef = queryRef.orderBy('createdAt', descending: true);
      }

      final snapshot = await queryRef.limit(limit * 2).get();

      // Filter by text search and content type in memory
      var results = snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .where((post) {
            final searchLower = query.toLowerCase();
            final matchesText =
                query.isEmpty ||
                post.text.toLowerCase().contains(searchLower) ||
                (post.subjectName?.toLowerCase().contains(searchLower) ??
                    false) ||
                (post.category.name.toLowerCase().contains(searchLower));

            final matchesTags =
                tags == null ||
                tags.isEmpty ||
                tags.any((tag) => post.tags.contains(tag.toLowerCase()));

            bool matchesType = true;
            if (contentType == 'images') {
              matchesType = post.imageUrls.isNotEmpty;
            } else if (contentType == 'videos') {
              matchesType = post.videoUrl != null;
            } else if (contentType == 'polls') {
              matchesType = post.pollData != null;
            } else if (contentType == 'text') {
              matchesType =
                  post.imageUrls.isEmpty &&
                  post.videoUrl == null &&
                  post.pollData == null;
            }

            return matchesText && matchesTags && matchesType;
          })
          .toList();

      return results.take(limit).toList();
    } catch (e, s) {
      logger.e('Error searching posts', error: e, stackTrace: s);
      return [];
    }
  }

  // 🚀 NEW: Get Trending Posts (based on engagement score)
  Future<List<PostModel>> getTrendingPosts({
    String? gradeId,
    String? medium,
    int limit = 20,
    int hours = 24, // Trending window
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
      Query query = _firestore
          .collection('posts')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffTime));

      if (gradeId != null) {
        query = query.where('gradeId', isEqualTo: gradeId);
      }
      if (medium != null) {
        query = query.where('medium', isEqualTo: medium);
      }

      final snapshot = await query
          .limit(limit * 2)
          .get(); // Get more to calculate score

      // Calculate engagement score: (likes * 2) + replies + (shares * 3) + views/10
      final posts = snapshot.docs
          .map((doc) => PostModel.fromSnapshot(doc))
          .toList();
      posts.sort((a, b) {
        final scoreA =
            (a.likeCount * 2) +
            a.replyCount +
            (a.reShareCount * 3) +
            (a.viewCount ~/ 10);
        final scoreB =
            (b.likeCount * 2) +
            b.replyCount +
            (b.reShareCount * 3) +
            (b.viewCount ~/ 10);
        return scoreB.compareTo(scoreA);
      });

      return posts.take(limit).toList();
    } catch (e, s) {
      logger.e('Error fetching trending posts', error: e, stackTrace: s);
      return [];
    }
  }

  // 🚀 NEW: Get Posts by Subject
  Future<List<PostModel>> getPostsBySubject({
    required String subjectId,
    String? gradeId,
    String? medium,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('status', isEqualTo: PostStatus.approved.name)
          .where('subjectId', isEqualTo: subjectId);

      if (gradeId != null) {
        query = query.where('gradeId', isEqualTo: gradeId);
      }
      if (medium != null) {
        query = query.where('medium', isEqualTo: medium);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => PostModel.fromSnapshot(doc)).toList();
    } catch (e, s) {
      logger.e('Error fetching posts by subject', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get a real-time stream of posts by subject
  Stream<List<PostModel>> getPostsBySubjectStream({
    required String subjectId,
    String? gradeId,
    String? medium,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('posts')
        .where('status', isEqualTo: PostStatus.approved.name)
        .where('subjectId', isEqualTo: subjectId);

    if (gradeId != null) {
      query = query.where('gradeId', isEqualTo: gradeId);
    }
    if (medium != null) {
      query = query.where('medium', isEqualTo: medium);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromSnapshot(doc))
              .toList();
        });
  }

  Stream<List<PostModel>> getPostsByCategoryStream({
    required String category,
    String? gradeId,
    String? medium,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('posts')
        .where('status', isEqualTo: PostStatus.approved.name)
        .where('category', isEqualTo: category);

    if (gradeId != null) {
      query = query.where('gradeId', isEqualTo: gradeId);
    }
    if (medium != null) {
      query = query.where('medium', isEqualTo: medium);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromSnapshot(doc))
              .toList();
        });
  }

  Stream<List<PostModel>> getPollPostsStream({
    String? gradeId,
    String? medium,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('posts')
        .where('status', isEqualTo: PostStatus.approved.name)
        .orderBy('pollData')
        .orderBy('createdAt', descending: true);

    if (gradeId != null) {
      query = query.where('gradeId', isEqualTo: gradeId);
    }
    if (medium != null) {
      query = query.where('medium', isEqualTo: medium);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromSnapshot(doc)).toList();
    });
  }

  Stream<List<PostModel>> getVerifiedPostsStream({
    String? gradeId,
    String? medium,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('posts')
        .where('status', isEqualTo: PostStatus.approved.name)
        .where('helpfulAnswerCount', isGreaterThan: 0);

    if (gradeId != null) {
      query = query.where('gradeId', isEqualTo: gradeId);
    }
    if (medium != null) {
      query = query.where('medium', isEqualTo: medium);
    }

    return query
        .orderBy('helpfulAnswerCount', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromSnapshot(doc))
              .toList();
        });
  }

  // 🚀 NEW: Mark Answer as Helpful
  Future<void> markAnswerAsHelpful({
    required String postId,
    required String replyId,
    required String userId,
    bool isHelpful = true,
  }) async {
    try {
      final replyRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('replies')
          .doc(replyId);

      if (isHelpful) {
        // Check if post author is marking (official helpful)
        final postDoc = await _firestore.collection('posts').doc(postId).get();
        final post = PostModel.fromSnapshot(postDoc);
        final isAuthor = post.authorId == userId;

        if (isAuthor) {
          // Author marking - set as official helpful answer
          await _firestore.collection('posts').doc(postId).update({
            'helpfulAnswerId': replyId,
            'helpfulAnswerCount': FieldValue.increment(1),
          });
        }

        // Add to helpful collection
        await replyRef.collection('helpful').doc(userId).set({
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Increment helpful count
        await replyRef.update({
          'helpfulCount': FieldValue.increment(1),
          if (isAuthor) 'isMarkedHelpful': true,
        });
      } else {
        // Remove helpful mark
        final postDoc = await _firestore.collection('posts').doc(postId).get();
        final post = PostModel.fromSnapshot(postDoc);
        final isAuthor = post.authorId == userId;

        if (isAuthor) {
          // Author removing - clear official helpful answer
          await _firestore.collection('posts').doc(postId).update({
            'helpfulAnswerId': null,
            'helpfulAnswerCount': FieldValue.increment(-1),
          });
        }

        await replyRef.collection('helpful').doc(userId).delete();
        await replyRef.update({
          'helpfulCount': FieldValue.increment(-1),
          if (isAuthor) 'isMarkedHelpful': false,
        });
      }
    } catch (e) {
      logger.e('Error marking answer as helpful', error: e);
      rethrow;
    }
  }
}
