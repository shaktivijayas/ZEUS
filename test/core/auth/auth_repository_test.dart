import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/auth/auth_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';

void main() {
  test('signUp creates a Firebase Auth user and an initial Firestore user doc', () async {
    final auth = MockFirebaseAuth();
    final firestore = FakeFirebaseFirestore();
    final repo = AuthRepository(auth, (uid) => UserRepository(firestore, uid));

    await repo.signUp(name: 'Vani', email: 'vani@example.com', password: 'hunter22');

    expect(auth.currentUser, isNotNull);
    expect(auth.currentUser!.email, 'vani@example.com');

    final userRepo = UserRepository(firestore, auth.currentUser!.uid);
    final user = await userRepo.getUser();
    expect(user, isNotNull);
    expect(user!.onboarded, isFalse);
  });

  test('signOut clears the current user', () async {
    final auth = MockFirebaseAuth(signedIn: true);
    final firestore = FakeFirebaseFirestore();
    final repo = AuthRepository(auth, (uid) => UserRepository(firestore, uid));

    await repo.signOut();

    expect(auth.currentUser, isNull);
  });
}
