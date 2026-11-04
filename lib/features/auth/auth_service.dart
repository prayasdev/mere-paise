import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  static const String serverClientId =
      '1023749463309-dlja4hktb59eu8athnrdnme18c8qbquq.apps.googleusercontent.com';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize(serverClientId: serverClientId);
      _initialized = true;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount googleAccount = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = googleAccount.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      debugPrint('AuthService: Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('AuthService: GoogleSignIn sign out note: $e');
    }
    await _auth.signOut();
  }
}
