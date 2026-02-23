import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Web login
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      }

      // google_sign_in is supported on mobile (and macOS), but not on Windows/Linux.
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        throw Exception(
          'Google sign in is not supported on this platform. Use Android, iOS, macOS, or Web.',
        );
      }

      // Mobile login
      final googleSignIn = GoogleSignIn();

      await googleSignIn.signOut(); // avoid cached session bugs

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign in FirebaseAuthException: ${e.code} ${e.message}');
      throw Exception('Google sign in failed: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('Google sign in error: $e');
      throw Exception('Google sign in failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }
}
