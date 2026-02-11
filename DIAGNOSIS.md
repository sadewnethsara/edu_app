# Database Structure Diagnosis

## Problem Identified

Mobile app is fetching subjects from:
```
curricula/en/grades/zxPy1XFjw089A69XsIvm/subjects/
```

But subjects don't exist there. Admin API shows subjects at:
```
grades/5tdxtNwojf2pHVcmRXt7/subjects/s27J3g3ByPmQPQHhLpoE/
```

These are **DIFFERENT grade IDs**!

## Root Cause

According to the Firebase structure you provided, there are TWO locations for grade-related data:

1. **Curriculum Hierarchy**: `curricula/{languageCode}/grades/{gradeId}/subjects/...`
   - Contains: Grade/Subject/Lesson/Subtopic METADATA (name, order, description)
   - Used by: Mobile app to fetch curriculum structure

2. **Content Storage**: `grades/{gradeId}/subjects/{subjectId}/lessons/{lessonId}/`
   - Contains: Actual CONTENT (videos[], notes[], contentPdfs[], resources[])
   - Used by: Admin panel and mobile app for content

## The Issue

Your admin panel created:
- Subjects at: `grades/5tdxtNwojf2pHVcmRXt7/subjects/...` (content location)
- But NOT at: `curricula/en/grades/5tdxtNwojf2pHVcmRXt7/subjects/...` (curriculum location)

Mobile app expects subjects in the curriculum location!

## Solutions

### Option 1: Use Grade ID from Curriculum (Current Approach)
Mobile app should fetch subjects from where they actually exist.

**Check in Firebase Console:**
1. Go to `curricula/en/grades/zxPy1XFjw089A69XsIvm/subjects/`
2. Do subjects exist there? If NO → this is the problem!

### Option 2: Admin Panel Should Create in BOTH Locations
When admin creates a subject, it should create:
1. Metadata in: `curricula/{lang}/grades/{gId}/subjects/{sId}` (name, order, icon)
2. Content in: `grades/{gId}/subjects/{sId}` (videos[], notes[], etc.)

### Option 3: Check if Grade IDs Should Match
The grade ID in both locations should be the SAME:
- `curricula/en/grades/5tdxtNwojf2pHVcmRXt7/subjects/...`
- `grades/5tdxtNwojf2pHVcmRXt7/subjects/...`

## What to Check Now

Run these queries in Firebase Console:

1. **Check what grades exist in curricula:**
   ```
   curricula/en/grades/
   ```
   Note the document IDs.

2. **Check what grades exist in grades collection:**
   ```
   grades/
   ```
   Note the document IDs.

3. **Check subjects under the grade mobile app is using:**
   ```
   curricula/en/grades/zxPy1XFjw089A69XsIvm/subjects/
   ```
   Are there any documents?

4. **Check subjects under the grade admin is using:**
   ```
   grades/5tdxtNwojf2pHVcmRXt7/subjects/
   ```
   Are there any documents?

## Expected Structure

For Grade 6 in English, you should have:

```
curricula/
  └─ en/
      └─ grades/
          └─ 5tdxtNwojf2pHVcmRXt7/           ← Same ID everywhere
              ├─ name: "Grade 6"
              ├─ order: 6
              └─ subjects/
                  └─ s27J3g3ByPmQPQHhLpoE/
                      ├─ name: "Mathematics"
                      ├─ order: 1
                      └─ lessons/
                          └─ LMrQJoEKb9gCysy1zQkw/
                              ├─ name: "Algebra"
                              └─ order: 1

grades/                                         ← Same ID here too!
  └─ 5tdxtNwojf2pHVcmRXt7/
      └─ subjects/
          └─ s27J3g3ByPmQPQHhLpoE/
              └─ lessons/
                  └─ LMrQJoEKb9gCysy1zQkw/
                      └─ content/
                          ├─ videos: [...]
                          ├─ notes: [...]
                          ├─ contentPdfs: [...]
                          └─ resources: [...]
```

## Quick Fix

If your admin panel already created everything under `grades/` collection, you need to:

1. **Copy grade metadata** from `grades/5tdxtNwojf2pHVcmRXt7` to `curricula/en/grades/5tdxtNwojf2pHVcmRXt7`
2. **Copy all subjects** from `grades/5tdxtNwojf2pHVcmRXt7/subjects/` to `curricula/en/grades/5tdxtNwojf2pHVcmRXt7/subjects/`
3. **Copy all lessons** similarly
4. **Copy all subtopics** similarly

OR

Update the user's `grades` array to use the correct grade ID: `5tdxtNwojf2pHVcmRXt7` instead of `zxPy1XFjw089A69XsIvm`.

## Please Share

1. Screenshot of Firebase Console showing `curricula/en/grades/` documents
2. Screenshot of Firebase Console showing `grades/` documents
3. Do the IDs match or are they different?
