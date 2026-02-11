# Content Storage Options

## Overview

Your updated Firestore rules include a `/content/{contentId}` collection. This document explains:
1. **Current Implementation** (Option A)
2. **New Implementation** (Option B) 
3. **Which One to Choose**
4. **Migration Guide**

---

## Option A: Current Implementation (Embedded Content)

### Structure
Content is stored **inside** lesson/subtopic documents:

```
grades/
  └─ {gradeId}/
      └─ subjects/
          └─ {subjectId}/
              └─ lessons/
                  └─ {lessonId}/
                      ├─ content: {
                      │   ├─ videos: [
                      │   │   {id, name, url, language, order, ...},
                      │   │   {id, name, url, language, order, ...}
                      │   │ ],
                      │   ├─ notes: [...],
                      │   ├─ contentPdfs: [...],
                      │   └─ resources: [...]
                      │ }
                      └─ subtopics/
                          └─ {subtopicId}/
                              └─ content: { ... }
```

### Current API Code
```dart
// lib/services/api_service.dart
Future<ContentCollection?> getLessonContent(
  String gradeId,
  String subjectId,
  String lessonId,
  String languageCode,
) async {
  final doc = await _firestore
      .collection('grades')
      .doc(gradeId)
      .collection('subjects')
      .doc(subjectId)
      .collection('lessons')
      .doc(lessonId)
      .get();

  final data = doc.data()!;
  final content = data['content'] as Map<String, dynamic>?;

  // Filter content by language
  final videos = (content?['videos'] as List?)
      ?.map((e) => ContentItem.fromJson(e))
      .where((item) => item.language == languageCode)
      .toList() ?? [];

  return ContentCollection(
    videos: videos,
    notes: notes,
    contentPdfs: contentPdfs,
    resources: resources,
  );
}
```

### Pros ✅
- ✅ **Simple structure** - All content for a lesson in one document
- ✅ **Single read** - Fetch all content types at once
- ✅ **No additional queries** - Efficient for small content arrays
- ✅ **Currently working** - Already implemented

### Cons ❌
- ❌ **Document size limit** - Firestore documents are limited to 1MB
- ❌ **Large arrays** - 100+ videos/notes in one document gets unwieldy
- ❌ **Scalability** - Hard to manage large amounts of content
- ❌ **No per-item queries** - Can't easily query specific videos across lessons

---

## Option B: New Implementation (Separate Content Collection)

### Structure
Content stored in separate `/content/` collection with references:

```
content/
  └─ {contentId}/  (e.g., "lesson_gradeId_subjectId_lessonId")
      ├─ type: "lesson" | "subtopic"
      ├─ gradeId: "gradeId"
      ├─ subjectId: "subjectId"
      ├─ lessonId: "lessonId"
      ├─ subtopicId: "subtopicId" (optional, if type=subtopic)
      ├─ language: "en"
      ├─ videos: [...]
      ├─ notes: [...]
      ├─ contentPdfs: [...]
      └─ resources: [...]
```

**OR** even more granular (one document per content item):

```
content/
  ├─ video_xyz123/
  │   ├─ type: "video"
  │   ├─ gradeId: "gradeId"
  │   ├─ subjectId: "subjectId"
  │   ├─ lessonId: "lessonId"
  │   ├─ language: "en"
  │   ├─ name: "Introduction to Algebra"
  │   ├─ url: "https://..."
  │   └─ order: 1
  ├─ note_abc456/
  │   ├─ type: "note"
  │   ├─ ...
  └─ pdf_def789/
      └─ ...
```

### New API Code (Per-Lesson Content Document)

```dart
// lib/services/api_service.dart

/// Fetch lesson content from /content/ collection
Future<ContentCollection?> getLessonContent(
  String gradeId,
  String subjectId,
  String lessonId,
  String languageCode,
) async {
  try {
    logger.i(
      'Fetching lesson content for lesson: $lessonId, language: $languageCode from /content/',
    );

    // Construct content document ID
    // Format: lesson_{gradeId}_{subjectId}_{lessonId}_{language}
    final contentId = 'lesson_${gradeId}_${subjectId}_${lessonId}_$languageCode';

    final doc = await _firestore
        .collection('content')
        .doc(contentId)
        .get();

    if (!doc.exists) {
      logger.w('Content document does not exist: $contentId');
      return ContentCollection(
        videos: [],
        notes: [],
        contentPdfs: [],
        resources: [],
      );
    }

    final data = doc.data()!;

    // Parse content arrays (already language-specific)
    final videos = (data['videos'] as List?)
            ?.map((e) => ContentItem.fromJson(e))
            .toList() ??
        [];

    final notes = (data['notes'] as List?)
            ?.map((e) => ContentItem.fromJson(e))
            .toList() ??
        [];

    final contentPdfs = (data['contentPdfs'] as List?)
            ?.map((e) => ContentItem.fromJson(e))
            .toList() ??
        [];

    final resources = (data['resources'] as List?)
            ?.map((e) => ContentItem.fromJson(e))
            .toList() ??
        [];

    logger.i('Fetched ${videos.length} videos, ${notes.length} notes for lesson $lessonId');

    return ContentCollection(
      videos: videos,
      notes: notes,
      contentPdfs: contentPdfs,
      resources: resources,
    );
  } catch (e, s) {
    logger.e(
      'Error fetching lesson content for lesson: $lessonId',
      error: e,
      stackTrace: s,
    );
    return null;
  }
}

/// Fetch subtopic content from /content/ collection
Future<ContentCollection?> getSubtopicContent(
  String gradeId,
  String subjectId,
  String lessonId,
  String subtopicId,
  String languageCode,
) async {
  try {
    logger.i(
      'Fetching subtopic content for subtopic: $subtopicId, language: $languageCode from /content/',
    );

    // Construct content document ID
    // Format: subtopic_{gradeId}_{subjectId}_{lessonId}_{subtopicId}_{language}
    final contentId = 'subtopic_${gradeId}_${subjectId}_${lessonId}_${subtopicId}_$languageCode';

    final doc = await _firestore
        .collection('content')
        .doc(contentId)
        .get();

    if (!doc.exists) {
      logger.w('Content document does not exist: $contentId');
      return ContentCollection(
        videos: [],
        notes: [],
        contentPdfs: [],
        resources: [],
      );
    }

    final data = doc.data()!;

    final videos = (data['videos'] as List?)
            ?.map((e) => ContentItem.fromJson(e))
            .toList() ??
        [];

    final notes = (data['notes'] as List?)
            ?.map((e) => ContentItem.fromJson(e))
            .toList() ??
        [];

    final contentPdfs = (data['contentPdfs'] as List?)
            ?.map((e) => ContentItem.fromJson(e))
            .toList() ??
        [];

    final resources = (data['resources'] as List?)
            ?.map((e) => ContentItem.fromJson(e))
            .toList() ??
        [];

    logger.i('Fetched ${videos.length} videos, ${notes.length} notes for subtopic $subtopicId');

    return ContentCollection(
      videos: videos,
      notes: notes,
      contentPdfs: contentPdfs,
      resources: resources,
    );
  } catch (e, s) {
    logger.e(
      'Error fetching subtopic content for subtopic: $subtopicId',
      error: e,
      stackTrace: s,
    );
    return null;
  }
}
```

### New API Code (Per-Item Granular Approach)

```dart
/// Fetch lesson content from /content/ collection (per-item documents)
Future<ContentCollection?> getLessonContent(
  String gradeId,
  String subjectId,
  String lessonId,
  String languageCode,
) async {
  try {
    logger.i(
      'Fetching lesson content items for lesson: $lessonId, language: $languageCode',
    );

    // Query all content items for this lesson
    final snapshot = await _firestore
        .collection('content')
        .where('gradeId', isEqualTo: gradeId)
        .where('subjectId', isEqualTo: subjectId)
        .where('lessonId', isEqualTo: lessonId)
        .where('language', isEqualTo: languageCode)
        .get();

    logger.i('Found ${snapshot.docs.length} content items for lesson $lessonId');

    // Separate items by type
    final videos = <ContentItem>[];
    final notes = <ContentItem>[];
    final contentPdfs = <ContentItem>[];
    final resources = <ContentItem>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final item = ContentItem.fromJson(data);

      switch (data['type']) {
        case 'video':
          videos.add(item);
          break;
        case 'note':
          notes.add(item);
          break;
        case 'pdf':
          contentPdfs.add(item);
          break;
        case 'resource':
          resources.add(item);
          break;
      }
    }

    // Sort by order
    videos.sort((a, b) => a.order.compareTo(b.order));
    notes.sort((a, b) => a.order.compareTo(b.order));
    contentPdfs.sort((a, b) => a.order.compareTo(b.order));
    resources.sort((a, b) => a.order.compareTo(b.order));

    return ContentCollection(
      videos: videos,
      notes: notes,
      contentPdfs: contentPdfs,
      resources: resources,
    );
  } catch (e, s) {
    logger.e(
      'Error fetching lesson content for lesson: $lessonId',
      error: e,
      stackTrace: s,
    );
    return null;
  }
}
```

### Pros ✅
- ✅ **Scalability** - No document size limits
- ✅ **Flexibility** - Can query content across lessons
- ✅ **Modularity** - Each content type can be managed separately
- ✅ **Better for large content** - Handles 1000+ videos easily
- ✅ **Advanced queries** - Can search for specific videos, popular content, etc.

### Cons ❌
- ❌ **More complex** - Requires careful document ID management
- ❌ **Multiple reads** - May need multiple queries for different content types
- ❌ **Migration needed** - Existing data must be moved
- ❌ **Composite indexes** - Per-item approach requires indexes for queries with multiple filters

---

## Recommended Approach

### 🎯 **Stick with Option A (Current)** if:
- ✅ Your lessons have **< 50 content items** each
- ✅ You want **simple, fast queries**
- ✅ You don't need to **search across lessons**
- ✅ Your current implementation **works fine**

### 🚀 **Migrate to Option B** if:
- ✅ You have lessons with **100+ videos/notes**
- ✅ You're hitting **document size limits** (1MB)
- ✅ You want to **query content globally** (e.g., "show all videos by teacher X")
- ✅ You need **content recommendations** across lessons
- ✅ Your admin panel creates content frequently and needs scalability

---

## My Recommendation

**Stick with Option A (Current Implementation)** for now because:

1. ✅ **It's already working** - No migration needed
2. ✅ **Simple structure** - Easier to maintain
3. ✅ **Efficient** - Single document read per lesson
4. ✅ **No indexes needed** - Avoids composite index complexity

**When to migrate to Option B:**
- When you hit the 1MB document size limit
- When you have 100+ content items per lesson
- When you need advanced content queries (search, analytics, recommendations)

---

## How to Check Current Content Size

Run this query in Firebase Console to check your largest content documents:

```javascript
// In Firestore Console, run this in the Console tab
const snapshot = await db.collectionGroup('lessons').get();
snapshot.docs.forEach(doc => {
  const data = doc.data();
  const content = data.content;
  if (content) {
    const videoCount = content.videos?.length || 0;
    const noteCount = content.notes?.length || 0;
    const pdfCount = content.contentPdfs?.length || 0;
    const resourceCount = content.resources?.length || 0;
    const total = videoCount + noteCount + pdfCount + resourceCount;
    
    if (total > 20) {
      console.log(`Lesson ${doc.id}: ${total} items (${videoCount}v, ${noteCount}n, ${pdfCount}p, ${resourceCount}r)`);
    }
  }
});
```

If you see lessons with **> 100 total items**, consider migrating to Option B.

---

## Migration Guide (If You Choose Option B)

### Step 1: Create Migration Script

```javascript
// migrate_content.js
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function migrateContent() {
  // Get all lessons
  const gradesSnapshot = await db.collection('grades').get();
  
  for (const gradeDoc of gradesSnapshot.docs) {
    const gradeId = gradeDoc.id;
    const subjectsSnapshot = await gradeDoc.ref.collection('subjects').get();
    
    for (const subjectDoc of subjectsSnapshot.docs) {
      const subjectId = subjectDoc.id;
      const lessonsSnapshot = await subjectDoc.ref.collection('lessons').get();
      
      for (const lessonDoc of lessonsSnapshot.docs) {
        const lessonId = lessonDoc.id;
        const lessonData = lessonDoc.data();
        const content = lessonData.content;
        
        if (content) {
          // Group content by language
          const contentByLanguage = {};
          
          ['videos', 'notes', 'contentPdfs', 'resources'].forEach(type => {
            if (content[type]) {
              content[type].forEach(item => {
                const lang = item.language || 'en';
                if (!contentByLanguage[lang]) {
                  contentByLanguage[lang] = {
                    videos: [],
                    notes: [],
                    contentPdfs: [],
                    resources: []
                  };
                }
                contentByLanguage[lang][type].push(item);
              });
            }
          });
          
          // Create content documents per language
          for (const [lang, langContent] of Object.entries(contentByLanguage)) {
            const contentId = `lesson_${gradeId}_${subjectId}_${lessonId}_${lang}`;
            
            await db.collection('content').doc(contentId).set({
              type: 'lesson',
              gradeId,
              subjectId,
              lessonId,
              language: lang,
              videos: langContent.videos,
              notes: langContent.notes,
              contentPdfs: langContent.contentPdfs,
              resources: langContent.resources,
              migratedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            
            console.log(`Migrated content for ${contentId}`);
          }
        }
        
        // Do the same for subtopics
        const subtopicsSnapshot = await lessonDoc.ref.collection('subtopics').get();
        // ... similar logic for subtopics
      }
    }
  }
  
  console.log('Migration complete!');
}

migrateContent();
```

### Step 2: Update API Service

Replace the content methods in `lib/services/api_service.dart` with the new Option B code above.

### Step 3: Test Thoroughly

1. Test lesson content loading
2. Test subtopic content loading
3. Verify all content types (videos, notes, PDFs, resources)
4. Check language filtering works correctly

### Step 4: Clean Up Old Data (After Verification)

Once confirmed working, remove old `content` fields from lesson/subtopic documents.

---

## Summary

**Current Status**: Your app uses **Option A** (embedded content in lesson/subtopic documents)

**Security Rules**: You've added `/content/` collection rules, but **you don't need to migrate** unless you have scalability issues.

**Recommendation**: **Keep Option A** unless you have:
- 100+ content items per lesson
- Document size warnings
- Need for advanced content queries

Your current implementation is **working correctly** and is **efficient** for typical use cases! 🎉
