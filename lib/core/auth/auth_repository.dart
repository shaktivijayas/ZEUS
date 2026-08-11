import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firestore/user_repository.dart';

/// [userRepoFor] is injected so tests can point it at a FakeFirebaseFirestore
/// instead of a real one, without AuthRepository knowing about Firestore setup.
class AuthRepository {
  AuthRepository(this._auth, this.userRepoFor);

  final FirebaseAuth _auth;
  final UserRepository Function(String uid) userRepoFor;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signUp({required String name, required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    await userRepoFor(uid).createInitialUser(name: name, email: email);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  // setPersistence is only implemented for the web platform by the
  // firebase_auth plugin; on mobile the SDK always persists sessions
  // locally, so this is a no-op there rather than an UnimplementedError.
  Future<void> setKeepLoggedIn(bool keepLoggedIn) {
    if (!kIsWeb) return Future.value();
    return _auth.setPersistence(keepLoggedIn ? Persistence.LOCAL : Persistence.SESSION);
  }
}
