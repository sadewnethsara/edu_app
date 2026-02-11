# Past Papers Fix - Quick Reference

## What Changed

### 1. ApiService (`lib/services/api_service.dart`)

#### Before:
- Tried to query `pastPapers` by `gradeId` field (doesn't exist in admin panel structure)
- Simple language comparison (exact match only)

#### After:
- ✅ Queries by `subjectId` (matches admin panel)
- ✅ Gets all subjects for grade first, then fetches papers per subject
- ✅ Flexible language matching (en ↔ english, si ↔ sinhala)
- ✅ Enhanced logging with emojis for easy debugging
- ✅ Error handling per subject (continues on failure)

### 2. Past Papers Screen (`lib/screens/past_papers_screen.dart`)

#### Before:
- Used `learningMedium` directly without conversion

#### After:
- ✅ Converts "english" → "en", "sinhala" → "si"
- ✅ Better logging for language selection
- ✅ Shows sample papers in debug logs
- ✅ Warns when no papers found

## Testing Steps

### 1. Quick Test
```bash
flutter run
```

1. Navigate to Past Papers screen
2. Check console for logs:
   - `🌍 User learning medium: english → Using language code: en`
   - `📚 Fetching past papers for grade: grade_6`
   - `✅ Total papers loaded: X for grade grade_6`
3. Select different grades from dropdown
4. Verify papers load correctly

### 2. Debug Logs to Look For

**Success:**
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

**No Papers:**
```
⚠️ No past papers found for grade grade_6 in language en
```

### 3. Common Fixes

**If no papers show:**
1. Check Firestore: `pastPapers` collection exists
2. Verify paper has `subjectId` field matching a subject in the grade
3. Verify paper has `language: "english"` or `language: "sinhala"`
4. Check subject exists in `/curricula/en/grades/grade_6/subjects/`

**If language mismatch:**
1. Check user document: `/users/{uid}` → `learningMedium` field
2. Should be "english" or "sinhala" (lowercase)
3. App converts to "en" or "si" automatically

## Admin Panel Integration

### When creating a paper in admin panel:
```javascript
POST /api/admin/past-papers
{
  "title": "2023 Final Exam",
  "year": "2023",
  "term": "Term 3",
  "language": "english",      // ← Important: use full name
  "subjectId": "mathematics", // ← Critical: must match subject ID
  "fileUrl": "https://...",
  ...
}
```

### Mobile app will:
1. Get user's `learningMedium` → Convert to "en"
2. Load subjects for grade → Find "mathematics" subject
3. Query `pastPapers` where `subjectId == "mathematics"`
4. Filter where `language == "english"` (matches "en" flexibly)
5. Display papers

## Key Files Modified

1. ✅ `lib/services/api_service.dart`
   - `getPastPapers()` method
   - `getPastPapersBySubject()` method

2. ✅ `lib/screens/past_papers_screen.dart`
   - `_loadUserLanguage()` method
   - `_loadPastPapers()` method

3. ✅ `PAST_PAPERS_FETCH_FIX.md` (documentation)

## Firestore Index Needed

If you see "index required" error:

```json
{
  "collectionGroup": "pastPapers",
  "fields": [
    { "fieldPath": "subjectId", "order": "ASCENDING" },
    { "fieldPath": "year", "order": "DESCENDING" },
    { "fieldPath": "uploadedAt", "order": "DESCENDING" }
  ]
}
```

Deploy: `firebase deploy --only firestore:indexes`

## Next Steps

1. ✅ Code changes complete
2. ⏳ Test app: `flutter run`
3. ⏳ Verify papers load for each grade
4. ⏳ Test PDF opening
5. ⏳ Deploy Firestore index if needed
6. ⏳ Test language switching (English ↔ Sinhala)

## Support

If issues persist, check logs for:
- Subject count per grade
- Paper count per subject
- Language matching results
- Any error messages

All methods include comprehensive logging for debugging.
