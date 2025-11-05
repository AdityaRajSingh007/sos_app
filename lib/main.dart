import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'providers.dart';
import 'services/fcm_service.dart';

/// Background message handler must be a top-level function
/// This is registered before runApp() is called
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  await Firebase.initializeApp();
  // Handle the background message
  await handleBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Register background message handler BEFORE runApp()
  // This must be a top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Setup FCM token refresh listener
  setupTokenRefreshListener();
  
  // Setup FCM message handlers (foreground and app open scenarios)
  setupFcmMessageHandlers();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    // Update FCM token on app start if logged in
    updateFcmTokenOnAppStart();
    return MaterialApp.router(
      title: 'SOS App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
