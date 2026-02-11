# Firestore Structure & Index Requirements

## Database Structure Overview

The app uses a **dual structure** approach:

1. **Curriculum Hierarchy** (in `curricula/{languageCode}/`): Stores grade/subject/lesson/subtopic metadata
2. **Content Storage** (in `grades/{gradeId}/`): Stores actual content arrays (videos, notes, PDFs, resources)

### Structure Paths

```
curricula/
  ├─ en/                          (English curriculum)
  │   └─ grades/
  │       └─ {gradeId}/
  │           ├─ name, order, language, imageUrl
  │           └─ subjects/
  │               └─ {subjectId}/
  │                   ├─ name, order, language, icon
  │                   └─ lessons/
  │                       └─ {lessonId}/
  │                           ├─ name, order, language
  │                           └─ subtopics/
  │                               └─ {subtopicId}/
  │                                   └─ name, order, language
  ├─ si/                          (Sinhala curriculum)
  └─ ta/                          (Tamil curriculum)

grades/                           (Content storage - separate from curriculum)
  └─ {gradeId}/
      └─ subjects/
          └─ {subjectId}/
              └─ lessons/
                  └─ {lessonId}/
                      ├─ content/
                      │   ├─ videos[] (each item has language field)
                      │   ├─ notes[]
                      │   ├─ contentPdfs[]
                      │   └─ resources[]
                      └─ subtopics/
                          └─ {subtopicId}/
                              └─ content/ (same structure)
```

## Mobile App vs Admin Panel Indexes

### Mobile App Requirements

**✅ NO COMPOSITE INDEXES NEEDED!**

The mobile app uses simple queries that don't require composite indexes:

1. **Grades**: `curricula/{lang}/grades/` - Direct collection fetch (no where/orderBy)
2. **Subjects**: `curricula/{lang}/grades/{gId}/subjects/` - Direct collection fetch
3. **Lessons**: `curricula/{lang}/grades/{gId}/subjects/{sId}/lessons/` - Direct collection fetch
4. **Subtopics**: `curricula/{lang}/.../lessons/{lId}/subtopics/` - Direct collection fetch
5. **Content**: `grades/{gId}/subjects/{sId}/lessons/{lId}` - Direct document fetch, filters in-memory
6. **Past Papers**: Simple query with only one filter + orderBy

All sorting and filtering (by language, isActive) happens **in-memory** after fetching data.

### Admin Panel Indexes

The admin panel uses different query patterns and requires these composite indexes:

```json
{
  "indexes": [
    {
      "collectionGroup": "pastPapers",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "subjectId", "order": "ASCENDING" },
        { "fieldPath": "year", "order": "DESCENDING" },
        { "fieldPath": "uploadedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "subjects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "gradeId", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "lessons",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "subjectId", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "subtopics",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "lessonId", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Note**: The admin panel also has indexes for `content` collection with `videos.order`, `notes.order`, etc., but the mobile app doesn't query content this way - it fetches the entire content document and filters/sorts in-memory.

## Why Mobile App Doesn't Need Indexes

### 1. Language-Specific Paths
Instead of:
```dart
// ❌ Requires composite index
.collection('grades')
.where('language', isEqualTo: 'en')
.where('isActive', isEqualTo: true)
.orderBy('order')
```

Mobile app uses:
```dart
// ✅ No index needed
.collection('curricula')
.doc('en')  // Language in path
.collection('grades')
.get()
// Then sort in-memory by order
```

### 2. Direct Document Fetches
Instead of:
```dart
// ❌ Requires index
.collectionGroup('subjects')
.where('gradeId', isEqualTo: gradeId)
.orderBy('order')
```

Mobile app uses:
```dart
// ✅ No index needed
.collection('curricula')
.doc(lang)
.collection('grades')
.doc(gradeId)
.collection('subjects')
.get()
// Then sort in-memory by order
```

### 3. In-Memory Filtering
Content is fetched as a single document, then filtered by language:
```dart
final doc = await firestore
    .collection('grades')
    .doc(gradeId)
    // ... path to lesson/subtopic
    .get();

final content = doc.data()['content'];
final videos = content['videos']
    .where((v) => v['language'] == languageCode)
    .toList();
```

## Setup Instructions

### For Mobile App Development
**No action required!** The mobile app queries are designed to work without composite indexes.

### For Admin Panel
The admin panel requires the indexes listed in `firestore.indexes.json`. Deploy them using:

```bash
firebase deploy --only firestore:indexes
```

Or create them manually in Firebase Console when you see index errors.

## How to Add Indexes

### Method 1: Automatic (Recommended)
1. Run the app and try to fetch data
2. Firebase will log an error with a direct link to create the index
3. Click the link in console output
4. Firebase Console will auto-create the index

### Method 2: Manual via Firebase Console
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Enter the collection/collection group name
4. Add fields as specified above
5. Click "Create Index"

### Method 3: Using firestore.indexes.json
Create or update `firestore.indexes.json` in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "grades",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "language", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "subjects",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "language", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "lessons",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "language", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "subtopics",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "language", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "pastPapers",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "gradeId", "order": "ASCENDING" },
        { "fieldPath": "language", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "year", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy:
```bash
firebase deploy --only firestore:indexes
```

## Index Build Time
- **Small collections (<1000 docs)**: Usually 1-2 minutes
- **Medium collections (1000-10000 docs)**: 5-15 minutes
- **Large collections (>10000 docs)**: 15+ minutes

## Verification
After creating indexes, verify in Firebase Console:
1. Go to Firestore Database → Indexes
2. Wait for status to change from "Building" to "Enabled"
3. Green checkmark indicates the index is ready

## Updated API Methods

All query methods now use the new dual structure:

### Curriculum Queries (from `curricula/{languageCode}/`)
- ✅ `getGrades(languageCode)` - Fetches from `curricula/{languageCode}/grades/`
- ✅ `getSubjects(gradeId, languageCode)` - Fetches from `curricula/{languageCode}/grades/{gradeId}/subjects/`
- ✅ `getLessons(gradeId, subjectId, languageCode)` - Fetches from `curricula/{languageCode}/grades/{gradeId}/subjects/{subjectId}/lessons/`
- ✅ `getSubtopics(gradeId, subjectId, lessonId, languageCode)` - Fetches from `curricula/{languageCode}/grades/{gradeId}/subjects/{subjectId}/lessons/{lessonId}/subtopics/`

### Content Queries (from `grades/{gradeId}/`)
- ✅ `getLessonContent()` - Fetches from `grades/{gradeId}/subjects/{subjectId}/lessons/{lessonId}`, filters content items by language field
- ✅ `getSubtopicContent()` - Fetches from `grades/{gradeId}/subjects/{subjectId}/lessons/{lessonId}/subtopics/{subtopicId}`, filters content items by language field

### Other Queries
- ✅ `getPastPapers(gradeId, languageCode)` - Filters by gradeId and language with composite index

## Key Changes from Previous Structure

**Before (Old Structure):**
```dart
// Queried grades/ with .where() filters
.collection('grades')
.where('language', isEqualTo: languageCode)
.where('isActive', isEqualTo: true)
.orderBy('order')
```

**After (New Structure):**
```dart
// Fetches from language-specific path, no filters needed
.collection('curricula')
.doc(languageCode)
.collection('grades')
.get()
```

**Benefits:**
- ✅ No composite indexes needed for curriculum queries
- ✅ Cleaner separation of curriculum metadata and content
- ✅ Easier content management (content arrays in separate docs)
- ✅ Better performance (no .where() filters on curriculum)
- ✅ Each content item has its own language field for filtering

## Content Filtering

Content items are filtered by language at the app level:

```dart
List<ContentItem> filterByLanguage(List<dynamic>? items) {
  if (items == null) return [];
  return items
      .map((e) => ContentItem.fromJson(e))
      .where((item) => item.language == languageCode)
      .toList();
}
```

This allows multilingual content in the same lesson/subtopic document.

## Data Workflow

1. **Admin creates grade in English:**
   - Creates document in `curricula/en/grades/{gradeId}`
   - Includes: name, order, language: "en"

2. **Admin translates grade to Sinhala:**
   - Creates document in `curricula/si/grades/{gradeId}` (same ID)
   - Includes: name (Sinhala), order (same), language: "si"

3. **Admin adds video content:**
   - Uploads to Firebase Storage
   - Adds to `grades/{gradeId}/subjects/{sId}/lessons/{lId}/content.videos[]`
   - Content item includes: {id, name, url, language: "en", ...}

4. **Mobile app fetches:**
   - User selects "Sinhala" as learning medium
   - App fetches from `curricula/si/grades/...`
   - App fetches content from `grades/.../lessons/.../content`
   - Filters content items where language === "si"

## Verification

After updating API service, test all screens:
1. Settings screen - Select learning medium
2. Home screen - Verify grades appear
3. Subjects screen - Verify subjects load
4. Lessons screen - Verify lessons load with content counts
5. Lesson content - Verify videos/notes/PDFs load correctly
6. All Lessons screen - Verify all user's lessons appear

Check logs for:
```
Fetching grades for language: si from curricula/si/grades/
Fetched 2 grades for language: si
```
