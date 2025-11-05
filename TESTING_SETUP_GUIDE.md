# Testing Setup Guide - Remote Alert Triggering

## Understanding the Flow

```
[You with ID Token] → [POST Request] → [Cloud Function] → [FCM] → [Responder Devices]
                          ↓
                    (targetUserId = Student UID)
                          ↓
              Student's assignedResponders array
                          ↓
              [Your UID should be here to receive alert]
```

## Step-by-Step Setup

### Step 1: Get Your User UID (for receiving alerts)

**Option A: From Flutter App**
```dart
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  print('Your UID: ${user.uid}');
  // Copy this UID - you'll need it!
}
```

**Option B: From Firebase Console**
- Go to Firebase Console → Authentication → Users
- Find your user account
- Copy the UID

### Step 2: Get Your ID Token (for making the request)

**From Flutter App:**
```dart
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  final idToken = await user.getIdToken();
  print('Your ID Token: $idToken');
  // Copy this token for the POST request
}
```

### Step 3: Set Up Student Document in Firestore

Go to Firebase Console → Firestore → `users` collection:

1. Find or create the student document (the one you want to test alerts for)
2. Edit the document
3. Make sure `assignedResponders` field exists (it's an array)
4. Add your UID to the array:

```json
{
  "assignedResponders": [
    "YOUR_UID_HERE"  // ← Add your UID here
  ],
  // ... other fields
}
```

**Example:**
```json
{
  "uid": "student_uid_123",
  "fullName": "Test Student",
  "assignedResponders": [
    "your_uid_abc123"  // ← Your UID goes here
  ],
  "fcmToken": "student_fcm_token_here",
  // ... rest of student data
}
```

### Step 4: Make Sure Your Device Has FCM Token

On the device where you want to receive the alert:

1. Make sure you're logged in to the app
2. The app automatically updates your FCM token in Firestore
3. Verify in Firestore: Your user document should have `fcmToken` field populated

### Step 5: Make the POST Request

Now you can trigger the alert:

**PowerShell:**
```powershell
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer YOUR_ID_TOKEN_HERE"  # ← Your ID token
}

$body = @{
    data = @{
        targetUserId = "STUDENT_UID_HERE"  # ← Student's UID
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/triggerCriticalAlert" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

## Quick Reference

| What | Where to Get It | Used For |
|------|----------------|----------|
| **Your UID** | Firebase Auth Console or `currentUser.uid` | Add to student's `assignedResponders` array to RECEIVE alerts |
| **Your ID Token** | `getIdToken()` after login | Authentication header in POST request to TRIGGER alerts |
| **Student UID** | Firebase Auth Console or Firestore `users` collection | `targetUserId` in POST request |
| **Function URL** | Firebase Console → Functions | The endpoint URL for POST request |

## Testing Scenarios

### Scenario 1: Test on Same Device (You trigger, you receive)

1. **Your UID**: `your_uid_123`
2. **Your ID Token**: `your_id_token_abc...`
3. **Student UID**: `student_uid_456`
4. **Student's assignedResponders**: `["your_uid_123"]` ← Your UID
5. Make POST request with your ID token, targeting student UID
6. Your device receives the alert!

### Scenario 2: Test on Different Device (You trigger, friend receives)

1. **Your UID**: `your_uid_123` (for authentication)
2. **Your ID Token**: `your_id_token_abc...` (for POST request)
3. **Friend's UID**: `friend_uid_789` (for receiving)
4. **Student UID**: `student_uid_456`
5. **Student's assignedResponders**: `["friend_uid_789"]` ← Friend's UID
6. Make POST request with your ID token, targeting student UID
7. Friend's device receives the alert!

## Common Mistakes

❌ **Wrong**: Using your ID token as the responder
- The ID token is for authentication, not for receiving alerts

✅ **Correct**: 
- ID token = who you are (authentication)
- Your UID in `assignedResponders` = who receives the alert

❌ **Wrong**: Not having your UID in `assignedResponders`
- You won't receive the alert even if you trigger it

✅ **Correct**: 
- Add your UID to the student's `assignedResponders` array
- Make sure your device has a valid `fcmToken` in your user document

## Verification Checklist

Before testing, verify:

- [ ] Student document exists in Firestore `users` collection
- [ ] Student document has `assignedResponders` array
- [ ] Your UID is in the `assignedResponders` array
- [ ] Your user document has a valid `fcmToken`
- [ ] You have a valid ID token (not expired)
- [ ] You're logged in on the device where you want to receive alerts
- [ ] Device has notification permissions granted
- [ ] Cloud Function is deployed

