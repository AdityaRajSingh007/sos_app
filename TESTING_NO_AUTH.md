# Testing Remote Alert Without Authentication

## Quick Test Guide

The function is now configured to allow unauthenticated requests for testing.

## Method 1: Using cURL (No Auth Required)

```bash
curl -X POST \
  https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/triggerCriticalAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "targetUserId": "STUDENT_USER_ID_HERE"
    }
  }'
```

## Method 2: Using PowerShell (No Auth Required)

```powershell
$headers = @{
    "Content-Type" = "application/json"
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

## Method 3: Using Postman

1. **Method**: POST
2. **URL**: `https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/triggerCriticalAlert`
3. **Headers**:
   - `Content-Type`: `application/json`
4. **Body** (raw JSON):
```json
{
  "data": {
    "targetUserId": "STUDENT_USER_ID_HERE"
  }
}
```

## Important Notes

- ✅ **No authentication required** - You can test without login
- ✅ **No ID token needed** - Just send the POST request
- ⚠️ **For testing only** - Re-enable authentication for production
- ✅ **Student must have responders assigned** - Check Firestore `assignedResponders` array

## Example Response

**Success:**
```json
{
  "result": {
    "success": true,
    "alertId": "abc123xyz",
    "message": "Alert triggered successfully. Sent to 1 device(s).",
    "sentCount": 1,
    "failedCount": 0
  }
}
```

**Error (No Responders):**
```json
{
  "error": {
    "status": "FAILED_PRECONDITION",
    "message": "Target user has no assigned responders"
  }
}
```

## Quick Test Checklist

- [ ] Function deployed
- [ ] Student UID ready (from Firestore)
- [ ] Responder UID added to student's `assignedResponders` array
- [ ] Responder device has app installed and logged in
- [ ] Responder device has valid FCM token in Firestore

## After Testing

⚠️ **Remember to re-enable authentication** for production by:
1. Removing `invoker: "public"` from function config
2. Re-adding authentication check in the function code

