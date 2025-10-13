import 'package:firebase_auth/firebase_auth.dart';

String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'An account already exists with this email. Please log in.';
    case 'weak-password':
      return 'The password is too weak. It must be at least 6 characters long.';
    case 'invalid-email':
      return 'The email address is not valid. Please check the format.';
    case 'user-not-found':
      return 'No account found with this email. Please check your email or register.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    default:
      return 'An unexpected error occurred. Please try again.';
  }
}


