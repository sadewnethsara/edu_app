# Past Papers Fetch Fix

## Problem
Past papers created in the admin panel were not showing in the mobile app. The issue was:

1. **Admin panel structure**: Stores past papers by `subjectId` in the `pastPapers` collection
2. **Mobile app expectation**: Was trying to fetch by `gradeId` directly
3. **Language mismatch**: Admin stores as "english"/"sinhala", app uses "en"/"si"

## Solution

### 1. Updated API Service (`lib/services/api_service.dart`)

#### `getPastPapers(gradeId, languageCode)` Method
Now correctly fetches past papers for a grade by:
1. Getting all subjects for the grade
2. Fetching papers for each subject using `subjectId`
3. Combining all papers from different subjects
4. Filtering by language with flexible matching
5. Sorting by year (descending)

```dart
Future<List<PastPaperModel>> getPastPapers(String gradeId, String languageCode)
```

**Key Features:**
- ✅ Fetches from all subjects in the grade
- ✅ Handles language conversion (en ↔ english, si ↔ sinhala)
- ✅ Comprehensive logging for debugging
- ✅ Error handling per subject (continues if one fails)
- ✅ Sorts by year descending

#### `getPastPapersBySubject(subjectId, languageCode)` Method
Updated to match admin panel structure:
- Queries by `subjectId` (matches admin panel POST structure)
- Orders by `year` DESC, then `uploadedAt` DESC
- Flexible language matching
- Better logging

### 2. Updated Past Papers Screen (`lib/screens/past_papers_screen.dart`)

#### Language Handling
```dart
Future<void> _loadUserLanguage()
```

**Improvements:**
- ✅ Reads user's `learningMedium` from Firestore `/users/{uid}` document
- ✅ Converts "english" → "en", "sinhala" → "si" for API calls
- ✅ Logs language conversion for debugging

#### Better Logging
```dart
Future<void> _loadPastPapers(String gradeId)
```

**Enhanced Debug Info:**
- Shows first 3 papers with full details
- Displays count summary
- Warns when no papers found
- Includes language in paper logs

## How It Works

### Data Flow

```
1. User opens Past Papers Screen
   ↓
2. Load user's learningMedium from Firestore
   (e.g., "english")
   ↓
3. Convert to language code
   ("english" → "en")
   ↓
4. Load grades for language code
   GET /curricula/en/grades
   ↓
5. Auto-select first grade
   (e.g., grade_6)
   ↓
6. Load subjects for grade
   GET /curricula/en/grades/grade_6/subjects
   ↓
7. For each subject, fetch past papers
   GET /pastPapers where subjectId == subject.id
   ↓
8. Filter papers by language
   (paper.language matches "en" or "english")
   ↓
9. Combine all papers and sort by year
   ↓
10. Display in UI
```

### Admin Panel Structure

**POST /api/admin/past-papers**
Creates papers with:
```javascript
{
  title: "2023 Final Exam",
  year: "2023",
  term: "Term 3",
  description: "Final examination paper",
  fileUrl: "https://...",
  fileSize: 1024000,
  language: "english",        // Full name
  subjectId: "mathematics",   // Key field!
  tags: ["algebra", "geometry"],
  uploadedAt: "2024-11-11T10:00:00Z",
  uploadedBy: "admin_uid"
}
```

**GET /api/admin/past-papers?subjectId=mathematics**
Queries:
```javascript
.where('subjectId', '==', subjectId)
.orderBy('year', 'desc')
.orderBy('uploadedAt', 'desc')
```

### Mobile App Query Strategy

**Option 1: By Grade (Current)**
```dart
_apiService.getPastPapers(gradeId, languageCode)
```
- Gets all subjects for grade
- Fetches papers for each subject
- Best for grade-level view

**Option 2: By Subject (Alternative)**
```dart
_apiService.getPastPapersBySubject(subjectId, languageCode)
```
- Direct query by subject
- Most efficient for subject-specific view
- Matches admin panel structure exactly

## Language Mapping

| User Setting | Stored As | API Uses | Papers Stored As | Match Logic |
|--------------|-----------|----------|------------------|-------------|
| English | `learningMedium: "english"` | `en` | `language: "english"` | ✅ Flexible |
| Sinhala | `learningMedium: "sinhala"` | `si` | `language: "sinhala"` | ✅ Flexible |

**Matching Logic:**
```dart
paperLang == targetLang ||
paperLang == 'english' && targetLang == 'en' ||
paperLang == 'sinhala' && targetLang == 'si' ||
paperLang == 'en' && targetLang == 'english' ||
paperLang == 'si' && targetLang == 'sinhala'
```

## Testing

### 1. Check Firestore Data
```javascript
// pastPapers collection should have:
{
  title: "...",
  year: "2023",
  subjectId: "mathematics",  // Must exist!
  language: "english",        // or "sinhala"
  fileUrl: "https://...",
  uploadedAt: "2024-11-11T..."
}
```

### 2. Run the App
```bash
flutter run
```

### 3. Check Console Logs
Look for:
```
🌍 User learning medium: english → Using language code: en
📚 Fetching past papers for grade: grade_6, language: en
Found 3 subjects for grade grade_6
Fetching papers for subject: Mathematics (mathematics)
Found 5 papers in database for subject mathematics
✅ After language filter: 5 papers match en
✅ Total papers loaded: 5 for grade grade_6
📄 Paper: 2023 Final Exam (2023 - Term 3) - english
```

### 4. Verify in UI
- Grade dropdown shows grades in user's language
- Papers load automatically when grade is selected
- Papers show correct titles, years, terms
- Tapping paper opens PDF

## Firestore Indexes Required

### For Efficient Queries

**Index 1: Subject + Year + Upload Time**
```json
{
  "collectionGroup": "pastPapers",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "subjectId", "order": "ASCENDING" },
    { "fieldPath": "year", "order": "DESCENDING" },
    { "fieldPath": "uploadedAt", "order": "DESCENDING" }
  ]
}
```

**Why needed:** Both admin panel GET and mobile app queries order by `year` DESC and `uploadedAt` DESC when filtering by `subjectId`.

### Deploy Indexes
```bash
firebase deploy --only firestore:indexes
```

Or create manually in Firebase Console:
1. Go to Firestore → Indexes
2. Click "Create Index"
3. Collection: `pastPapers`
4. Add fields: `subjectId` (ASC), `year` (DESC), `uploadedAt` (DESC)
5. Query scope: Collection
6. Create

## Common Issues

### Issue 1: No Papers Showing
**Check:**
1. Papers exist in Firestore `pastPapers` collection
2. Papers have correct `subjectId` (matches subject in grade)
3. Papers have correct `language` ("english" or "sinhala")
4. Subject exists in `/curricula/{lang}/grades/{gradeId}/subjects/`

**Debug:**
```dart
logger.i('Papers found: ${papers.length}');
```

### Issue 2: Language Mismatch
**Check:**
1. User's `learningMedium` in `/users/{uid}` document
2. Paper's `language` field in Firestore
3. Language conversion logs

**Fix:**
- Ensure flexible matching in `getPastPapers()` method

### Issue 3: Missing Subjects
**Check:**
1. Subjects exist in `/curricula/{lang}/grades/{gradeId}/subjects/`
2. Subjects have correct `id` field
3. Papers reference correct `subjectId`

**Debug:**
```dart
logger.i('Found ${subjects.length} subjects for grade $gradeId');
```

## API Reference

### `ApiService.getPastPapers(gradeId, languageCode)`
Fetches all past papers for a grade across all subjects.

**Parameters:**
- `gradeId`: Grade ID (e.g., "grade_6")
- `languageCode`: Language code ("en" or "si")

**Returns:** `Future<List<PastPaperModel>>`

**Example:**
```dart
final papers = await _apiService.getPastPapers('grade_6', 'en');
```

### `ApiService.getPastPapersBySubject(subjectId, languageCode)`
Fetches past papers for a specific subject.

**Parameters:**
- `subjectId`: Subject ID (e.g., "mathematics")
- `languageCode`: Language code ("en" or "si")

**Returns:** `Future<List<PastPaperModel>>`

**Example:**
```dart
final papers = await _apiService.getPastPapersBySubject('mathematics', 'en');
```

## Summary

✅ **Fixed:** Past papers now fetch correctly from admin panel structure
✅ **Language:** Handles both "english"/"sinhala" and "en"/"si" formats
✅ **Grade Selection:** Auto-selects first grade and loads papers
✅ **Logging:** Comprehensive debug logs for troubleshooting
✅ **Error Handling:** Graceful fallback if subject queries fail
✅ **Admin Panel Match:** Queries match admin panel structure exactly

The app now correctly:
1. Reads user's learning medium from settings
2. Converts language format for API calls
3. Fetches subjects for selected grade
4. Queries past papers by subject ID (admin panel structure)
5. Filters by language with flexible matching
6. Displays papers sorted by year
