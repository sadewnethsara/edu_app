# Firebase Structure Complete Reference

## Quick Overview

Your Firebase setup uses a **dual-structure approach**:

1. **Curriculum Hierarchy** (`curricula/{lang}/`) - Metadata for grades/subjects/lessons
2. **Content Storage** (`grades/{gradeId}/`) - Actual videos/notes/PDFs/resources
3. **Security Rules** - Role-based access (user, viewer, admin, super_admin)

---

## Complete Collections List

| Collection | Purpose | Mobile App Uses |
|------------|---------|-----------------|
| `/languages/{code}` | Available languages | ✅ Settings screen |
| `/curricula/{lang}/grades/...` | Curriculum metadata | ✅ All screens |
| `/grades/{gId}/subjects/.../lessons/...` | Content storage | ✅ Content screens |
| `/pastPapers/{paperId}` | Past exam papers | ✅ Past Papers screen |
| `/users/{userId}` | User profiles | ✅ Auth & Settings |
| `/publicData/{docId}` | System announcements | 🔜 Future use |
| `/curriculumLabels/{lang}` | UI labels | 🔜 Admin only |
| `/languageFonts/{lang}` | Font settings | 🔜 Admin only |
| `/avatars/{avatarId}` | Profile avatars | 🔜 Future use |
| `/content/{contentId}` | Alternative content storage | 🔜 Optional migration |

---

## Mobile App Data Flow

### 1. User Authentication
```dart
FirebaseAuth.instance.signInWithEmailAndPassword()
```
↓
Custom claims checked: `request.auth.token.role`
↓
User document read: `users/{uid}`

### 2. Language Selection (Settings)
```dart
ApiService.getLanguages()
```
↓
Fetches from: `/languages/` (where isActive=true)
↓
Saves to: `users/{uid}.learningMedium`

### 3. Grade Selection (Settings)
```dart
ApiService.getGrades(learningMedium)
```
↓
Fetches from: `/curricula/{learningMedium}/grades/`
↓
Saves to: `users/{uid}.grades[]`

### 4. Home Screen (Grades Display)
```dart
// User document already has grades array
grades = user.grades
```
↓
For each gradeId, fetch name from:
`/curricula/{learningMedium}/grades/{gradeId}`

### 5. Subjects Screen
```dart
ApiService.getSubjects(gradeId, learningMedium)
```
↓
**Primary path**: `/curricula/{learningMedium}/grades/{gradeId}/subjects/`
↓
**Fallback**: `/grades/{gradeId}/subjects/` (if primary empty)

### 6. Lessons Screen
```dart
ApiService.getLessons(gradeId, subjectId, learningMedium)
```
↓
**Metadata from**: `/curricula/{learningMedium}/grades/{gradeId}/subjects/{subjectId}/lessons/`
↓
**Content counts from**: `/grades/{gradeId}/subjects/{subjectId}/lessons/{lessonId}` (count videos/notes by language)

### 7. Lesson Content Screen
```dart
ApiService.getLessonContent(gradeId, subjectId, lessonId, learningMedium)
```
↓
Fetches from: `/grades/{gradeId}/subjects/{subjectId}/lessons/{lessonId}`
↓
Reads `content` field: `{videos: [], notes: [], contentPdfs: [], resources: []}`
↓
Filters items where `item.language === learningMedium`

### 8. Past Papers Screen
```dart
ApiService.getPastPapers(gradeId, learningMedium)
```
↓
Queries: `/pastPapers/` where gradeId matches
↓
Filters in-memory: `language === learningMedium && isActive === true`

---

## Security Rules Summary

### User Roles
- **user** - Regular students (default)
- **viewer** - Read-only access
- **admin** - Full content management
- **super_admin** - System settings access

### Access Control

| Action | user | viewer | admin | super_admin |
|--------|------|--------|-------|-------------|
| Read curriculum | ✅ | ✅ | ✅ | ✅ |
| Read own profile | ✅ | ✅ | ✅ | ✅ |
| Update own profile | ✅ (except role) | ✅ (except role) | ✅ | ✅ |
| Read past papers | ✅ | ✅ | ✅ | ✅ |
| Create/Edit content | ❌ | ❌ | ✅ | ✅ |
| Manage languages | ❌ | ❌ | ❌ | ✅ |
| Manage system settings | ❌ | ❌ | ❌ | ✅ |

---

## Firebase Indexes

### Mobile App
**NO COMPOSITE INDEXES REQUIRED** ✅

Why? The mobile app uses:
- Direct path queries (no `.where()` filters)
- In-memory sorting/filtering
- Language in path (`curricula/{lang}/`)

### Admin Panel
Requires **14 composite indexes** for:
- Collection group queries
- Multi-field filters
- Cross-language queries

See **FIRESTORE_INDEXES.md** for complete index list.

---

## Current Implementation Status

### ✅ Fully Implemented

1. **Authentication & Authorization**
   - Firebase Auth with custom claims
   - Role-based access control
   - User profile management

2. **Language Support**
   - English, Sinhala, Tamil
   - UI language (appLanguage)
   - Content language (learningMedium)
   - Separate settings for UI and content

3. **Curriculum Hierarchy**
   - Grades → Subjects → Lessons → Subtopics
   - Language-specific paths in `curricula/`
   - Fallback to `grades/` for backward compatibility

4. **Content Management**
   - Videos, notes, PDFs, resources
   - Language filtering
   - Content counts for lessons/subtopics
   - Embedded in lesson/subtopic documents

5. **Past Papers**
   - Filterable by grade and language
   - Year-based sorting
   - Active/inactive status

6. **Settings Screen**
   - Language selection
   - Grade selection
   - Sequential loading (user data → grades)

7. **All Screens Updated**
   - Settings, Home, Subjects, Lessons
   - Lesson Content, Subtopics, Past Papers
   - All use `learningMedium` for content queries

### 🔜 Future Enhancements

1. **Content Collection Migration** (optional)
   - Migrate to `/content/` collection for scalability
   - Only needed if > 100 items per lesson

2. **Public Data**
   - System announcements
   - Maintenance notices
   - Feature flags

3. **Avatar System**
   - Profile pictures
   - Custom avatars

---

## Common Issues & Solutions

### Issue 1: "No grades appearing"
**Cause**: Using wrong language field (appLanguage vs learningMedium)
**Solution**: All screens now use `learningMedium` ✅

### Issue 2: "No subjects appearing"
**Possible Causes**:
1. Grade ID mismatch between `curricula/` and `grades/`
2. Subjects only in `grades/` collection
3. User selected wrong grade

**Solutions**:
1. Check grade IDs match in both locations
2. API service has fallback to check `grades/` collection ✅
3. Reselect grade in Settings

### Issue 3: "Permission denied"
**Cause**: Custom claims not set or token not refreshed
**Solution**:
```dart
// Force token refresh
await FirebaseAuth.instance.currentUser?.getIdToken(true);
```

### Issue 4: "Composite index required"
**Cause**: Using `.where()` + `.orderBy()` on different fields
**Solution**: Mobile app already optimized to avoid this ✅

---

## Admin Panel Requirements

### Custom Claims Setup
When creating users in admin panel:

```javascript
const admin = require('firebase-admin');

// Set custom claims
await admin.auth().setCustomUserClaims(userId, {
  role: 'user'  // or 'viewer', 'admin', 'super_admin'
});
```

### User Document Creation
```javascript
await admin.firestore().collection('users').doc(userId).set({
  uid: userId,
  email: email,
  displayName: name,
  role: 'user',  // Match custom claim
  appLanguage: 'en',
  learningMedium: 'en',
  grades: [],
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  lastLogin: admin.firestore.FieldValue.serverTimestamp()
});
```

### Dual Structure Creation
When admin creates curriculum content:

**Step 1**: Create metadata in `curricula/`
```javascript
// For each language
await db.collection('curricula').doc('en').collection('grades').doc(gradeId).set({
  name: 'Grade 6',
  order: 6,
  language: 'en',
  imageUrl: '...'
});

await db.collection('curricula').doc('si').collection('grades').doc(gradeId).set({
  name: 'ශ්‍රේණිය 6',
  order: 6,
  language: 'si',
  imageUrl: '...'
});
```

**Step 2**: Create content storage in `grades/`
```javascript
await db.collection('grades').doc(gradeId).collection('subjects')
  .doc(subjectId).collection('lessons').doc(lessonId).set({
    content: {
      videos: [
        {id: 'v1', name: 'Intro', url: '...', language: 'en', order: 1},
        {id: 'v2', name: 'හැඳින්වීම', url: '...', language: 'si', order: 1}
      ],
      notes: [...],
      contentPdfs: [...],
      resources: [...]
    }
  });
```

---

## Testing Checklist

After any Firebase changes, test:

- [ ] User can sign in
- [ ] Languages load in Settings
- [ ] Grades load in Settings (after selecting language)
- [ ] Home screen shows selected grades
- [ ] Subjects load for each grade
- [ ] Lessons load for each subject
- [ ] Lesson content shows videos/notes/PDFs
- [ ] Content filters by language correctly
- [ ] Past papers load and filter by language
- [ ] All Lessons screen shows all user's lessons
- [ ] No console errors
- [ ] Logs show correct paths being queried

---

## Documentation Files

| File | Purpose |
|------|---------|
| `FIRESTORE_RULES.md` | Complete security rules explanation |
| `FIRESTORE_INDEXES.md` | Index requirements (mobile vs admin) |
| `CONTENT_STORAGE_OPTIONS.md` | Content storage comparison (embedded vs separate) |
| `DIAGNOSIS.md` | Troubleshooting grade ID mismatch |
| `FIREBASE_STRUCTURE.md` | This file - complete reference |

---

## Quick Commands

### Check Logs in App
```dart
// In any screen
debugPrint('🔍 Current language: $_selectedLanguage');
```

### Firebase Console Queries
```javascript
// Check grade IDs in curricula
db.collection('curricula').doc('en').collection('grades').get()

// Check grade IDs in grades
db.collection('grades').get()

// Check user's selected grades
db.collection('users').doc(userId).get().then(doc => {
  console.log(doc.data().grades);
})

// Check subjects for a grade
db.collection('curricula').doc('en').collection('grades')
  .doc(gradeId).collection('subjects').get()
```

---

## Contact & Support

If you encounter issues:

1. Check **DIAGNOSIS.md** for common problems
2. Review logs in VSCode Debug Console
3. Verify Firebase structure in console
4. Check security rules in Firebase Console → Firestore → Rules
5. Verify indexes in Firebase Console → Firestore → Indexes

---

## Summary

Your Firebase structure is **well-designed** with:
- ✅ Clean separation of curriculum metadata and content
- ✅ Language-specific organization
- ✅ Secure role-based access control
- ✅ Efficient queries (no composite indexes for mobile)
- ✅ Scalable architecture
- ✅ Backward compatibility with fallback logic

**Mobile app is fully aligned with this structure!** 🎉
