# Past Papers Testing Guide

## Quick Test Checklist

### 1. Build and Run the App

```bash
cd c:\Users\sadew\StudioProjects\Math\math
flutter run
```

### 2. Navigate to Past Papers

1. Login to the app
2. From home screen, tap "Past Papers" button
3. Watch the console for debug logs

### 3. Expected Console Output

```
🔍 Loaded 2 grades for language: english
🔍 Grade available: zH3Nk9B6A1b78IQmpM7W - Grade 1
🔍 Grade available: 5tdxtNwojf2pHVcmRXt7 - Grade 2
🔍 Auto-selected first grade: zH3Nk9B6A1b78IQmpM7W
🔍 Loading past papers for gradeId: zH3Nk9B6A1b78IQmpM7W, language: english
🔍 Fetching past papers for grade: zH3Nk9B6A1b78IQmpM7W, language: english
🔍 Found 2 past papers for grade zH3Nk9B6A1b78IQmpM7W
🔍 Past paper doc abc123: gradeId=zH3Nk9B6A1b78IQmpM7W, language=english, year=2024, isActive=true
🔍 After filtering: 2 papers match language english
🔍 Loaded 2 past papers for grade: zH3Nk9B6A1b78IQmpM7W
🔍 Paper: 2024 Mathematics Mid-Year (2024 - First Term)
```

### 4. Test Different Languages

Switch language in app settings:
- English → Should show papers with `language: "english"`
- Sinhala → Should show papers with `language: "sinhala"`

### 5. Test Paper Opening

1. Tap "Paper" button on any card
2. PDF should open in device's default viewer
3. If error occurs, check console for URL details

### 6. Test Grade Filtering

1. Tap different grade chips at the top
2. Papers should reload for that grade
3. Check console logs confirm correct gradeId

## Debugging No Papers Showing

### Step 1: Check Firestore Data

Open Firebase Console:
```
https://console.firebase.google.com/project/math-world-01/firestore/data/pastPapers
```

Verify:
- [ ] Collection exists
- [ ] Documents have correct structure
- [ ] `gradeId` matches grade IDs in your app
- [ ] `language` field is lowercase ("english" not "English")
- [ ] `isActive` is `true` (boolean, not string)

### Step 2: Check Console Logs

Look for warning messages:

**No grades loaded:**
```
Loaded 0 grades for language: english
```
→ Fix: Add grades in admin panel for this language

**No papers found:**
```
Found 0 past papers for grade xyz
```
→ Fix: Check gradeId in pastPapers matches grades collection

**Papers filtered out:**
```
Warning: Found 5 papers but none match language=english or isActive=true
```
→ Fix: Update `language` field or set `isActive=true`

### Step 3: Verify Data Structure

Use Flutter DevTools to inspect data:

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

Check variables:
- `_selectedLanguage` = "english" or "sinhala"
- `_selectedGrade` = valid grade ID
- `_papers` = list of PastPaperModel objects
- `_filteredPapers` = filtered by year if selected

## Manual Test Scenarios

### Scenario 1: New User First Time
1. Login
2. Navigate to Past Papers
3. ✅ First grade auto-selected
4. ✅ Papers shown immediately (if they exist)
5. ✅ Empty state shows helpful message if no papers

### Scenario 2: Switch Languages
1. Go to Past Papers (English selected)
2. Note papers showing
3. Go to Settings → Change to Sinhala
4. Return to Past Papers
5. ✅ Papers reload for Sinhala language
6. ✅ Different papers shown (if Sinhala papers exist)

### Scenario 3: Switch Grades
1. Open Past Papers
2. Tap "Grade 2" chip
3. ✅ Loading indicator shows
4. ✅ Papers update for Grade 2
5. ✅ Year filter updates with new years

### Scenario 4: Filter by Year
1. View papers (multiple years exist)
2. Tap year chip (e.g., "2024")
3. ✅ Only 2024 papers shown
4. Tap "All Years"
5. ✅ All papers shown again

### Scenario 5: Open Papers
1. Tap "Paper" button
2. ✅ PDF opens in external viewer
3. Go back to app
4. Tap "Answers" button (if available)
5. ✅ Answer sheet opens

## Expected Results Summary

| Action | Expected Result | Check |
|--------|----------------|-------|
| Open Past Papers | First grade auto-selected, papers load | ⬜ |
| No papers exist | "Papers will appear here once uploaded" | ⬜ |
| Papers exist | Cards shown with title, year, term | ⬜ |
| Tap "Paper" button | PDF opens in viewer | ⬜ |
| Tap "Answers" button | Answer PDF opens | ⬜ |
| Switch grade | Papers reload for new grade | ⬜ |
| Switch language | Papers reload for new language | ⬜ |
| Filter by year | Only selected year shown | ⬜ |
| Debug logs | Detailed info in console | ⬜ |

## Common Issues and Solutions

### Issue: "No past papers available" despite data in Firestore

**Solution 1:** Check gradeId matching
```dart
// Console should show:
Grade available: zH3Nk9B6A1b78IQmpM7W - Grade 1
Loading past papers for gradeId: zH3Nk9B6A1b78IQmpM7W

// In Firestore, pastPaper document should have:
gradeId: "zH3Nk9B6A1b78IQmpM7W"  // Must match exactly
```

**Solution 2:** Check language field
```javascript
// In Firestore, should be lowercase:
language: "english"  // ✅ Correct
language: "English"  // ❌ Wrong - won't match
```

**Solution 3:** Check isActive field
```javascript
isActive: true  // ✅ Correct (boolean)
isActive: "true"  // ❌ Wrong (string)
```

### Issue: Papers don't open when tapped

**Check console for error:**
```
Error opening paper URL: Invalid URL
```

**Solution:** Ensure paperUrl is valid
```javascript
// ✅ Valid URLs:
"https://firebasestorage.googleapis.com/..."
"https://example.com/papers/math-2024.pdf"

// ❌ Invalid URLs:
"papers/math-2024.pdf"
""
null
```

### Issue: Wrong language papers showing

**Check user document:**
```javascript
// In Firestore users/{uid}:
learningMedium: "english"  // Should match paper language
appLanguage: "si"          // UI language (different from content)
```

## Performance Notes

- First load fetches all papers for a grade (no pagination yet)
- In-memory filtering by language and isActive
- In-memory filtering by year when year chip selected
- Consider pagination if >50 papers per grade

## Next Steps After Testing

If tests pass:
1. ✅ Remove debug logging or set to production level
2. ✅ Test with real data from admin panel
3. ✅ Verify on both Android and iOS
4. ✅ Test with slow network connection
5. ✅ Add analytics tracking for paper opens

If tests fail:
1. Review console logs for specific errors
2. Check Firestore data structure
3. Verify gradeId and language matching
4. See PAST_PAPERS_FIX.md for detailed troubleshooting
