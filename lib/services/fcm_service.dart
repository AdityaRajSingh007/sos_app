import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'alert_service.dart';

Future<void> updateFcmTokenOnAppStart() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  final newToken = await FirebaseMessaging.instance.getToken();
  if (newToken == null) return;
  final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
  final snap = await docRef.get();
  final current = (snap.data() ?? const {})['fcmToken'];
  if (current != newToken) {
    await docRef.update({'fcmToken': newToken, 'updatedAt': FieldValue.serverTimestamp()});
  }
}

void setupTokenRefreshListener() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': newToken,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }).onError((err) {
    // no-op for now
  });
}

/// Handle FCM messages when app is in foreground
/// This is called when a message is received while the app is active
Future<void> handleForegroundMessage(RemoteMessage message) async {
  debugPrint('Received foreground message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');

  // Check if this is a critical alert message
  if (message.data['type'] == 'critical_alert') {
    debugPrint('Critical alert received! Triggering native alert...');
    try {
      await AlertService.triggerCriticalAlert();
      debugPrint('Native alert triggered successfully');
    } catch (e) {
      debugPrint('Error triggering native alert: $e');
    }
  }
}

/// Handle FCM messages when app is in background
/// This must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Received background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');

  // Check if this is a critical alert message
  if (message.data['type'] == 'critical_alert') {
    debugPrint('Critical alert received in background! Triggering native alert...');
    try {
      await AlertService.triggerCriticalAlert();
      debugPrint('Native alert triggered successfully from background');
    } catch (e) {
      debugPrint('Error triggering native alert from background: $e');
    }
  }
}

/// Setup FCM message handlers for foreground messages and app open scenarios
/// Note: Background message handler must be registered in main() before runApp()
void setupFcmMessageHandlers() {
  // Request notification permissions (required for Android 13+)
  FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  // Handle foreground messages (when app is in foreground)
  FirebaseMessaging.onMessage.listen(handleForegroundMessage);

  // Handle messages that opened the app from a terminated state
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null && message.data['type'] == 'critical_alert') {
      debugPrint('App opened from terminated state by critical alert');
      // Trigger alert when app opens
      AlertService.triggerCriticalAlert().catchError((e) {
        debugPrint('Error triggering alert on app open: $e');
      });
    }
  });

  // Handle messages when app is opened from background via notification tap
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('App opened from background by message: ${message.messageId}');
    if (message.data['type'] == 'critical_alert') {
      debugPrint('Critical alert opened app, triggering native alert');
      AlertService.triggerCriticalAlert().catchError((e) {
        debugPrint('Error triggering alert on notification tap: $e');
      });
    }
  });
}


