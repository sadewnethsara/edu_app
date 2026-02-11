# Quick Start Guide - Using the New Features

## 1. Testing the Language Selection

After login, users should see the language selection screen:

```dart
// The language selection is automatic after first login
// To manually test, navigate to:
context.go('/language-selection');
```

## 2. Using the API Service

```dart
import 'package:math/services/api_service.dart';

final apiService = ApiService();

// Get available languages
final languages = await apiService.getLanguages();

// Get grades in English
final grades = await apiService.getGrades('en');

// Get subjects for a grade
final subjects = await apiService.getSubjects('grade-1', 'en');

// Get lessons for a subject
final lessons = await apiService.getLessons('grade-1', 'subject-math', 'en');

// Get lesson content
final content = await apiService.getLessonContent(
  'grade-1',
  'subject-math',
  'lesson-addition',
  'en',
);

// Access content types
print('Videos: ${content?.videos.length}');
print('Notes: ${content?.notes.length}');
```

## 3. Navigation Examples

```dart
// Navigate to subjects for Grade 1
context.push('/subjects/grade-1');

// Navigate to lessons
context.push('/subjects/grade-1/subject-math');

// Navigate to lesson content
context.push('/subjects/grade-1/subject-math/lessons/lesson-addition');

// Navigate to subtopics
context.push('/subjects/grade-1/subject-math/lessons/lesson-addition/subtopics');

// Navigate to past papers
context.push('/past-papers');
```

## 4. Getting User's Selected Language

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  
  final preferences = userDoc.data()?['preferences'] as Map<String, dynamic>?;
  final language = preferences?['language'] as String? ?? 'en';
  
  print('User language: $language');
}
```

## 5. Sample Firestore Data Structure

### Languages Collection
```json
{
  "en": {
    "code": "en",
    "label": "English",
    "nativeName": "English",
    "isActive": true,
    "order": 1
  },
  "si": {
    "code": "si",
    "label": "Sinhala",
    "nativeName": "සිංහල",
    "isActive": true,
    "order": 2
  }
}
```

### Grades Collection
```json
{
  "grade-1": {
    "order": 1,
    "isActive": true,
    "translations": {
      "en": {
        "name": "Grade 1",
        "description": "First grade mathematics"
      },
      "si": {
        "name": "ශ්‍රේණිය 1",
        "description": "පළමු ශ්‍රේණියේ ගණිතය"
      }
    }
  }
}
```

### Subjects Subcollection
```json
{
  "grades/grade-1/subjects/subject-math": {
    "order": 1,
    "icon": "calculator",
    "isActive": true,
    "translations": {
      "en": {
        "name": "Mathematics",
        "description": "Core mathematics concepts"
      },
      "si": {
        "name": "ගණිතය",
        "description": "මූලික ගණිත සංකල්ප"
      }
    }
  }
}
```

### Lessons with Content
```json
{
  "grades/grade-1/subjects/subject-math/lessons/lesson-addition": {
    "order": 1,
    "isActive": true,
    "translations": {
      "en": {
        "name": "Addition Basics",
        "description": "Learn basic addition"
      }
    },
    "content": {
      "videos": [
        {
          "id": "video-1",
          "name": "Introduction Video",
          "url": "https://youtube.com/watch?v=xxx",
          "type": "url",
          "language": "en",
          "thumbnail": "https://...",
          "uploadedAt": "2025-01-01T00:00:00Z",
          "description": "Basic addition intro",
          "tags": ["addition", "basics"]
        }
      ],
      "notes": [],
      "contentPdfs": [],
      "resources": []
    }
  }
}
```

## 6. Customizing Colors

Edit `lib/theme/app_theme.dart`:

```dart
// Change primary color (yellow)
static const Color _primaryYellow = Color(0xFFFFD300);

// Change secondary color (navy)
static const Color _secondaryBlue = Color(0xFF0B1C2C);
```

Or in individual screens, edit the color arrays:

```dart
// In _GradeCard widget
final colors = [
  Colors.blue,      // Change these
  Colors.purple,
  Colors.green,
  // Add more colors
];
```

## 7. Adding More Content Types

To add a new content type (e.g., "Exercises"):

1. Update `ContentCollection` in `lib/data/models/content_model.dart`:
```dart
class ContentCollection {
  final List<ContentItem> videos;
  final List<ContentItem> notes;
  final List<ContentItem> contentPdfs;
  final List<ContentItem> resources;
  final List<ContentItem> exercises; // Add this

  // Update constructor and fromJson
}
```

2. Update API Service to fetch exercises
3. Add new tab in `LessonContentScreen`

## 8. Implementing Progress Tracking

Add to user document:
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .set({
  'progress': {
    'grade-1': {
      'subject-math': {
        'lesson-addition': {
          'completed': true,
          'progress': 100,
          'lastViewed': FieldValue.serverTimestamp(),
        }
      }
    }
  }
}, SetOptions(merge: true));
```

Query progress:
```dart
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

final progress = userDoc.data()?['progress'] as Map<String, dynamic>?;
final lessonProgress = progress?['grade-1']?['subject-math']?['lesson-addition'];
final isCompleted = lessonProgress?['completed'] ?? false;
```

## 9. Testing Checklist

Run these tests in order:

1. **Language Selection**
   - [ ] Open app after fresh install
   - [ ] Complete onboarding
   - [ ] See language selection screen
   - [ ] Select a language
   - [ ] Check Firestore for saved preference

2. **Home Dashboard**
   - [ ] See grades listed
   - [ ] See streak badge
   - [ ] Tap a grade card

3. **Subjects**
   - [ ] See subject cards
   - [ ] Colors are vibrant
   - [ ] Tap a subject

4. **Lessons**
   - [ ] See numbered lessons
   - [ ] First lesson is unlocked
   - [ ] Content badges show
   - [ ] Tap first lesson

5. **Content Viewer**
   - [ ] Tabs load correctly
   - [ ] Content cards appear
   - [ ] Tap a video/PDF
   - [ ] URL opens externally

6. **Past Papers**
   - [ ] Select a grade filter
   - [ ] Papers appear
   - [ ] Year filter works
   - [ ] Tap paper/answer button

## 10. Common Issues & Fixes

### Issue: No grades showing
**Fix:** Check Firestore has `grades` collection with `isActive: true`

### Issue: Language not changing
**Fix:** Verify `LanguageService` is provided in main.dart and locale is being read

### Issue: Content not loading
**Fix:** 
1. Check Firestore rules allow read access
2. Verify content has correct `language` field
3. Check user's selected language matches content language

### Issue: Navigation error
**Fix:** Verify path parameters in router match actual IDs from Firestore

### Issue: URL launcher not working
**Fix:**
- Android: Add to `AndroidManifest.xml`:
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```
- iOS: Add to `Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
</array>
```

## 11. Performance Tips

1. **Use cached_network_image** for thumbnails (already imported)
2. **Limit query results** if you have many lessons:
```dart
.limit(20)
```
3. **Use Firebase indexes** for complex queries
4. **Enable offline persistence** (already enabled in main.dart)

## 12. Deployment Checklist

Before releasing:
- [ ] Test all screens on different devices
- [ ] Test with all three languages
- [ ] Verify all Firestore rules are set correctly
- [ ] Test with slow internet connection
- [ ] Test offline mode
- [ ] Update app version in pubspec.yaml
- [ ] Create release build: `flutter build apk --release`
- [ ] Test release build thoroughly

---

**Need Help?**
- Check INTEGRATION_SUMMARY.md for detailed documentation
- Review the database structure document
- Check Flutter errors in debug console
- Verify Firestore data structure matches expected format
