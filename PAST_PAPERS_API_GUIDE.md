# Past Papers API Guide

## Overview

The Past Papers API provides multiple methods to fetch past exam papers from Firestore with support for filtering by subject, grade, year, term, and tags. This implementation matches the admin panel's data structure and provides efficient querying.

---

## Data Model

### PastPaperModel

```dart
class PastPaperModel {
  final String id;
  final String gradeId;
  final String subjectId;
  final String year;           // String type (e.g., "2024", "2023")
  final String? term;          // Optional (e.g., "First Term", "Mid-Year")
  final String title;
  final String description;
  final String fileUrl;        // Main paper URL
  final String? answerUrl;     // Optional answer sheet URL
  final int? fileSize;         // File size in bytes
  final String language;       // "english" or "sinhala" (lowercase)
  final String uploadedAt;     // ISO timestamp
  final bool isActive;         // Must be true to show in app
  final List<String>? tags;    // Optional tags array
}
```

### Available Tags

- `"School Past Paper"`
- `"Class Past Paper"`
- `"Zone Past Paper"`
- `"Provincial Past Paper"`

---

## API Methods

### 1. Get Past Papers by Grade (Legacy - Still Supported)

**Use case:** Fetch all papers for a grade across all subjects

```dart
Future<List<PastPaperModel>> getPastPapers(
  String gradeId,
  String languageCode,
)
```

**Example:**
```dart
final papers = await apiService.getPastPapers(
  'zH3Nk9B6A1b78IQmpM7W',  // Grade ID
  'english',                // Language code
);
```

**Query:**
- Collection: `pastPapers`
- Filter: `gradeId == gradeId`
- Order: `year DESC`
- In-memory filter: `language == languageCode && isActive == true`

---

### 2. Get Past Papers by Subject (RECOMMENDED) ⭐

**Use case:** Most efficient method for fetching papers for a specific subject

```dart
Future<List<PastPaperModel>> getPastPapersBySubject(
  String subjectId,
  String languageCode,
)
```

**Example:**
```dart
final papers = await apiService.getPastPapersBySubject(
  'URUYRjfuHn5omThsBqev',  // Subject ID
  'english',                // Language code
);
```

**Query:**
- Collection: `pastPapers`
- Filter: `subjectId == subjectId`
- Order: `year DESC, uploadedAt DESC`
- In-memory filter: `language == languageCode && isActive == true`

**Required Index:**
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

---

### 3. Get Past Papers by Year

**Use case:** Filter papers for a specific year and subject

```dart
Future<List<PastPaperModel>> getPastPapersByYear(
  String subjectId,
  String languageCode,
  String year,
)
```

**Example:**
```dart
final papers = await apiService.getPastPapersByYear(
  'URUYRjfuHn5omThsBqev',
  'english',
  '2024',  // Year as string
);
```

**Query:**
- Collection: `pastPapers`
- Filter: `subjectId == subjectId && year == year`
- Order: `uploadedAt DESC`
- In-memory filter: `language == languageCode && isActive == true`

---

### 4. Get Past Papers by Term

**Use case:** Filter papers for a specific term (e.g., "First Term", "Mid-Year")

```dart
Future<List<PastPaperModel>> getPastPapersByTerm(
  String subjectId,
  String languageCode,
  String term,
)
```

**Example:**
```dart
final papers = await apiService.getPastPapersByTerm(
  'URUYRjfuHn5omThsBqev',
  'english',
  'First Term',
);
```

**Query:**
- Collection: `pastPapers`
- Filter: `subjectId == subjectId`
- Order: `year DESC`
- In-memory filter: `language == languageCode && isActive == true && term == term`

---

### 5. Get Past Papers by Tag

**Use case:** Filter papers by tag type (e.g., "Provincial Past Paper")

```dart
Future<List<PastPaperModel>> getPastPapersByTag(
  String subjectId,
  String languageCode,
  String tag,
)
```

**Example:**
```dart
final papers = await apiService.getPastPapersByTag(
  'URUYRjfuHn5omThsBqev',
  'english',
  'Provincial Past Paper',
);
```

**Query:**
- Collection: `pastPapers`
- Filter: `subjectId == subjectId && tags array-contains tag`
- Order: `year DESC`
- In-memory filter: `language == languageCode && isActive == true`

---

## Helper Methods

### Get Available Years

```dart
Future<List<String>> getAvailableYears(String subjectId)
```

Returns list of available years for a subject (sorted descending).

**Example:**
```dart
final years = await apiService.getAvailableYears('URUYRjfuHn5omThsBqev');
// Returns: ['2024', '2023', '2022', ...]
```

---

### Get Available Terms

```dart
Future<List<String>> getAvailableTerms(String subjectId)
```

Returns list of available terms for a subject (sorted ascending).

**Example:**
```dart
final terms = await apiService.getAvailableTerms('URUYRjfuHn5omThsBqev');
// Returns: ['First Term', 'Mid-Year', 'Third Term', ...]
```

---

### Get Available Tags

```dart
Future<List<String>> getAvailableTags(String subjectId)
```

Returns list of all tags used in papers for a subject (sorted ascending).

**Example:**
```dart
final tags = await apiService.getAvailableTags('URUYRjfuHn5omThsBqev');
// Returns: ['Provincial Past Paper', 'School Past Paper', ...]
```

---

## Usage Examples

### Example 1: Display Past Papers by Subject (Most Common)

```dart
class SubjectPastPapersScreen extends StatefulWidget {
  final String subjectId;
  final String languageCode;
  
  @override
  _SubjectPastPapersScreenState createState() => _SubjectPastPapersScreenState();
}

class _SubjectPastPapersScreenState extends State<SubjectPastPapersScreen> {
  final ApiService _apiService = ApiService();
  List<PastPaperModel> _papers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  Future<void> _loadPapers() async {
    final papers = await _apiService.getPastPapersBySubject(
      widget.subjectId,
      widget.languageCode,
    );
    
    setState(() {
      _papers = papers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: _papers.length,
      itemBuilder: (context, index) {
        final paper = _papers[index];
        return ListTile(
          title: Text(paper.title),
          subtitle: Text('${paper.year} • ${paper.term ?? "N/A"}'),
          trailing: _buildTagsChips(paper.tags),
          onTap: () => _openPaper(paper.fileUrl),
        );
      },
    );
  }
  
  Widget _buildTagsChips(List<String>? tags) {
    if (tags == null || tags.isEmpty) return SizedBox();
    
    return Wrap(
      spacing: 4,
      children: tags.map((tag) => Chip(
        label: Text(tag, style: TextStyle(fontSize: 10)),
        padding: EdgeInsets.all(2),
      )).toList(),
    );
  }
  
  Future<void> _openPaper(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
```

---

### Example 2: Filter by Year with Dropdown

```dart
class FilteredPastPapersScreen extends StatefulWidget {
  final String subjectId;
  final String languageCode;
  
  @override
  _FilteredPastPapersScreenState createState() => _FilteredPastPapersScreenState();
}

class _FilteredPastPapersScreenState extends State<FilteredPastPapersScreen> {
  final ApiService _apiService = ApiService();
  List<PastPaperModel> _papers = [];
  List<String> _availableYears = [];
  String? _selectedYear;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadYearsAndPapers();
  }

  Future<void> _loadYearsAndPapers() async {
    // Load available years first
    final years = await _apiService.getAvailableYears(widget.subjectId);
    
    setState(() {
      _availableYears = years;
      _selectedYear = years.isNotEmpty ? years.first : null;
    });
    
    if (_selectedYear != null) {
      await _loadPapersForYear(_selectedYear!);
    }
  }

  Future<void> _loadPapersForYear(String year) async {
    setState(() => _isLoading = true);
    
    final papers = await _apiService.getPastPapersByYear(
      widget.subjectId,
      widget.languageCode,
      year,
    );
    
    setState(() {
      _papers = papers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Year Dropdown
        DropdownButton<String>(
          value: _selectedYear,
          items: _availableYears.map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text(year),
            );
          }).toList(),
          onChanged: (year) {
            if (year != null) {
              setState(() => _selectedYear = year);
              _loadPapersForYear(year);
            }
          },
        ),
        
        // Papers List
        Expanded(
          child: _isLoading
            ? CircularProgressIndicator()
            : ListView.builder(
                itemCount: _papers.length,
                itemBuilder: (context, index) {
                  final paper = _papers[index];
                  return PastPaperCard(paper: paper);
                },
              ),
        ),
      ],
    );
  }
}
```

---

### Example 3: Filter by Tags

```dart
Future<void> _loadProvincialPapers() async {
  final papers = await _apiService.getPastPapersByTag(
    subjectId,
    languageCode,
    'Provincial Past Paper',
  );
  
  setState(() {
    _papers = papers;
  });
}
```

---

## UI Components

### Past Paper Card with Tags

```dart
class PastPaperCard extends StatelessWidget {
  final PastPaperModel paper;

  const PastPaperCard({required this.paper});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              paper.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            // Year and Term
            Row(
              children: [
                Text(paper.year),
                if (paper.term != null) ...[
                  Text(' • '),
                  Text(paper.term!),
                ],
              ],
            ),
            SizedBox(height: 12),
            
            // Tags
            if (paper.tags != null && paper.tags!.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: paper.tags!.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.blue.shade100,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  );
                }).toList(),
              ),
              SizedBox(height: 12),
            ],
            
            // Description
            Text(
              paper.description,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openPaper(paper.fileUrl),
                    icon: Icon(Icons.description),
                    label: Text('Open Paper'),
                  ),
                ),
                if (paper.answerUrl != null) ...[
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPaper(paper.answerUrl!),
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('Answers'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPaper(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
```

---

## Firestore Data Structure

### Collection: `pastPapers`

```javascript
{
  "id": "auto-generated",
  "gradeId": "zH3Nk9B6A1b78IQmpM7W",      // Original grade ID
  "subjectId": "URUYRjfuHn5omThsBqev",    // Original subject ID for language
  "year": "2024",                         // String type
  "term": "First Term",                   // Optional
  "title": "2024 First Term Mathematics",
  "description": "Provincial examination paper",
  "fileUrl": "https://firebasestorage.../paper.pdf",
  "answerUrl": "https://firebasestorage.../answers.pdf",  // Optional
  "fileSize": 1234567,                    // Bytes
  "language": "english",                  // Lowercase: "english" or "sinhala"
  "uploadedAt": "2024-01-15T10:00:00Z",  // ISO timestamp
  "isActive": true,                       // Boolean
  "tags": [                               // Optional array
    "Provincial Past Paper",
    "School Past Paper"
  ]
}
```

---

## Required Firestore Index

Add this composite index to Firebase Console:

**Collection:** `pastPapers`

| Field | Order |
|-------|-------|
| `subjectId` | Ascending |
| `year` | Descending |
| `uploadedAt` | Descending |

Or use the Firebase CLI with `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "pastPapers",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "subjectId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "year",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "uploadedAt",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

---

## Migration Notes

### Backward Compatibility

The updated model supports both old and new field names:

- **Old:** `paperUrl` → **New:** `fileUrl`
- **Old:** `year` as `int` → **New:** `year` as `String`
- **Old:** `term` required → **New:** `term` optional

The `PastPaperModel` automatically handles both:

```dart
// Supports both fileUrl and paperUrl
fileUrl: (json['fileUrl'] ?? json['paperUrl']) as String,

// Handles year as both int and string
final yearValue = json['year'];
final yearString = yearValue is int ? yearValue.toString() : (yearValue as String? ?? '');

// Backward compatibility getter
String get paperUrl => fileUrl;
```

---

## Best Practices

1. **Use `getPastPapersBySubject()`** as the primary method - it's most efficient
2. **Cache results** when possible to reduce Firestore reads
3. **Show loading indicators** while fetching
4. **Handle empty states** gracefully when no papers are found
5. **Display tags** to help users identify paper types
6. **Validate URLs** before attempting to launch
7. **Log errors** for debugging using the logger
8. **Filter inactive papers** - handled automatically by all methods

---

## Error Handling

All methods return an empty list `[]` on error and log details:

```dart
try {
  final papers = await apiService.getPastPapersBySubject(subjectId, language);
  if (papers.isEmpty) {
    // Show "No papers found" message
  }
} catch (e) {
  // This won't be reached as errors return []
  // Check logs for actual error details
}
```

Check logs for debugging:

```
🔍 Fetching past papers for subject: URUYRjfuHn5omThsBqev, language: english
🔍 Found 5 past papers for subject URUYRjfuHn5omThsBqev
🔍 After filtering: 3 papers match language english
```

---

## Testing Checklist

- [ ] Papers load by grade
- [ ] Papers load by subject
- [ ] Year filtering works
- [ ] Term filtering works
- [ ] Tag filtering works
- [ ] Available years/terms/tags load correctly
- [ ] Tags display in UI
- [ ] Paper URLs open in external app
- [ ] Answer URLs open (if present)
- [ ] Language filtering works (english/sinhala)
- [ ] Inactive papers are hidden
- [ ] Empty state shows when no papers
- [ ] Loading states work correctly
- [ ] Error handling works gracefully

---

## Performance Considerations

### Query Efficiency

| Method | Firestore Reads | Best For |
|--------|----------------|----------|
| `getPastPapersBySubject()` | ~N papers | Single subject view |
| `getPastPapers()` | ~N×M papers | All subjects in grade |
| `getPastPapersByYear()` | ~N papers | Year-specific |
| `getPastPapersByTag()` | ~N papers | Tag-specific |

Where N = number of papers, M = number of subjects

### Optimization Tips

1. **Fetch by subject** when possible (smaller dataset)
2. **Cache filter options** (years, terms, tags) - they change infrequently
3. **Paginate** if more than 50 papers per subject
4. **Use stream listeners** for real-time updates (optional)

---

## Related Documentation

- `PAST_PAPERS_FIX.md` - Previous fix documentation
- `TEST_PAST_PAPERS.md` - Testing guide
- `FIREBASE_STRUCTURE.md` - Complete Firestore structure
- `FIRESTORE_RULES.md` - Security rules
