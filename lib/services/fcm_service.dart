import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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


