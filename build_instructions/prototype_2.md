### **Technical Brief: Prototype 2 - User Registration & Backend Integration**

**To the Developer:**

The following document details the requirements for Prototype 2 of our emergency alert application.We have successfully completed a Proof of Concept (PoC) for the critical alert mechanism. The goal of this prototype is to build the foundational backend, user data model, and the user-facing registration/login flow.

This prototype will connect our Flutter application to a live Firebase backend, allowing users to create accounts and have their data stored securely and reliably.

---

#### **1. Project Objective**

To build a fully functional user authentication and registration system using Flutter and Firebase. This includes creating the UI screens for login/registration, defining the data structure in Firestore, and implementing the logic to securely create and manage user accounts.

#### **2. Core Requirements & Success Criteria**

This prototype will be considered successful when:

1.  A new user can open the app and successfully register for an account using their email and a password.
2.  All information entered on the registration form is validated and then saved as a new document in the `users` collection in Firestore.
3.  A registered user can log out and log back in using their credentials.
4.  The application correctly manages the user's session (i.e., keeps them logged in after closing and reopening the app).
5.  The application logic includes a mechanism to update the user's FCM token in Firestore every time the app starts.

#### **3. Technical Stack**

*   **Frontend:** Flutter
*   **Backend & Database:** Google Firebase
    *   **Authentication:** Firebase Authentication (Email/Password method)
    *   **Database:** Firestore
    *   **Push Notifications:** Firebase Cloud Messaging (FCM) for token generation.

---

#### **4. Detailed Implementation Guide**

##### **Step 1: Firebase Project Setup**

1.  **Initialize Firebase:** Ensure the Flutter project is correctly linked to our Firebase project. The `google-services.json` (Android) and `GoogleService-Info.plist` (iOS, for future) should be in place.
2.  **Enable Services:** In the Firebase Console, confirm that **Authentication** (with Email/Password provider enabled) and **Firestore Database** are active.
3.  **Firestore Security Rules (Initial):** For development, set the Firestore rules to allow authenticated users to read and write their own data. A good starting point is:
    ```
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        // Allow users to create their own user document
        match /users/{userId} {
          allow create: if request.auth.uid == userId;
          // Allow logged-in users to read/update their own data
          allow read, update: if request.auth.uid == userId;
        }
      }
    }
    ```

##### **Step 2: Firestore Data Model**

Create a top-level collection named `users`. Each document in this collection will have its ID set to the user's `uid` from Firebase Authentication. The structure of each document is as follows:

```javascript
{
  uid: "...", // string, from Firebase Auth
  email: "user@college.edu", // string
  fullName: "John Doe", // string
  contact: "+91...", // string, formatted to E.164 standard
  guardianContact: "+91...", // string, formatted to E.164 standard
  enrollmentNumber: "A20405222099", // string
  accommodationType: "Hosteller", // string, "Hosteller" or "Dayscholar"
  hostelWingAndRoom: "Hostel 1, Wing A, Room 201", // string or null
  permanentHomeAddress: "123 Main St, Anytown, State, 12345", // string
  role: "Student", // string, hardcoded default value on creation
  medicalInfo: { // map
    bloodType: "O+", // string
    allergies: "None", // string
    otherDetails: "Asthmatic" // string
  },
  assignedResponders: [], // array, initially empty
  fcmToken: "..." // string, see Step 5 for update logic
}
```

##### **Step 3: Build the UI Screens in Flutter**

1.  **Authentication Wrapper (Main Logic):** In `main.dart`, implement a "wrapper" or "auth gate" that listens to Firebase's `authStateChanges()` stream.
    *   If a user is logged in, show the `HomePage`.
    *   If no user is logged in, show the `LoginPage`.
2.  **Login Screen (`login_page.dart`):**
    *   Two `TextField` widgets for email and password.
    *   A "Login" button that calls `FirebaseAuth.instance.signInWithEmailAndPassword()`.
    *   A text button/link to navigate to the `RegistrationPage`.
3.  **Registration Screen (`registration_page.dart`):**
    *   Create a `Form` widget with `TextFormField`s for all required user fields (fullName, email, password, contact numbers, etc.).
    *   Use radio buttons for `accommodationType`.
    *   The `hostelWingAndRoom` field should be conditionally visible/enabled only when `accommodationType` is "Hosteller."
    *   A "Register" button.

##### **Step 4: Implement Registration Logic**

This is the core logic for the "Register" button's `onPressed` event.

1.  **Form Validation:** Use a `GlobalKey<FormState>()` to validate the form.
    *   Ensure all fields are non-empty.
    *   Use a regex to validate the email format.
    *   Use a regex to validate that `contact` and `guardianContact` fields match the E.164 format (`^\+[1-9]\d{1,14}$`).
2.  **Show a Loading Indicator:** Provide user feedback that the registration is in progress.
3.  **Firebase Auth User Creation:**
    *   Call `FirebaseAuth.instance.createUserWithEmailAndPassword()`.
    *   Wrap this in a `try/catch` block to handle Firebase errors gracefully (e.g., "email-already-in-use", "weak-password").
4.  **Create Firestore Document:**
    *   If the auth user is created successfully, get the `uid` from the `UserCredential` object.
    *   Get the FCM token from the device (see Step 5).
    *   Create a new document in the `users` collection with the `uid` as the document ID.
    *   Populate this document with the validated data from the form, setting `role` to `"Student"` and `assignedResponders` to `[]` by default.
5.  **Handle Success/Failure:**
    *   On success, the `authStateChanges()` stream will automatically navigate the user to the `HomePage`.
    *   On failure, hide the loading indicator and show the user an appropriate error message (e.g., using a `SnackBar`).

##### **Step 5: Implement FCM Token Management**

This is a critical background task to ensure notifications work reliably.

1.  **Add Dependency:** Add the `firebase_messaging` package to `pubspec.yaml`.
2.  **Get Token:** Create a function to get the token: `FirebaseMessaging.instance.getToken()`.
3.  **Update Logic:** This logic should be placed in your main app widget or a state management provider that runs when the app starts.
    ```dart
    // This is pseudo-code for the logic flow
    void updateFcmTokenOnAppStart() async {
      // Get the current user from FirebaseAuth
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return; // Not logged in, do nothing

      // Get the new FCM token from the device
      String? newFcmToken = await FirebaseMessaging.instance.getToken();
      if (newFcmToken == null) return; // Could not get token

      // Get the user's current document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      // Compare the new token with the one in the database
      String? currentTokenInDb = userDoc.data()?['fcmToken'];

      if (currentTokenInDb != newFcmToken) {
        // If they are different, update the document
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': newFcmToken,
        });
        print("FCM Token updated successfully.");
      }
    }
    ```
    Call this function every time the application is launched by an authenticated user.

---