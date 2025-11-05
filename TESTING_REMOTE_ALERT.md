# Testing Remote Alert Triggering

## Method 1: Using Firebase CLI (Easiest)

### Step 1: Get Firebase ID Token

First, you need to authenticate and get an ID token. You can do this in several ways:

#### Option A: From Flutter App (Recommended)
Add this temporary code to get your ID token:

```dart
import 'package:firebase_auth/firebase_auth.dart';

// After login, get the ID token:
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  final idToken = await user.getIdToken();
  print('ID Token: $idToken');
  // Copy this token for use in curl/Postman
}
```

#### Option B: Using Firebase CLI
```bash
# Login to Firebase
firebase login

# Get ID token (requires Node.js)
firebase auth:export users.json --format=json
```

#### Option C: Using REST API (from browser console after login)
In your Flutter app, after logging in, open browser DevTools and run:
```javascript
// In browser console after Firebase Auth login
firebase.auth().currentUser.getIdToken().then(token => console.log(token));
```

### Step 2: Get Your Function URL

After deploying, find your function URL in Firebase Console:
- Go to Firebase Console → Functions
- Look for `triggerCriticalAlert`
- Copy the URL (format: `https://<region>-<project-id>.cloudfunctions.net/triggerCriticalAlert`)

Or use this format:
```
https://<region>-<project-id>.cloudfunctions.net/triggerCriticalAlert
```

### Step 3: Make POST Request

#### Using cURL:
```bash
curl -X POST \
  https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/triggerCriticalAlert \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "data": {
      "targetUserId": "STUDENT_USER_ID_HERE"
    }
  }'
```

#### Using PowerShell:
```powershell
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer YOUR_ID_TOKEN"
}

$body = @{
    data = @{
        targetUserId = "STUDENT_USER_ID_HERE"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/triggerCriticalAlert" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

#### Using Postman:
1. **Method**: POST
2. **URL**: `https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/triggerCriticalAlert`
3. **Headers**:
   - `Content-Type`: `application/json`
   - `Authorization`: `Bearer YOUR_ID_TOKEN`
4. **Body** (raw JSON):
```json
{
  "data": {
    "targetUserId": "STUDENT_USER_ID_HERE"
  }
}
```

## Method 2: Using Firebase Functions SDK (Node.js)

Create a test script:

```javascript
const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFunctions, httpsCallable } = require('firebase/functions');

const firebaseConfig = {
  // Your Firebase config
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  // ... other config
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const functions = getFunctions(app);

async function testTriggerAlert() {
  try {
    // Login
    const userCredential = await signInWithEmailAndPassword(
      auth,
      "your-email@example.com",
      "your-password"
    );
    
    console.log('Logged in:', userCredential.user.uid);
    
    // Call the function
    const triggerAlert = httpsCallable(functions, 'triggerCriticalAlert');
    const result = await triggerAlert({
      targetUserId: 'STUDENT_USER_ID_HERE'
    });
    
    console.log('Success:', result.data);
  } catch (error) {
    console.error('Error:', error);
  }
}

testTriggerAlert();
```

## Method 3: From Flutter App (Direct Test)

Add a test button in your `HomePage`:

```dart
import 'services/cloud_function_service.dart';

// In your HomePage widget:
ElevatedButton(
  onPressed: () async {
    try {
      final result = await CloudFunctionService.triggerCriticalAlert(
        targetUserId: 'STUDENT_USER_ID_HERE', // Replace with actual student UID
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Success! Alert ID: ${result['alertId']}'),
          backgroundColor: Colors.green,
        ),
      );
      
      print('Alert triggered: ${result['alertId']}');
      print('Sent to ${result['sentCount']} devices');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: Text('Test Remote Alert'),
)
```

## Getting the Required Information

### 1. Get Student User ID (targetUserId)
- Go to Firebase Console → Authentication → Users
- Copy the UID of the student user
- OR from Firestore: `users` collection → document ID is the UID

### 2. Get Your Project ID and Region
- Project ID: Firebase Console → Project Settings → General
- Region: Check where you deployed the function (default: `us-central1`)

### 3. Verify Responders are Assigned
Before testing, ensure:
- Student document in Firestore has `assignedResponders` array populated
- Responder users exist and have valid `fcmToken` in their documents

## Expected Response

**Success Response:**
```json
{
  "success": true,
  "alertId": "unique_alert_id_here",
  "message": "Alert triggered successfully. Sent to 2 device(s).",
  "sentCount": 2,
  "failedCount": 0
}
```

**Error Response:**
```json
{
  "error": {
    "code": "failed-precondition",
    "message": "Target user has no assigned responders"
  }
}
```

## Troubleshooting

### Error: "User must be authenticated"
- Make sure you're using a valid Firebase ID token
- Token might have expired (get a new one)

### Error: "Target user not found"
- Verify the `targetUserId` exists in Firestore `users` collection
- Check the UID is correct

### Error: "No assigned responders"
- Go to Firestore → `users` → student document
- Add responder UIDs to `assignedResponders` array:
  ```json
  {
    "assignedResponders": ["responder_uid_1", "responder_uid_2"]
  }
  ```

### Error: "No valid FCM tokens"
- Ensure responder users have logged in at least once
- Check `fcmToken` field exists in responder user documents
- Verify FCM token is not null/empty

### Function Not Found
- Make sure function is deployed: `firebase deploy --only functions`
- Check function URL region matches deployment region
- Verify function name matches: `triggerCriticalAlert`

## Quick Test Checklist

- [ ] Function is deployed
- [ ] You have a valid Firebase ID token
- [ ] Student user exists in Firestore
- [ ] Student has `assignedResponders` array with responder UIDs
- [ ] Responder users exist and have `fcmToken`
- [ ] Responder devices have the app installed and logged in
- [ ] Responder devices have notification permissions granted

## Testing End-to-End Flow

1. **Setup**:
   - Create 2 test accounts (student + responder)
   - Login as responder on a physical device
   - Assign responder UID to student's `assignedResponders` array

2. **Trigger Alert**:
   - Use any method above to call the function
   - Use student's UID as `targetUserId`

3. **Verify**:
   - Check responder device receives FCM message
   - Verify native alert triggers (bypasses DND, max volume)
   - Check function logs in Firebase Console

