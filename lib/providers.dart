import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/registration_page.dart';
import 'screens/home_page.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegistrationPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    ],
    redirect: (context, state) {
      if (authState.isLoading) return '/splash';
      final isLoggedIn = authState.asData?.value != null;
      final loc = state.matchedLocation;
      final isAuth = loc == '/login' || loc == '/register';
      final isSplash = loc == '/splash';
      if (isLoggedIn && (isAuth || isSplash)) return '/home';
      if (!isLoggedIn && !isAuth) return '/login';
      return null;
    },
  );
});
