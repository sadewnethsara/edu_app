# Past Papers Fix - Mobile App

## Issue Summary

Past papers were successfully created in the admin panel but were not showing in the mobile app. Users saw an empty state message "No past papers available" even after papers were uploaded.

## Root Causes Identified

1. **No Auto-Selection**: The app required users to manually select a grade, but provided no indication that this was necessary
2. **Insufficient Debug Logging**: No detailed logs to track what data was being fetched and filtered
3. **No URL Opening**: Buttons were placeholders that didn't actually open the PDF files

## Changes Made

### 1. Enhanced API Service (`lib/services/api_service.dart`)

**Added comprehensive debug logging:**
```dart
// Log all fetched documents before filtering
for (var doc in snapshot.docs) {
  final data = doc.data();
  logger.d(
    'Past paper doc ${doc.id}: gradeId=${data['gradeId']}, language=${data['language']}, year=${data['year']}, isActive=${data['isActive']}',
  );
}

// Warn if papers exist but don't match filters
if (papers.isEmpty && snapshot.docs.isNotEmpty) {
  logger.w(
    'Warning: Found ${snapshot.docs.length} papers but none match language=$languageCode or isActive=true',
  );
}
```

**What this helps with:**
- Identifies if papers exist in Firestore
- Shows which language/grade combinations are available
- Reveals mismatches between admin panel data and mobile app expectations

### 2. Auto-Select First Grade (`lib/screens/past_papers_screen.dart`)

**Before:**
```dart
// User had to manually select a grade - no papers shown initially
if (mounted) {
  setState(() {
    _availableGrades = grades;
    _isLoadingGrades = false;
  });
}
```

**After:**
```dart
if (mounted) {
  setState(() {
    _availableGrades = grades;
    _isLoadingGrades = false;
    
    // Auto-select first grade if available and none selected
    if (_selectedGrade == null && grades.isNotEmpty) {
      _selectedGrade = grades.first.id;
      logger.i('Auto-selected first grade: ${_selectedGrade}');
      // Load papers for the auto-selected grade
      _loadPastPapers(_selectedGrade!);
    }
  });
}
```

**Benefits:**
- Papers load immediately when screen opens
- Better user experience - no extra tap required
- Shows data right away if available

### 3. Enhanced Debug Logging in Past Papers Screen

**Added detailed logging:**
```dart
// Log all available grades
for (var grade in grades) {
  logger.d('Grade available: ${grade.id} - ${grade.name}');
}

// Log paper loading details
logger.i('Loading past papers for gradeId: $gradeId, language: $_selectedLanguage');

// Log each paper fetched
for (var paper in papers) {
  logger.d('Paper: ${paper.title} (${paper.year} - ${paper.term})');
}
```

### 4. Improved Empty State Message

**Before:**
```dart
Text(
  'No past papers available',
  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
),
```

**After:**
```dart
Text(
  _selectedGrade == null 
    ? 'Select a grade to view past papers'
    : 'No past papers available',
  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
),
if (_selectedGrade != null) ...[
  SizedBox(height: 8.h),
  Text(
    'Papers will appear here once uploaded',
    style: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
  ),
],
```

**Benefits:**
- Clearer messaging about why papers aren't showing
- Hints to users about what to expect

### 5. Functional PDF Opening

**Before:**
```dart
onPressed: () {
  // Open paper URL
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Opening paper...')),
  );
},
```

**After:**
```dart
onPressed: () async {
  try {
    final uri = Uri.parse(paper.paperUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open paper URL')),
        );
      }
    }
  } catch (e) {
    logger.e('Error opening paper URL', error: e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening paper: $e')),
      );
    }
  }
},
```

**Benefits:**
- Actually opens PDF files in external app/browser
- Handles errors gracefully
- Provides user feedback

## Testing the Fix

### 1. Check Debug Logs

Run the app with logging enabled:
```bash
flutter run
```

Look for these log messages:
```
🔍 Loaded X grades for language: english
🔍 Grade available: zH3Nk9B6A1b78IQmpM7W - Grade 1
🔍 Auto-selected first grade: zH3Nk9B6A1b78IQmpM7W
🔍 Loading past papers for gradeId: zH3Nk9B6A1b78IQmpM7W, language: english
🔍 Found X past papers for grade zH3Nk9B6A1b78IQmpM7W
🔍 Paper: 2024 Mid-Year Mathematics (2024 - First Term)
```

### 2. Verify Data in Firestore Console

Go to: https://console.firebase.google.com/project/math-world-01/firestore

Check `/pastPapers` collection:
- ✅ Documents exist with gradeId matching your app's grade IDs
- ✅ Each document has `language` field (e.g., "english", "sinhala")
- ✅ Each document has `isActive: true`
- ✅ Each document has `paperUrl` with valid URL

### 3. Test User Flow

1. Open app → Login
2. Navigate to Past Papers screen
3. **Expected:** Papers load automatically for first grade
4. Tap different grade filters → Papers update
5. Tap "Paper" button → PDF opens in browser/viewer
6. Tap "Answers" button (if available) → Answer sheet opens

## Troubleshooting

### Papers still not showing?

**Check these debug logs:**

1. **Are grades loading?**
   ```
   Loaded 0 grades for language: english
   ```
   → Problem: No grades exist for this language in Firestore

2. **Are papers in Firestore?**
   ```
   Found 0 past papers for grade zH3Nk9B6A1b78IQmpM7W
   ```
   → Problem: Papers don't exist or gradeId doesn't match

3. **Are papers being filtered out?**
   ```
   Found 5 past papers but 0 match language=english
   ```
   → Problem: Language mismatch in data

### Common Data Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| **Wrong gradeId** | Papers exist but not for selected grade | Check gradeId in admin panel matches mobile app |
| **Wrong language** | Papers filtered out | Ensure `language` field is "english" or "sinhala" (lowercase) |
| **isActive=false** | Papers hidden | Set `isActive: true` in Firestore |
| **Invalid URL** | Button doesn't open | Check `paperUrl` is valid HTTP/HTTPS URL |

## Admin Panel Data Format

When creating past papers in admin panel, ensure this structure:

```javascript
{
  "gradeId": "zH3Nk9B6A1b78IQmpM7W",  // Must match grade ID from /grades collection
  "subjectId": "URUYRjfuHn5omThsBqev", // Must match subject ID
  "year": 2024,                        // Number, not string
  "term": "First Term",                // String
  "title": "2024 Mid-Year Mathematics",
  "description": "Mathematics exam for Grade 1",
  "paperUrl": "https://...",           // Valid URL
  "answerUrl": "https://...",          // Optional, valid URL
  "language": "english",               // "english" or "sinhala" (lowercase)
  "isActive": true,                    // Must be true to show
  "uploadedAt": "2025-01-15T10:00:00Z"
}
```

## Expected Behavior After Fix

1. ✅ Past Papers screen opens → First grade auto-selected → Papers load immediately
2. ✅ Debug logs show all grades, papers, and filtering steps
3. ✅ Tapping "Paper" button opens PDF in external app
4. ✅ Empty state shows helpful message
5. ✅ Grade switching works smoothly
6. ✅ Year filtering works if multiple years exist

## Files Modified

- `lib/services/api_service.dart` - Enhanced debug logging
- `lib/screens/past_papers_screen.dart` - Auto-selection, URL opening, better UX

## Related Documentation

- `FIREBASE_STRUCTURE.md` - Firestore schema reference
- `INTEGRATION_SUMMARY.md` - Overall app integration
- `FIRESTORE_RULES.md` - Security rules for past papers
