### **Technical Brief: Critical Alert Proof of Concept (PoC) for Emergency App**

**To the Developer:**

The following document details the requirements for a technical spike. The goal is to build a minimal Flutter application for Android that validates our project's most critical technical requirement: the ability to deliver an unmissable emergency alert that bypasses the device's silent and Do Not Disturb (DND) settings.

---

#### **1. Project Objective**

To create a single-screen Flutter application that, upon a button press, triggers a local, high-priority alert on the Android OS. This alert must function as a "critical alert," designed to be impossible for the user to ignore.

#### **2. Core Requirements & Success Criteria**

The PoC will be considered successful if the triggered alert meets all the following criteria on a physical Android device:

1.  **Bypasses Do Not Disturb:** The alert must be audible even when the device is in its strictest DND or silent mode.
2.  **Maximizes Volume:** The alert sound must play at the device's maximum possible alarm volume, regardless of the user's current volume settings.
3.  **Plays Audible Alarm:** A custom, loud, and looping alarm sound must play continuously until the user interacts with the alert.
4.  **Full-Screen Notification:** The alert must immediately wake the device and display a full-screen notification that takes over the entire screen, even if the device is locked.
5.  **User Interaction:** The full-screen notification must present a button to "Acknowledge" or "Dismiss," which, when pressed, stops the alarm sound.

#### **3. Recommended Architecture**

The application will be built using Flutter, but the core critical alert functionality will be implemented using native Android (Kotlin) code. Communication between the Flutter UI and the native Android code will be handled via a **Flutter Platform Channel**.

*   **Flutter (UI Layer):** Will provide the user interface, consisting of a single button to trigger the test alert.
*   **Platform Channel (Bridge):** A `MethodChannel` will be used to send a "start alert" message from Flutter to the native Android side.
*   **Native Android - Kotlin (Execution Layer):** Native code will be responsible for directly interacting with the Android OS `AudioManager` and `NotificationManager` to create the desired alert behavior. This logic should be encapsulated within a **Foreground Service** to ensure it runs reliably even if the app is not in the foreground.

---

#### **4. Step-by-Step Implementation Guide**

##### **Step 1: Flutter Project Setup**

1.  Create a new Flutter project(done).
2.  The UI will be minimal: a `Scaffold` containing a centered `ElevatedButton` with the label "Trigger Critical Alert".
3.  No special Flutter packages are required for the initial PoC, as the heavy lifting is done natively.

##### **Step 2: Android Manifest Configuration**

Open `android/app/src/main/AndroidManifest.xml` and add the following permissions and service declaration:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourcompany.yourapp">

    <!-- Critical Permissions -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" /> <!-- For DND -->

    <application ...>
        <activity ...>
            <!-- This attribute is needed for the full-screen intent to show on the lock screen -->
            <meta-data
                android:name="android.app.showWhenLocked"
                android:value="true" />
            <meta-data
                android:name="android.app.turnScreenOn"
                android:value="true" />
        </activity>

        <!-- Declare the Foreground Service -->
        <service
            android:name=".CriticalAlertService"
            android:enabled="true"
            android:exported="false" />
    </application>
</manifest>
```

##### **Step 3: Create the Native Foreground Service (Kotlin)**

This is the core of the PoC. Create a new Kotlin file: `android/app/src/main/kotlin/com/yourcompany/yourapp/CriticalAlertService.kt`.

This service will:
1.  Create a high-priority notification channel.
2.  Use `AudioManager` to set the alarm stream volume to maximum.
3.  Use `MediaPlayer` to play a looping alarm sound.
4.  Build a notification with a `fullScreenIntent` to take over the screen.
5.  Run as a foreground service to prevent the OS from killing it.

**`CriticalAlertService.kt` Example:**

```kotlin
package com.yourcompany.yourapp

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class CriticalAlertService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "CriticalAlertChannel"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()

        // Maximize volume
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)

        // Play sound
        mediaPlayer = MediaPlayer.create(this, R.raw.alarm_sound) // Add alarm_sound.mp3 to res/raw
        mediaPlayer?.isLooping = true
        mediaPlayer?.start()

        // Create the full-screen intent
        val fullScreenIntent = Intent(this, MainActivity::class.java)
        val fullScreenPendingIntent = PendingIntent.getActivity(this, 0,
            fullScreenIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher) // Default Flutter icon
            .setContentTitle("EMERGENCY ALERT")
            .setContentText("This is a critical emergency alert.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true) // THE KEY PART
            .build()

        startForeground(NOTIFICATION_ID, notification)

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Critical Alert Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for critical emergency alerts"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaPlayer?.stop()
        mediaPlayer?.release()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
```
**Note:** You must create a `res/raw` directory in the `android/app/src/main/` folder and place an audio file named `alarm_sound.mp3` inside it. (done)

##### **Step 4: Implement the Flutter-to-Native Platform Channel**

1.  **Kotlin side (`MainActivity.kt`):**
    Listen for the method call from Flutter and start the service.

    ```kotlin
    package com.yourcompany.yourapp

    import android.content.Intent
    import android.provider.Settings
    import android.os.Build
    import androidx.annotation.NonNull
    import io.flutter.embedding.android.FlutterActivity
    import io.flutter.embedding.engine.FlutterEngine
    import io.flutter.plugin.common.MethodChannel

    class MainActivity: FlutterActivity() {
        private val CHANNEL = "com.yourcompany.yourapp/critical_alert"

        override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
            super.configureFlutterEngine(flutterEngine)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
                if (call.method == "startCriticalAlert") {
                    // Check for DND permission first
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !notificationManager.isNotificationPolicyAccessGranted) {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.error("PERMISSION_DENIED", "DND permission not granted.", null)
                    } else {
                        val serviceIntent = Intent(this, CriticalAlertService::class.java)
                        startService(serviceIntent)
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }
        }
    }
    ```

2.  **Dart side (`lib/main.dart`):**
    Create the UI and the method call.

    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter/services.dart';

    void main() {
      runApp(const MyApp());
    }

    class MyApp extends StatelessWidget {
      const MyApp({Key? key}) : super(key: key);

      @override
      Widget build(BuildContext context) {
        return const MaterialApp(
          home: HomePage(),
        );
      }
    }

    class HomePage extends StatelessWidget {
      const HomePage({Key? key}) : super(key: key);
      static const platform = MethodChannel('com.yourcompany.yourapp/critical_alert');

      Future<void> _triggerCriticalAlert() async {
        try {
          await platform.invokeMethod('startCriticalAlert');
        } on PlatformException catch (e) {
          print("Failed to trigger alert: '${e.message}'.");
          // Handle cases where permission is denied
        }
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Critical Alert PoC'),
          ),
          body: Center(
            child: ElevatedButton(
              onPressed: _triggerCriticalAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text(
                'Trigger Critical Alert',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
      }
    }
    ```

---