# Firestore Security Rules Documentation

## Overview

Your Firestore security rules implement a **role-based access control (RBAC)** system with 4 user roles:

1. **user** - Regular students using the mobile app
2. **viewer** - Read-only access (for observers/parents)
3. **admin** - Full content management access
4. **super_admin** - Complete system access including settings

## Role Hierarchy

```
super_admin  → Can do everything (admin + system settings)
    ↓
  admin      → Can manage all content (grades, subjects, lessons, etc.)
    ↓
 viewer      → Can only read/view content
    ↓
  user       → Can read content + update own profile
```

## Helper Functions

### `isAdmin()`
Returns `true` if user is **admin** or **super_admin**
- Used for: Creating/updating/deleting educational content

### `isSuperAdmin()`
Returns `true` if user is **super_admin** only
- Used for: System-level settings (languages, fonts, avatars)

### `isViewerOrHigher()`
Returns `true` if user has **any role** (user, viewer, admin, super_admin)
- Used for: Reading educational content

## Collection Access Rules

### 1. `/grades/{gradeId}` (Old Structure - For Backward Compatibility)

| Action | Who Can Access | Purpose |
|--------|----------------|---------|
| Read | Any authenticated user | Students can view grades and subjects |
| Write | Admin, Super Admin | Content management |

**Subcollections**: `subjects/`, `lessons/`, `subtopics/` follow same rules

**Mobile App Usage**: 
- Used as fallback when `curricula/` collection doesn't have data
- Content storage location (`grades/{gId}/subjects/{sId}/lessons/{lId}/content`)

---

### 2. `/curricula/{languageCode}` (New Structure - Primary)

| Action | Who Can Access | Purpose |
|--------|----------------|---------|
| Read | Any authenticated user | Students can view curriculum |
| Write | Admin, Super Admin | Curriculum management |

**Structure**: Language-specific curriculum hierarchy
- `curricula/en/grades/{gradeId}/subjects/{subjectId}/lessons/{lessonId}/subtopics/{subtopicId}`
- `curricula/si/...` (Sinhala)
- `curricula/ta/...` (Tamil)

**Mobile App Usage**: 
- Primary source for curriculum metadata (names, descriptions, order)
- Queried based on user's `learningMedium` setting

---

### 3. `/users/{userId}`

| Action | Who Can Access | Notes |
|--------|----------------|-------|
| Read | Own profile OR Admin/Super Admin | Users can only see their own data |
| Update | Own profile (except role) OR Admin/Super Admin | Users can't change their own role |
| Create | Admin, Super Admin | Only admins can create user accounts |
| Delete | Admin, Super Admin | Only admins can delete users |

**Important Security Feature**:
```javascript
// Users can update own profile BUT NOT their role
allow update: if (request.auth.uid == userId && 
                  request.resource.data.role == resource.data.role)
```

**Fields in User Document**:
```javascript
{
  uid: "firebase-auth-uid",
  email: "user@example.com",
  displayName: "User Name",
  role: "user",  // ← Protected! Users can't change this
  photoURL: "profile-pic-url",
  appLanguage: "en",  // UI language
  learningMedium: "si",  // Content language
  grades: ["gradeId1", "gradeId2"],  // Selected grades
  createdAt: timestamp,
  lastLogin: timestamp
}
```

---

### 4. `/languages/{languageCode}`

| Action | Who Can Access | Purpose |
|--------|----------------|---------|
| Read | Any authenticated user | App needs language list |
| Write | Super Admin only | System-level setting |

**Mobile App Usage**: 
- Fetched by `ApiService.getLanguages()`
- Displayed in settings for "Learning Medium" selection

---

### 5. `/pastPapers/{paperId}`

| Action | Who Can Access | Purpose |
|--------|----------------|---------|
| Read | Any authenticated user | Students can download papers |
| Write | Admin, Super Admin | Content management |

**Mobile App Usage**: 
- Queried by grade and language
- Filtered in-memory by language and isActive

---

### 6. `/publicData/{docId}`

| Action | Who Can Access | Purpose |
|--------|----------------|---------|
| Read | Any authenticated user | App announcements, banners, etc. |
| Write | Admin, Super Admin | Content management |

**Use Case**: System-wide announcements, maintenance notices, feature flags

---

### 7. `/content/{contentId}` (New - Optional Content Storage)

| Action | Who Can Access | Purpose |
|--------|----------------|---------|
| Read | Any authenticated user | Students can view content |
| Write | Admin, Super Admin | Content management |

**Structure Options**:

**Option A (Current)**: Content stored in lesson/subtopic documents
```
grades/{gradeId}/subjects/{sId}/lessons/{lId}/
  └─ content: {
       videos: [...],
       notes: [...],
       contentPdfs: [...],
       resources: [...]
     }
```

**Option B (New)**: Content stored as separate documents in `/content/` collection
```
content/{contentId}/
  ├─ type: "lesson" | "subtopic"
  ├─ gradeId: "gradeId"
  ├─ subjectId: "subjectId"
  ├─ lessonId: "lessonId"
  ├─ subtopicId: "subtopicId" (if type=subtopic)
  ├─ videos: [...]
  ├─ notes: [...]
  ├─ contentPdfs: [...]
  └─ resources: [...]
```

**Mobile App Impact**: 
- Option A (Current): Works now, content fetched from lesson/subtopic documents
- Option B (New): Would require API service updates to query `/content/` collection

---

### 8. System Settings Collections (Super Admin Only)

| Collection | Purpose |
|------------|---------|
| `/curriculumLabels/{languageCode}` | UI labels for curriculum (e.g., "Grade", "Subject") |
| `/languageFonts/{languageCode}` | Font settings for each language |
| `/avatars/{avatarId}` | System avatar images |

## Mobile App Integration

### Authentication Flow

1. **User signs in** via Firebase Auth
2. **Custom claims set** by admin panel:
   ```javascript
   admin.auth().setCustomUserClaims(uid, { role: 'user' })
   ```
3. **Token includes role**: `request.auth.token.role`
4. **Rules check role** before allowing access

### Required Custom Claims

Your admin panel must set custom claims when creating users:

```javascript
// In admin panel backend
const admin = require('firebase-admin');

await admin.auth().setCustomUserClaims(userId, {
  role: 'user'  // or 'viewer', 'admin', 'super_admin'
});
```

### Mobile App User Document Structure

When a user signs up or signs in, ensure their document is created/updated:

```dart
// In mobile app - after authentication
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? 'User',
      'role': 'user',  // Default role
      'photoURL': user.photoURL,
      'appLanguage': 'en',
      'learningMedium': 'en',
      'grades': [],
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
```

## Security Best Practices

### ✅ What's Secure

1. **Users can't escalate privileges** - Can't change their own role
2. **Users can only see their own data** - Can't read other users' profiles
3. **All educational content is read-only for students** - Can't modify curriculum
4. **System settings protected** - Only super admins can change languages, fonts, etc.

### ⚠️ Important Notes

1. **Custom Claims Required**: The `role` field in custom claims is CRITICAL
   - Without it, users will be denied access even with valid authentication
   - Admin panel must set custom claims when creating users

2. **Role in User Document**: The `role` field should ALSO be in the user document
   - Used by admin panel to display user role
   - Protected from user modification by rules
   - Should match the custom claim

3. **Token Refresh**: Custom claims are included in the auth token
   - If you change a user's role, they need to sign out and sign in again
   - Or force token refresh: `await user.getIdToken(true);`

## Testing Rules Locally

Use Firebase Emulator Suite to test rules:

```bash
# Start emulators
firebase emulators:start

# Run rules tests
firebase emulators:exec --only firestore "npm test"
```

Example test:
```javascript
it('should allow users to read grades', async () => {
  const db = testEnv.authenticatedContext('user123', {
    role: 'user'
  }).firestore();
  
  const gradeRef = db.collection('grades').doc('grade1');
  await firebase.assertSucceeds(gradeRef.get());
});
```

## Common Issues & Solutions

### Issue 1: "Permission Denied" Error
**Cause**: User doesn't have custom claims set
**Solution**: 
```javascript
// In admin panel
await admin.auth().setCustomUserClaims(userId, { role: 'user' });
```

### Issue 2: User Can't Read Curriculum
**Cause**: User role not in custom claims or token not refreshed
**Solution**: 
```dart
// In mobile app - force token refresh
await FirebaseAuth.instance.currentUser?.getIdToken(true);
```

### Issue 3: Admin Can't Update Content
**Cause**: Custom claim is 'admin' but rules check for both 'admin' and 'super_admin'
**Solution**: This should work - check if token is stale, try signing out/in

## Rule Deployment

Deploy rules to Firebase:

```bash
# Deploy rules only
firebase deploy --only firestore:rules

# Or deploy everything
firebase deploy
```

## Content Storage Structure

Your rules support **both** content storage approaches:

### Current Implementation (Recommended)
Content embedded in lesson/subtopic documents at:
- `grades/{gradeId}/subjects/{sId}/lessons/{lId}` - contains `content` field
- `grades/{gradeId}/subjects/{sId}/lessons/{lId}/subtopics/{stId}` - contains `content` field

**Mobile App**: Currently uses this approach ✅

### Alternative Implementation (Optional)
Separate `/content/` collection for scalability:
- `/content/{contentId}` - separate documents per lesson/subtopic content

**Mobile App**: Not implemented yet, but rules support it

See **CONTENT_STORAGE_OPTIONS.md** for detailed comparison and migration guide.

---

## Summary

Your security rules are **well-designed** and follow best practices:

- ✅ Role-based access control
- ✅ Users can't escalate privileges
- ✅ Content is protected from unauthorized changes
- ✅ System settings require super admin access
- ✅ Users can manage their own profiles (except role)
- ✅ Flexible content storage (supports both embedded and separate collection)

The mobile app works seamlessly with these rules as long as:
1. Users have proper custom claims set (`role` in auth token)
2. User documents exist with correct role field
3. Users are authenticated before accessing data

**Note**: Your current mobile app uses **embedded content** in lesson/subtopic documents. The `/content/` collection rule is future-proofing for scalability, but migration is **not required** unless you have 100+ content items per lesson.
