# Remote Critical Alert Implementation

## Overview
This implementation allows any logged-in user to trigger a critical alert on responder devices via Firebase Cloud Functions and FCM (Firebase Cloud Messaging). When an alert is triggered, all assigned responders receive an FCM message that immediately triggers the native critical alert on their devices (bypassing DND and playing at max volume).

## Architecture

### Flow Diagram
```
[Student Device] → [Cloud Function] → [FCM] → [Responder Device] → [Native Alert Service]
```

1. **Student triggers alert** (via app or API)
2. **Cloud Function validates** and fetches student data
3. **FCM messages sent** to all assigned responders
4. **Responder devices receive** FCM message
5. **Native alert triggered** immediately (bypasses DND, max volume)

## Implementation Details

### 1. Cloud Function (`functions/src/index.ts`)
- **Function Name**: `triggerCriticalAlert`
- **Type**: HTTP Callable Function
- **Authentication**: Required (must be logged in)
- **Parameters**: 
  ```typescript
  {
    targetUserId: string  // UID of the student
  }
  ```
- **Returns**:
  ```typescript
  {
    success: boolean,
    alertId: string,      // Unique alert identifier
    message: string,
    sentCount: number,    // Number of devices alerts were sent to
    failedCount: number   // Number of failed sends
  }
  ```

**What it does**:
1. Validates requester is authenticated
2. Generates unique alert ID
3. Fetches target user document from Firestore
4. Gets all `assignedResponders` UIDs
5. Fetches FCM tokens for all responders
6. Sends high-priority FCM data messages with student information
7. Returns success/failure status

### 2. Flutter Services

#### `lib/services/cloud_function_service.dart`
Service to call the Cloud Function from Flutter:
```dart
CloudFunctionService.triggerCriticalAlert(targetUserId: 'user_uid_here')
```

#### `lib/services/alert_service.dart`
Service to trigger native alerts via platform channel:
```dart
AlertService.triggerCriticalAlert()  // Triggers native alert
AlertService.stopCriticalAlert()     // Stops active alert
```

#### `lib/services/fcm_service.dart`
FCM message handling:
- **Foreground messages**: Triggers alert immediately when app is active
- **Background messages**: Triggers alert when app is in background
- **Terminated state**: Triggers alert when app is opened from terminated state

### 3. FCM Message Payload

The Cloud Function sends FCM data messages with this structure:
```json
{
  "alertId": "unique_alert_id",
  "type": "critical_alert",
  "studentInfo": "{...json stringified student data...}",
  "triggeredBy": "requester_uid"
}
```

The `studentInfo` includes all student information:
- uid, fullName, email, contact, guardianContact
- enrollmentNumber, accommodationType, hostelWingAndRoom
- permanentHomeAddress, medicalInfo

## How to Use

### Testing via Firebase Console

1. **Deploy the Cloud Function**:
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions
   ```

2. **Get the function URL** from Firebase Console → Functions

3. **Call via HTTP** (using Firebase Admin SDK or authenticated request):
   ```javascript
   // Using Firebase Admin SDK (Node.js)
   const functions = require('firebase-functions');
   const triggerAlert = functions.httpsCallable('triggerCriticalAlert');
   
   const result = await triggerAlert({ targetUserId: 'student_uid_here' });
   console.log(result.data);
   ```

### Testing via Flutter App

1. **Add a test button** (temporary) in `HomePage`:
   ```dart
   import 'services/cloud_function_service.dart';
   
   ElevatedButton(
     onPressed: () async {
       try {
         final result = await CloudFunctionService.triggerCriticalAlert(
           targetUserId: 'student_uid_here',
         );
         print('Alert triggered: ${result['alertId']}');
         print('Sent to ${result['sentCount']} devices');
       } catch (e) {
         print('Error: $e');
       }
     },
     child: Text('Trigger Remote Alert'),
   )
   ```

2. **Or call directly** from anywhere in your app after user is authenticated.

### Testing via cURL (with Authentication)

You'll need to get an ID token from Firebase Auth first, then:

```bash
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/triggerCriticalAlert \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{"data":{"targetUserId":"student_uid_here"}}'
```

## Setup Requirements

### 1. Firebase Configuration
- ✅ Firebase project initialized
- ✅ Cloud Functions enabled
- ✅ FCM enabled
- ✅ Authentication enabled

### 2. Responder Assignment
Assign responders to students in Firestore:
```javascript
// In Firebase Console → Firestore
// Update student document:
{
  assignedResponders: ["responder_uid_1", "responder_uid_2"]
}
```

### 3. Deploy Cloud Function
```bash
cd functions
npm install
npm run build
firebase deploy --only functions:triggerCriticalAlert
```

### 4. Flutter App Setup
- ✅ `cloud_functions` package added
- ✅ FCM permissions configured
- ✅ Background message handler registered
- ✅ All services implemented

## Testing Checklist

- [ ] Deploy Cloud Function
- [ ] Assign at least one responder to a test student in Firestore
- [ ] Ensure responder device has FCM token in Firestore
- [ ] Test trigger from Flutter app (logged in as any user)
- [ ] Verify responder receives FCM message
- [ ] Verify native alert triggers on responder device
- [ ] Verify alert bypasses DND on responder device
- [ ] Verify alert plays at max volume on responder device
- [ ] Test with app in foreground
- [ ] Test with app in background
- [ ] Test with app terminated

## Error Handling

The Cloud Function handles these error cases:
- **Invalid targetUserId**: Returns `invalid-argument` error
- **User not authenticated**: Returns `unauthenticated` error
- **Target user not found**: Returns `not-found` error
- **No assigned responders**: Returns `failed-precondition` error
- **No valid FCM tokens**: Returns `failed-precondition` error

The Flutter app handles these gracefully and shows appropriate error messages.

## Next Steps (Future Enhancements)

1. **Alert Logging**: Create `alerts` collection in Firestore to log all triggered alerts
2. **Duplicate Prevention**: Add time-window check to prevent duplicate alerts
3. **UI for Triggering**: Build student list/profile view for responders to trigger alerts
4. **Alert History**: Show history of triggered alerts in the app
5. **Responder Management UI**: Allow students to manage their assigned responders

## Troubleshooting

### Alert not triggering on responder device
- Check FCM token is valid in Firestore
- Check device has internet connection
- Check app has notification permissions
- Check logs: `firebase functions:log`

### Cloud Function errors
- Check authentication token is valid
- Check target user exists in Firestore
- Check assignedResponders array is populated
- Check Cloud Function logs in Firebase Console

### FCM not working
- Verify `google-services.json` is up to date
- Check FCM token is being generated and stored
- Verify notification permissions are granted
- Check Android manifest permissions

