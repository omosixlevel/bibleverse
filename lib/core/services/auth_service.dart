import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool forceOffline = true;

  User? get currentUser => forceOffline ? null : _auth.currentUser;

  Stream<User?> get authStateChanges =>
      forceOffline ? Stream.value(null) : _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    if (forceOffline) {
      debugPrint("OFFLINE MODE: Skipping anonymous sign in.");
      return null;
    }
    try {
      final userCredential = await _auth.signInAnonymously();
      debugPrint(
        "Signed in with temporary account: ${userCredential.user?.uid}",
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Failed to sign in anonymously: ${e.code}");
      switch (e.code) {
        case "operation-not-allowed":
          debugPrint("Anonymous auth hasn't been enabled for this project.");
          break;
        default:
          debugPrint("Unknown error.");
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
